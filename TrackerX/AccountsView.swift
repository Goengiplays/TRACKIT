import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("trackit.hideTotalBalance") private var hideTotalBalance = false
    @State private var selectedAccount: MoneyAccount?
    @State private var showingMonthlySummary = false
    @State private var showingAddManualAccount = false
    @State private var showingPlaid = false
    @State private var selectedDailyBarIndex = 6

    private var dailyBalanceStats: [DailyBalanceStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).map { index in
            let offset = 6 - index
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let dayTransactions = store.scopedTransactions.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let income = dayTransactions
                .filter { $0.kind == .income }
                .reduce(0) { $0 + abs($1.amount) }
            let spending = dayTransactions
                .filter { $0.kind == .expense }
                .reduce(0) { $0 + abs($1.amount) }

            return DailyBalanceStat(
                date: day,
                income: income,
                spending: spending,
                transactions: dayTransactions.count
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                TrackerHeader(eyebrow: "\(store.profile.fullName)'s wallet", title: "Home")
                ScopeSwitcher()
                balanceHeader

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
    }

    private var balanceHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.caption.weight(.bold))
                    Text("TOTAL NET BALANCE")
                        .font(.caption.weight(.bold))
                        .tracking(1.6)
                }
                .foregroundStyle(AppTheme.forest)
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
                    .font(.system(size: 48, weight: .medium, design: .serif))
                    .tracking(-1.6)
                    .foregroundStyle(AppTheme.ink)
                    .transition(.opacity)
            } else {
                AnimatedCurrencyText(value: store.totalBalance, size: 48)
                    .transition(.opacity)
            }

            HStack(spacing: 10) {
                BalancePill(title: "Income", value: store.totalIncome, color: AppTheme.blue, icon: "arrow.down.left")
                BalancePill(title: "Spent", value: store.totalSpending, color: AppTheme.forest, icon: "arrow.up.right")
            }

            let stats = dailyBalanceStats
            let maxNet = max(stats.map { abs($0.net) }.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(stats.enumerated()), id: \.element.date) { index, stat in
                    let normalized = abs(stat.net) / maxNet
                    let isSelected = selectedDailyBarIndex == index
                    Button {
                        withAnimation(.snappy(duration: 0.28)) {
                            selectedDailyBarIndex = index
                        }
                    } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(isSelected ? AppTheme.forest : AppTheme.blue.opacity(0.30 + normalized * 0.38))
                                .frame(height: 28 + normalized * 42)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(.white.opacity(isSelected ? 0.42 : 0), lineWidth: 1)
                                )
                                .shadow(color: isSelected ? AppTheme.forest.opacity(0.26) : .clear, radius: 12, y: 7)
                            Text(stat.shortLabel)
                                .font(.caption2.weight(isSelected ? .bold : .semibold))
                                .foregroundStyle(isSelected ? AppTheme.forest : AppTheme.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(stat.accessibilityLabel), net \(stat.net.currency)")
                }
            }
            .frame(height: 96)

            DailyBalanceStatCard(stat: stats[min(selectedDailyBarIndex, stats.count - 1)])

            HStack {
                Label("Live animated balance", systemImage: "waveform.path.ecg")
                Spacer()
                Text("\(store.scopedAccounts.count) accounts")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.secondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.surface,
                        AppTheme.blueSoft,
                        AppTheme.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(AppTheme.blue.opacity(0.18))
                    .frame(width: 190, height: 190)
                    .blur(radius: 22)
                    .offset(x: 130, y: -80)
                Circle()
                    .fill(AppTheme.forest.opacity(0.10))
                    .frame(width: 160, height: 160)
                    .blur(radius: 24)
                    .offset(x: -130, y: 92)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.7), AppTheme.blue.opacity(0.22), AppTheme.forest.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppTheme.blue.opacity(0.22), radius: 28, x: 0, y: 16)
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
                    SwipeDeleteAccountRow(account: account) {
                        selectedAccount = account
                    } onDelete: {
                        withAnimation { store.deleteAccount(account) }
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

private struct DailyBalanceStat {
    let date: Date
    let income: Double
    let spending: Double
    let transactions: Int

    var net: Double { income - spending }

    var shortLabel: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yest" }
        return date.formatted(.dateTime.weekday(.abbreviated))
    }

    var title: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide))
    }

    var accessibilityLabel: String {
        "\(title), \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct DailyBalanceStatCard: View {
    let stat: DailyBalanceStat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(stat.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
                Text(stat.net.currency)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(stat.net >= 0 ? AppTheme.forest : AppTheme.expense)
            }

            HStack(spacing: 8) {
                MiniDailyMetric(title: "Made", value: stat.income, color: AppTheme.blue)
                MiniDailyMetric(title: "Spent", value: stat.spending, color: AppTheme.forest)
                MiniDailyMetric(title: "Moves", value: Double(stat.transactions), color: AppTheme.secondary, isCount: true)
            }
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AppTheme.border, lineWidth: 1))
    }
}

private struct MiniDailyMetric: View {
    let title: String
    let value: Double
    let color: Color
    var isCount = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
            Text(isCount ? "\(Int(value))" : value.compactCurrency)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.canvas.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct BalancePill: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(color)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.secondary)
                Text(value.compactCurrency)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(AppTheme.surface.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
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

private struct SwipeDeleteAccountRow: View {
    let account: MoneyAccount
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0

    private let deleteWidth: CGFloat = 92

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    offset = 0
                    startOffset = 0
                }
                onDelete()
            } label: {
                VStack(spacing: 5) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Delete")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(width: deleteWidth)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .background(AppTheme.expense)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button(action: onTap) {
                WalletAccountRow(account: account)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        let nextOffset = startOffset + value.translation.width
                        offset = min(0, max(-deleteWidth, nextOffset))
                    }
                    .onEnded { value in
                        let shouldOpen = offset < -deleteWidth * 0.45 || value.predictedEndTranslation.width < -deleteWidth
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            offset = shouldOpen ? -deleteWidth : 0
                            startOffset = offset
                        }
                    }
            )
            .contextMenu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove account", systemImage: "trash")
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
