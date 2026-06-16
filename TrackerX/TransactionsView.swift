import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedAccountIDs: Set<UUID> = []
    @State private var searchText = ""
    @State private var showingAddEntry = false
    @State private var showingAccountFilter = false
    @State private var confirmingReset = false

    private var availableAccounts: [MoneyAccount] {
        store.accounts.filter { $0.scope == store.activeScope }
    }

    private var filteredTransactions: [FinanceTransaction] {
        let selectedAccounts = availableAccounts.filter { selectedAccountIDs.contains($0.id) }
        let selectedNames = Set(selectedAccounts.map(\.name))
        let selectedTypes = Set(selectedAccounts.map(\.type))

        return store.scopedTransactions.filter { transaction in
            let matchesSearch = searchText.isEmpty ||
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText) ||
                transaction.source.localizedCaseInsensitiveContains(searchText)

            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .income: matchesFilter = transaction.kind == .income
            case .expenses: matchesFilter = transaction.kind == .expense
            case .cash: matchesFilter = transaction.accountType == .cash
            case .bank: matchesFilter = transaction.accountType == .bank
            case .crypto: matchesFilter = transaction.accountType == .crypto
            }

            let matchesAccount = selectedAccountIDs.isEmpty ||
                transaction.accountName.map(selectedNames.contains) == true ||
                (transaction.accountName == nil && selectedTypes.contains(transaction.accountType))

            return matchesSearch && matchesFilter && matchesAccount
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    TrackerHeader(eyebrow: "Every dollar", title: "Activity")
                    ScopeSwitcher()
                    HStack(spacing: 10) {
                        Button {
                            showingAddEntry = true
                        } label: {
                            Label("Add", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.canvas)
                                .clipShape(Capsule())
                        }
                        Button(role: .destructive) {
                            confirmingReset = true
                        } label: {
                            Label("Clear", systemImage: "trash")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.canvas)
                                .clipShape(Capsule())
                        }
                    }
                    filterControls
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                .listRowSeparator(.hidden)
            }

            if filteredTransactions.isEmpty {
                Section {
                    EmptyState(
                        icon: "tray",
                        title: store.transactions.isEmpty ? "Activity cleared" : "No transactions",
                        message: store.transactions.isEmpty
                            ? "Your balances and activity are at zero. Add an entry or connect a bank to begin."
                            : "Try changing the account, type, or search filters."
                    )
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .listRowSeparator(.hidden)
                }
            } else {
                Section {
                    ForEach(filteredTransactions) { transaction in
                        NavigationLink {
                            TransactionDetailView(transaction: transaction)
                        } label: {
                            TransactionRow(transaction: transaction)
                                .padding(.vertical, 5)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { store.delete(transaction) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("\(filteredTransactions.count) transactions")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .searchable(text: $searchText, prompt: "Merchant, job, or category")
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView()
        }
        .sheet(isPresented: $showingAccountFilter) {
            AccountFilterSheet(
                accounts: availableAccounts,
                selection: $selectedAccountIDs
            )
        }
        .confirmationDialog(
            "Reset TRACK IT to zero?",
            isPresented: $confirmingReset,
            titleVisibility: .visible
        ) {
            Button("Clear all activity and balances", role: .destructive) {
                withAnimation {
                    store.clearAllData()
                    selectedAccountIDs.removeAll()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes every transaction and sets every account balance to $0.00.")
        }
        .onChange(of: store.activeScope) { _, _ in
            selectedAccountIDs.removeAll()
        }
    }

    private var filterControls: some View {
        VStack(spacing: 12) {
            Button {
                showingAccountFilter = true
            } label: {
                HStack {
                    Image(systemName: "building.columns")
                    Text(accountFilterTitle)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(AppTheme.canvas)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            selectedFilter = filter
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedFilter == filter ? .white : AppTheme.forest)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(selectedFilter == filter ? AppTheme.forest : AppTheme.limeSoft)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var accountFilterTitle: String {
        if selectedAccountIDs.isEmpty { return "All banks and cards" }
        if selectedAccountIDs.count == 1,
           let account = availableAccounts.first(where: { selectedAccountIDs.contains($0.id) }) {
            return account.name
        }
        return "\(selectedAccountIDs.count) accounts selected"
    }
}

private struct AccountFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [MoneyAccount]
    @Binding var selection: Set<UUID>

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selection.removeAll()
                    } label: {
                        HStack {
                            Label("All banks and cards", systemImage: "square.stack.3d.up.fill")
                            Spacer()
                            if selection.isEmpty {
                                Image(systemName: "checkmark").foregroundStyle(AppTheme.forest)
                            }
                        }
                    }
                }

                Section("Select multiple") {
                    ForEach(accounts) { account in
                        Button {
                            if selection.contains(account.id) {
                                selection.remove(account.id)
                            } else {
                                selection.insert(account.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                IconBubble(systemName: account.type.icon, color: account.type.color, size: 38)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name).foregroundStyle(AppTheme.ink)
                                    Text(account.detail)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondary)
                                }
                                Spacer()
                                Image(systemName: selection.contains(account.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selection.contains(account.id) ? AppTheme.forest : AppTheme.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
