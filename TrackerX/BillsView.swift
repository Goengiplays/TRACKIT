import SwiftUI

struct BillsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showingAddBill = false

    private var monthlyTotal: Double {
        store.scopedBills.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    TrackerHeader(eyebrow: "Recurring money out", title: "Bills")
                    ScopeSwitcher()
                    Button {
                        showingAddBill = true
                    } label: {
                        Label("Add bill", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppTheme.canvas)
                            .clipShape(Capsule())
                    }
                    HStack(spacing: 12) {
                        BillMetric(title: "Monthly", value: monthlyTotal.currency, color: AppTheme.expense)
                        BillMetric(title: "Recurring", value: "\(store.scopedBills.filter(\.isRecurring).count)", color: AppTheme.forest)
                    }
                }
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 12, trailing: 20))
                .listRowSeparator(.hidden)
            }

            Section(store.activeScope.rawValue) {
                if store.scopedBills.isEmpty {
                    EmptyState(icon: "calendar.badge.plus", title: "No bills yet", message: "Add rent, subscriptions, cards, and recurring payments here.")
                } else {
                    ForEach(store.scopedBills.sorted { $0.dueDay < $1.dueDay }) { bill in
                        BillRow(bill: bill)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { store.deleteBill(bill) }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddBill) {
            AddBillView()
        }
    }
}

private struct BillMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
            Text(value)
                .font(.title2.weight(.medium))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .trackerCard(radius: 18)
    }
}

private struct BillRow: View {
    let bill: Bill

    var body: some View {
        HStack(spacing: 13) {
            IconBubble(systemName: bill.isRecurring ? "repeat" : "calendar", color: AppTheme.expense)
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.name).font(.headline.weight(.medium))
                Text("Due day \(bill.dueDay) · \(bill.accountName)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            Text(bill.amount.currency)
                .font(.headline.weight(.medium))
                .foregroundStyle(AppTheme.expense)
        }
        .padding(.vertical, 5)
    }
}

private struct AddBillView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var amountText = ""
    @State private var dueDay = 1
    @State private var category = "Bills"
    @State private var accountName = ""
    @State private var recurring = true

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Bill name", text: $name)
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                Stepper("Due day \(dueDay)", value: $dueDay, in: 1...31)
                Picker("Category", selection: $category) {
                    ForEach(store.categories, id: \.self) { Text($0).tag($0) }
                }
                Picker("Account", selection: $accountName) {
                    ForEach(store.scopedAccounts) { account in
                        Text(account.name).tag(account.name)
                    }
                }
                Toggle("Recurring monthly", isOn: $recurring)
            }
            .onAppear {
                accountName = store.scopedAccounts.first?.name ?? ""
            }
            .navigationTitle("New bill")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addBill(
                            name: name.isEmpty ? "New bill" : name,
                            amount: amount,
                            dueDay: dueDay,
                            category: category,
                            accountName: accountName,
                            isRecurring: recurring
                        )
                        dismiss()
                    }
                    .disabled(amount <= 0 || accountName.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}
