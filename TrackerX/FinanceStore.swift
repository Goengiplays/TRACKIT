import Foundation

@MainActor
final class FinanceStore: ObservableObject {
    @Published var transactions: [FinanceTransaction] {
        didSet { saveTransactions() }
    }
    @Published var accounts: [MoneyAccount]
    @Published var activeScope: AccountScope = .personal
    @Published var customCategories: [String] {
        didSet { saveStringList(customCategories, key: categoriesKey) }
    }
    @Published var customSources: [String] {
        didSet { saveStringList(customSources, key: sourcesKey) }
    }
    @Published var bills: [Bill] {
        didSet { saveBills() }
    }
    @Published var profile: UserProfile {
        didSet { saveProfile() }
    }

    private let baseIncomeSources: [IncomeSource] = [
        IncomeSource(name: "Moxies", icon: "fork.knife", color: .orange),
        IncomeSource(name: "Rosa", icon: "cup.and.saucer.fill", color: .pink),
        IncomeSource(name: "TikTok Shop", icon: "bag.fill", color: .black),
        IncomeSource(name: "Cash jobs", icon: "hammer.fill", color: AppTheme.forest),
        IncomeSource(name: "Side hustle", icon: "sparkles", color: AppTheme.crypto)
    ]

    private static let baseCategories = [
        "Food", "Rent", "Bills", "Shopping", "Gas", "Subscriptions",
        "Entertainment", "Business", "Income", "Tips", "Other"
    ]

    private let storageKey = "trackerx.transactions.v1"
    private let categoriesKey = "trackerx.categories.v1"
    private let sourcesKey = "trackerx.sources.v1"
    private let billsKey = "trackerx.bills.v1"
    private let profileKey = "trackerx.profile.v1"

    init() {
        accounts = Self.sampleAccounts
        profile = Self.loadProfile(key: profileKey)
        customCategories = Self.loadStringList(key: categoriesKey)
        customSources = Self.loadStringList(key: sourcesKey)
        if let data = UserDefaults.standard.data(forKey: billsKey),
           let saved = try? JSONDecoder().decode([Bill].self, from: data) {
            bills = saved
        } else {
            bills = Self.sampleBills
        }
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([FinanceTransaction].self, from: data) {
            transactions = saved
        } else {
            transactions = Self.sampleTransactions
        }
    }

    var categories: [String] {
        Self.baseCategories.mergingPreservingOrder(with: customCategories)
    }

    var incomeSources: [IncomeSource] {
        let custom = customSources.map {
            IncomeSource(name: $0, icon: "plus.square.fill", color: AppTheme.forest)
        }
        return baseIncomeSources + custom
    }

    var scopedBills: [Bill] {
        bills.filter { $0.scope == activeScope }
    }

    var totalBalance: Double {
        accounts.filter { $0.scope == activeScope }.reduce(0) { total, account in
            account.type == .card ? total - abs(account.balance) : total + account.balance
        }
    }

    var totalIncome: Double {
        scopedTransactions.filter { $0.kind == .income }.reduce(0) { $0 + abs($1.amount) }
    }

    var totalSpending: Double {
        scopedTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + abs($1.amount) }
    }

    var netProfit: Double { totalIncome - totalSpending }
    var scopedTransactions: [FinanceTransaction] {
        transactions.filter { $0.effectiveScope == activeScope }
    }
    var scopedAccounts: [MoneyAccount] {
        accounts.filter { $0.scope == activeScope }
    }

    func balance(for type: AccountType) -> Double {
        scopedAccounts.filter { $0.type == type }.reduce(0) { $0 + $1.balance }
    }

    func total(for source: String) -> Double {
        scopedTransactions
            .filter { $0.kind == .income && $0.source == source }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func total(forCategory category: String) -> Double {
        scopedTransactions
            .filter { $0.kind == .expense && $0.category == category }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func netTotal(forCategory category: String, on date: Date? = nil) -> Double {
        scopedTransactions
            .filter { transaction in
                let matchesDate = date.map { Calendar.current.isDate(transaction.date, inSameDayAs: $0) } ?? true
                return transaction.category == category && matchesDate
            }
            .reduce(0) { $0 + $1.signedAmount }
    }

    func totalHours(forCategory category: String, on date: Date? = nil) -> Double {
        scopedTransactions
            .filter { transaction in
                let matchesDate = date.map { Calendar.current.isDate(transaction.date, inSameDayAs: $0) } ?? true
                return transaction.category == category && matchesDate
            }
            .reduce(0) { $0 + ($1.hoursWorked ?? 0) }
    }

    func addTransaction(
        kind: EntryKind,
        amount: Double,
        title: String,
        source: String,
        category: String,
        accountType: AccountType,
        date: Date,
        hoursWorked: Double? = nil
    ) {
        let account = accounts.first { $0.scope == activeScope && $0.type == accountType }
        let entry = FinanceTransaction(
            title: title.isEmpty ? source : title,
            subtitle: kind == .income ? "Manual income" : "Manual expense",
            amount: abs(amount),
            date: date,
            kind: kind,
            category: category,
            source: source,
            accountType: accountType,
            accountName: account?.name,
            scope: activeScope,
            hoursWorked: kind == .income ? hoursWorked : nil
        )
        transactions.insert(entry, at: 0)

        if let index = accounts.firstIndex(where: { $0.id == account?.id }) {
            accounts[index].balance += kind == .income ? abs(amount) : -abs(amount)
        }
    }

    func addCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !categories.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        customCategories.append(trimmed)
    }

    func addSource(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !incomeSources.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        customSources.append(trimmed)
    }

    func deleteAccount(_ account: MoneyAccount) {
        accounts.removeAll { $0.id == account.id }
        transactions.removeAll { $0.accountName == account.name && $0.effectiveScope == account.scope }
        bills.removeAll { $0.accountName == account.name && $0.scope == account.scope }
    }

    func addAccount(name: String, detail: String, type: AccountType, balance: Double, institution: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = MoneyAccount(
            name: trimmedName.isEmpty ? "\(type.rawValue) account" : trimmedName,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Manual account" : detail,
            type: type,
            balance: balance,
            isConnected: false,
            scope: activeScope,
            institution: institution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? trimmedName : institution
        )
        accounts.insert(account, at: 0)
    }

    func addBill(name: String, amount: Double, dueDay: Int, category: String, accountName: String, isRecurring: Bool) {
        let bill = Bill(
            name: name,
            amount: amount,
            dueDay: min(max(dueDay, 1), 31),
            category: category,
            accountName: accountName,
            scope: activeScope,
            isRecurring: isRecurring
        )
        bills.insert(bill, at: 0)
    }

    func deleteBill(_ bill: Bill) {
        bills.removeAll { $0.id == bill.id }
    }

    func importPlaidSnapshot(_ snapshot: PlaidSnapshot) {
        let connectedAccounts = snapshot.accounts.map { item in
            MoneyAccount(
                name: item.name,
                detail: item.mask.map { "•••• \($0)" } ?? "Connected with Plaid",
                type: accountType(from: item.type),
                balance: item.balance,
                isConnected: true,
                scope: AccountScope(rawValue: item.scope ?? "") ?? activeScope
            )
        }

        accounts.removeAll { $0.isConnected && $0.type != .cash && $0.name != "Coinbase" }
        accounts.insert(contentsOf: connectedAccounts, at: 0)

        let existingTitles = Set(transactions.map { "\($0.title)-\($0.date.timeIntervalSince1970)" })
        let imported = snapshot.transactions.compactMap { item -> FinanceTransaction? in
            let key = "\(item.name)-\(item.date.timeIntervalSince1970)"
            guard !existingTitles.contains(key) else { return nil }
            return FinanceTransaction(
                title: item.name,
                subtitle: "Synced with Plaid",
                amount: abs(item.amount),
                date: item.date,
                kind: item.amount < 0 ? .income : .expense,
                category: item.category,
                source: item.name,
                accountType: accountType(from: item.accountType),
                accountName: item.accountName,
                scope: AccountScope(rawValue: item.scope ?? "") ?? activeScope
            )
        }
        transactions.insert(contentsOf: imported, at: 0)
    }

    private func accountType(from value: String) -> AccountType {
        switch value.lowercased() {
        case "credit", "card": .card
        case "investment", "crypto": .crypto
        case "cash": .cash
        default: .bank
        }
    }

    func deleteTransactions(at offsets: IndexSet, in filtered: [FinanceTransaction]) {
        let ids = offsets.map { filtered[$0].id }
        ids.compactMap { id in transactions.first { $0.id == id } }.forEach(delete)
    }

    func delete(_ transaction: FinanceTransaction) {
        if let name = transaction.accountName,
           let index = accounts.firstIndex(where: { $0.name == name && $0.scope == transaction.effectiveScope }) {
            accounts[index].balance -= transaction.kind == .income ? abs(transaction.amount) : -abs(transaction.amount)
        }
        transactions.removeAll { $0.id == transaction.id }
    }

    func clearAllData() {
        transactions.removeAll()
        for index in accounts.indices {
            accounts[index].balance = 0
        }
        bills.removeAll()
    }

    func restoreDemoData() {
        accounts = Self.sampleAccounts
        transactions = Self.sampleTransactions
        bills = Self.sampleBills
        activeScope = .personal
    }

    func updateProfile(fullName: String, email: String, phone: String, password: String? = nil) {
        profile.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.fullName : fullName
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let password, !password.isEmpty {
            profile.password = password
        }
    }

    private func saveTransactions() {
        guard let data = try? JSONEncoder().encode(transactions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func saveBills() {
        guard let data = try? JSONEncoder().encode(bills) else { return }
        UserDefaults.standard.set(data, forKey: billsKey)
    }

    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }

    private func saveStringList(_ list: [String], key: String) {
        UserDefaults.standard.set(list, forKey: key)
    }

    private static func loadStringList(key: String) -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    private static func loadProfile(key: String) -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return .placeholder
        }
        return profile
    }

    private static var sampleAccounts: [MoneyAccount] {
        [
            MoneyAccount(name: "Chase Checking", detail: "•••• 2841", type: .bank, balance: 12480.24, institution: "Chase"),
            MoneyAccount(name: "American Express Gold", detail: "•••• 0000 · Due Jun 28", type: .card, balance: 1284.32, institution: "American Express"),
            MoneyAccount(name: "Cash Wallet", detail: "Manual balance", type: .cash, balance: 1860.00),
            MoneyAccount(name: "Coinbase", detail: "BTC · ETH · SOL", type: .crypto, balance: 4739.00),
            MoneyAccount(name: "Chase Business", detail: "•••• 8820", type: .bank, balance: 6380.50, scope: .business, institution: "Chase"),
            MoneyAccount(name: "Business Gold", detail: "•••• 0000", type: .card, balance: 824.10, scope: .business, institution: "American Express")
        ]
    }

    private static var sampleBills: [Bill] {
        [
            Bill(name: "Studio rent", amount: 1450, dueDay: 1, category: "Rent", accountName: "Chase Checking"),
            Bill(name: "Phone bill", amount: 94.50, dueDay: 12, accountName: "American Express Gold"),
            Bill(name: "Adobe Creative Cloud", amount: 59.99, dueDay: 18, category: "Subscriptions", accountName: "Business Gold", scope: .business),
            Bill(name: "Shopify tools", amount: 39, dueDay: 22, category: "Business", accountName: "Chase Business", scope: .business)
        ]
    }

    private static var sampleTransactions: [FinanceTransaction] {
        let calendar = Calendar.current
        let now = Date()
        func daysAgo(_ value: Int, hour: Int = 12) -> Date {
            let day = calendar.date(byAdding: .day, value: -value, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        return [
            FinanceTransaction(title: "Moxies", subtitle: "Dinner shift · Tips", amount: 286, date: daysAgo(0, hour: 23), kind: .income, category: "Tips", source: "Moxies", accountType: .cash, accountName: "Cash Wallet", scope: .personal, hoursWorked: 6),
            FinanceTransaction(title: "Whole Foods", subtitle: "Groceries", amount: 84.27, date: daysAgo(0, hour: 18), kind: .expense, category: "Food", source: "Whole Foods", accountType: .card, accountName: "American Express Gold", scope: .personal),
            FinanceTransaction(title: "Rosa", subtitle: "Morning shift", amount: 318, date: daysAgo(1, hour: 15), kind: .income, category: "Income", source: "Rosa", accountType: .cash, accountName: "Cash Wallet", scope: .personal, hoursWorked: 7),
            FinanceTransaction(title: "Shell", subtitle: "Fuel", amount: 61.42, date: daysAgo(1, hour: 9), kind: .expense, category: "Gas", source: "Shell", accountType: .card, accountName: "American Express Gold", scope: .personal),
            FinanceTransaction(title: "Studio Rent", subtitle: "Monthly payment", amount: 1450, date: daysAgo(3), kind: .expense, category: "Rent", source: "Landlord", accountType: .bank, accountName: "Chase Checking", scope: .personal),
            FinanceTransaction(title: "Electric Bill", subtitle: "Auto-pay", amount: 137.21, date: daysAgo(10), kind: .expense, category: "Bills", source: "Utility", accountType: .bank, accountName: "Chase Checking", scope: .personal),
            FinanceTransaction(title: "TikTok Shop", subtitle: "Weekly payout", amount: 1240.80, date: daysAgo(2), kind: .income, category: "Business", source: "TikTok Shop", accountType: .bank, accountName: "Chase Business", scope: .business, hoursWorked: 3),
            FinanceTransaction(title: "Cash job", subtitle: "Furniture assembly", amount: 420, date: daysAgo(4), kind: .income, category: "Income", source: "Cash jobs", accountType: .bank, accountName: "Chase Business", scope: .business, hoursWorked: 4),
            FinanceTransaction(title: "Adobe", subtitle: "Creative Cloud", amount: 59.99, date: daysAgo(5), kind: .expense, category: "Subscriptions", source: "Adobe", accountType: .card, accountName: "Business Gold", scope: .business),
            FinanceTransaction(title: "Side hustle", subtitle: "Brand design", amount: 875, date: daysAgo(7), kind: .income, category: "Business", source: "Side hustle", accountType: .bank, accountName: "Chase Business", scope: .business, hoursWorked: 5),
            FinanceTransaction(title: "Amazon", subtitle: "Business supplies", amount: 173.65, date: daysAgo(8), kind: .expense, category: "Business", source: "Amazon", accountType: .card, accountName: "Business Gold", scope: .business)
        ]
    }
}

private extension Array where Element == String {
    func mergingPreservingOrder(with extra: [String]) -> [String] {
        var seen = Set(map { $0.lowercased() })
        var merged = self
        for item in extra where !seen.contains(item.lowercased()) {
            merged.append(item)
            seen.insert(item.lowercased())
        }
        return merged
    }
}
