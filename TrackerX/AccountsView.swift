import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("trackit.hideTotalBalance") private var hideTotalBalance = false
    @State private var selectedAccount: MoneyAccount?
    @State private var showingMonthlySummary = false
    @State private var showingAddManualAccount = false
    @State private var showingPlaid = false
    @State private var showingAddNote = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                TrackerHeader(eyebrow: "\(store.profile.fullName)'s wallet", title: "Home")
                ScopeSwitcher()
                balanceHeader
                TodoListCard()
                NotepadCard(showingAddNote: $showingAddNote)

                Button {
                    showingMonthlySummary = true
                } label: {
                    MonthlyMoneyRingCard(income: store.totalIncome, spending: store.totalSpending)
                }
                .buttonStyle(.plain)

                accountsSection
                activitySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .refreshable {
            await store.refreshDashboard()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedAccount) { account in
            AccountPreviewSheet(account: account)
        }
        .sheet(isPresented: $showingMonthlySummary) {
            MonthlySummarySheet()
        }
        .sheet(isPresented: $showingAddManualAccount) {
            AddManualAccountView()
        }
        .sheet(isPresented: $showingPlaid) {
            NavigationStack { PlaidConnectionView(autoStart: true) }
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView()
        }
    }

    private var balanceHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Total balance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.secondary)
                Spacer()
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        hideTotalBalance.toggle()
                    }
                } label: {
                    Image(systemName: hideTotalBalance ? "eye.slash.fill" : "eye.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.blue)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.blueSoft)
                        .clipShape(Circle())
                }
                .accessibilityLabel(hideTotalBalance ? "Show total balance" : "Hide total balance")
            }
            if hideTotalBalance {
                Text("$••••••")
                    .font(.system(size: 44, weight: .medium, design: .default))
                    .tracking(-1.4)
                    .foregroundStyle(AppTheme.ink)
                    .transition(.opacity)
            } else {
                AnimatedCurrencyText(value: store.totalBalance, size: 44)
                    .transition(.opacity)
            }
            Text("Live balance animates when activity changes.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(title: "Accounts", action: nil)
                Button {
                    showingPlaid = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.blue.opacity(0.16), radius: 14, y: 7)
                }
                .accessibilityLabel("Add bank or account")
                .contextMenu {
                    Button("Add manual account") { showingAddManualAccount = true }
                }
            }
            VStack(spacing: 10) {
                ForEach(store.scopedAccounts) { account in
                    Button {
                        selectedAccount = account
                    } label: {
                        WalletAccountRow(account: account)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation { store.deleteAccount(account) }
                        } label: {
                            Label("Remove account", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation { store.deleteAccount(account) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(AppTheme.expense)
                    }
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                TransactionsView()
            } label: {
                SectionTitle(title: "Activity", action: "View all")
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                ForEach(store.scopedTransactions.prefix(5)) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction)
                    } label: {
                        TransactionRow(transaction: transaction)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation { store.delete(transaction) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(AppTheme.expense)
                    }

                    if transaction.id != store.scopedTransactions.prefix(5).last?.id {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .padding(16)
            .trackerCard(radius: 22)
        }
    }
}

private struct TodoListCard: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var newTodo = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today’s todo")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text("Money tasks to keep you on track")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
                Image(systemName: "checklist")
                    .font(.headline)
                    .foregroundStyle(AppTheme.forest)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.limeSoft)
                    .clipShape(Circle())
            }

            HStack(spacing: 10) {
                TextField("Add a task", text: $newTodo)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(AppTheme.canvas)
                    .clipShape(Capsule())
                Button {
                    store.addTodo(newTodo)
                    newTodo = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.forest)
                        .clipShape(Circle())
                }
                .disabled(newTodo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newTodo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }

            ForEach(store.visibleTodos.prefix(4)) { todo in
                HStack(spacing: 12) {
                    Button {
                        withAnimation { store.toggleTodo(todo) }
                    } label: {
                        Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(todo.isDone ? AppTheme.forest : AppTheme.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(todo.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                            .strikethrough(todo.isDone)
                    }
                    Spacer()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation { store.deleteTodo(todo) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(AppTheme.expense)
                }
            }
        }
        .padding(18)
        .trackerCard(radius: 24)
    }
}

private struct NotepadCard: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showingAddNote: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notepad")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text("Quick money thoughts and reminders")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.headline)
                        .foregroundStyle(AppTheme.forest)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.limeSoft)
                        .clipShape(Circle())
                }
            }

            if store.visibleNotes.isEmpty {
                Text("No notes yet. Add reminders about bills, cash, or goals.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
            } else {
                ForEach(store.visibleNotes.prefix(2)) { note in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(note.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text(note.body)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation { store.deleteNote(note) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(AppTheme.expense)
                    }
                }
            }
        }
        .padding(18)
        .trackerCard(radius: 24)
    }
}

private struct AddNoteView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Note", text: $bodyText, axis: .vertical)
                    .lineLimit(5...10)
            }
            .navigationTitle("New note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addNote(title: title, body: bodyText)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AddManualAccountView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var institution = ""
    @State private var detail = ""
    @State private var balanceText = ""
    @State private var type: AccountType = .bank

    private var balance: Double {
        Double(balanceText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name", text: $name)
                    TextField("Institution", text: $institution)
                    TextField("Details, last 4, or note", text: $detail)
                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { accountType in
                            Label(accountType.rawValue, systemImage: accountType.icon).tag(accountType)
                        }
                    }
                    TextField("Balance", text: $balanceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addAccount(name: name, detail: detail, type: type, balance: balance, institution: institution)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

private struct WalletAccountRow: View {
    let account: MoneyAccount

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [account.type.color.opacity(0.95), AppTheme.ink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(account.institution)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: account.type.icon)
                    }
                    Spacer()
                    Text(account.detail.replacingOccurrences(of: "· Due Jun 28", with: ""))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(12)
            }
            .frame(width: 104, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: account.type.color.opacity(0.18), radius: 10, y: 5)

            VStack(alignment: .leading, spacing: 5) {
                Text(account.name)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                Text("\(account.scope.rawValue) \(account.type.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(account.balance.currency)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(account.type == .card ? AppTheme.expense : AppTheme.ink)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
        }
        .padding(14)
        .trackerCard(radius: 22)
    }
}

private struct MonthlySummarySheet: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var monthOffset = 0

    private var calendar: Calendar { Calendar.current }
    private var monthDate: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    private var monthTransactions: [FinanceTransaction] {
        store.scopedTransactions.filter { calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month) }
    }
    private var income: Double {
        monthTransactions.filter { $0.kind == .income }.reduce(0) { $0 + abs($1.amount) }
    }
    private var spending: Double {
        monthTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + abs($1.amount) }
    }
    private var topCategories: [(String, Double)] {
        Dictionary(grouping: monthTransactions.filter { $0.kind == .expense }, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + abs($1.amount) }) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Month", selection: $monthOffset) {
                        ForEach((-11...0).reversed(), id: \.self) { offset in
                            Text(label(for: offset)).tag(offset)
                        }
                    }
                    .pickerStyle(.menu)

                    MonthlyMoneyRingCard(income: income, spending: spending)

                    HStack(spacing: 12) {
                        insightTile("Made", income, AppTheme.blue)
                        insightTile("Spent", spending, AppTheme.expense)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where it went")
                            .font(.headline.weight(.medium))
                        ForEach(topCategories.prefix(5), id: \.0) { item in
                            HStack {
                                Text(item.0)
                                Spacer()
                                Text(item.1.currency)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            ProgressView(value: spending == 0 ? 0 : item.1 / spending)
                                .tint(AppTheme.blue)
                        }
                    }
                    .padding(18)
                    .trackerCard(radius: 22)

                    Text(spending > income
                        ? "Insight: spending is above income for this month. Start with the biggest category above and set a weekly limit so the balance stops leaking."
                        : "Insight: income is ahead of spending. Keep the gap by watching subscriptions and card charges before the end of the month.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .lineSpacing(4)
                        .padding(18)
                        .trackerCard(radius: 22)
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(monthDate.formatted(.dateTime.month(.wide).year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(30)
    }

    private func label(for offset: Int) -> String {
        let date = calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
        return offset == 0 ? "This month" : date.formatted(.dateTime.month(.abbreviated).year())
    }

    private func insightTile(_ title: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
            Text(value.currency)
                .font(.title3.weight(.medium))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .trackerCard(radius: 18)
    }
}

struct AccountRow: View {
    let account: MoneyAccount

    var body: some View {
        HStack(spacing: 14) {
            IconBubble(systemName: account.type.icon, color: account.type.color, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                            .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                Text(account.detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            Text(account.balance.currency)
                .font(.body.weight(.bold))
                .foregroundStyle(account.type == .card ? AppTheme.expense : AppTheme.ink)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
        }
        .padding(.vertical, 7)
    }
}

private struct AccountPreviewSheet: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    let account: MoneyAccount

    private var transactions: [FinanceTransaction] {
        store.transactions.filter { $0.accountName == account.name && $0.effectiveScope == account.scope }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    AccountVisualCard(account: account)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(account.balance.currency)
                    .font(.system(size: 38, weight: .medium, design: .default))
                            .foregroundStyle(account.type == .card ? AppTheme.expense : AppTheme.ink)
                        Text(account.type == .card
                            ? "Card balances count against your total. Pay this down first if utilization is climbing."
                            : "This account is part of your \(account.scope.rawValue.lowercased()) balance. Review activity often so the total stays accurate.")
                            .foregroundStyle(AppTheme.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .trackerCard(radius: 22)

                    SectionTitle(title: "Recent activity")
                    ForEach(transactions.prefix(6)) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
                .padding(20)
            }
            .navigationTitle(account.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(30)
    }
}

struct AccountDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    let account: MoneyAccount

    private var transactions: [FinanceTransaction] {
        store.transactions.filter { $0.accountType == account.type }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(account.balance.currency)
                    .font(.system(size: 40, weight: .medium, design: .default))
                Text(account.detail)
                    .foregroundStyle(AppTheme.secondary)
                Text(account.type == .card
                    ? "Keep card utilization below 30% and pay the statement balance in full to avoid interest."
                    : "This account is healthy. Review uncategorized transactions weekly to keep your total accurate.")
                    .padding(18)
                    .background(AppTheme.limeSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                SectionTitle(title: "Full activity")
                ForEach(transactions) { TransactionRow(transaction: $0) }
            }
            .padding(20)
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
