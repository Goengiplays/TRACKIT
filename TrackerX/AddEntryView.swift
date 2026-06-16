import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FinanceStore

    @State private var kind: EntryKind = .income
    @State private var amountText = ""
    @State private var title = ""
    @State private var source = "Moxies"
    @State private var category = "Tips"
    @State private var accountType: AccountType = .cash
    @State private var date = Date()
    @State private var hoursText = ""

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Picker("Type", selection: $kind) {
                        ForEach(EntryKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: kind) { _, newValue in
                        category = newValue == .income ? "Tips" : "Food"
                        source = newValue == .income ? "Moxies" : "Manual"
                    }

                    VStack(spacing: 8) {
                        Text(kind == .income ? "How much came in?" : "How much went out?")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.title.weight(.medium))
                            TextField("0", text: $amountText)
                                .font(.system(size: 54, weight: .medium, design: .default))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .fixedSize()
                        }
                        .foregroundStyle(AppTheme.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .background(kind == .income ? AppTheme.limeSoft : Color.red.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                    VStack(spacing: 18) {
                        EntryField(title: "Description", icon: "text.alignleft") {
                            TextField(kind == .income ? "Dinner shift" : "What did you buy?", text: $title)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider()

                        EntryField(title: kind == .income ? "Job / source" : "Merchant", icon: "briefcase") {
                            if kind == .income {
                                Picker("Source", selection: $source) {
                                    ForEach(store.incomeSources, id: \.name) { Text($0.name).tag($0.name) }
                                }
                            } else {
                                TextField("Manual", text: $source)
                                    .multilineTextAlignment(.trailing)
                            }
                        }

                        Divider()

                        EntryField(title: "Category", icon: "square.grid.2x2") {
                            Picker("Category", selection: $category) {
                                ForEach(store.categories, id: \.self) { Text($0).tag($0) }
                            }
                        }

                        Divider()

                        if kind == .income {
                            EntryField(title: "Hours worked", icon: "clock") {
                                TextField("Optional", text: $hoursText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }

                            Divider()
                        }

                        EntryField(title: "Paid with", icon: "wallet.bifold") {
                            Picker("Account", selection: $accountType) {
                                ForEach(AccountType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                        }

                        Divider()

                        EntryField(title: "Date", icon: "calendar") {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                    .padding(18)
                    .trackerCard()

                    Button {
                        store.addTransaction(
                            kind: kind,
                            amount: amount,
                            title: title,
                            source: source,
                            category: category,
                            accountType: accountType,
                            date: date,
                            hoursWorked: Double(hoursText.replacingOccurrences(of: ",", with: ""))
                        )
                        dismiss()
                    } label: {
                        Text(kind == .income ? "Add income" : "Add expense")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(kind == .income ? AppTheme.forest : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(kind == .income ? AppTheme.lime : AppTheme.forest)
                            .clipShape(Capsule())
                    }
                    .disabled(amount <= 0)
                    .opacity(amount > 0 ? 1 : 0.45)
                }
                .padding(20)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.forest)
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(30)
    }
}

private struct EntryField<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.forest)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            content
                .font(.subheadline)
                .tint(AppTheme.forest)
        }
    }
}
