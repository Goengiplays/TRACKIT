import Charts
import SwiftUI

enum InsightKind: Equatable {
    case netBalance, income, spending

    var title: String {
        switch self {
        case .netBalance: "Net balance"
        case .income: "Income"
        case .spending: "Expenses"
        }
    }

    var color: Color {
        self == .spending ? AppTheme.expense : AppTheme.forest
    }
}

struct InsightDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    let kind: InsightKind
    private let points = [32.0, 39, 36, 48, 44, 55, 51, 63, 59, 70, 67, 78]

    private var amount: Double {
        switch kind {
        case .netBalance: store.totalBalance
        case .income: store.totalIncome
        case .spending: store.totalSpending
        }
    }

    private var insight: String {
        switch kind {
        case .netBalance: "Your net balance is growing. Keep at least one month of expenses in cash before increasing investments."
        case .income: "Moxies and TikTok Shop provide most of your tracked income. Adding one more recurring source would reduce income concentration."
        case .spending: "Rent is your largest expense. Food and subscriptions are the easiest categories to trim this month."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(kind.title)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                    Text(amount.currency)
                        .font(.system(size: 40, weight: .medium, design: .default))
                        .foregroundStyle(kind.color)
                    Text(kind == .spending ? "4.9% lower than last month" : "12.8% higher than last month")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(kind.color)
                }

                Chart(Array(points.enumerated()), id: \.offset) { index, value in
                    LineMark(x: .value("Period", index), y: .value("Value", value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(kind.color)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    AreaMark(x: .value("Period", index), y: .value("Value", value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(kind.color.opacity(0.1))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 190)

                VStack(alignment: .leading, spacing: 12) {
                    Label("TRACK IT insight", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(AppTheme.forest)
                    Text(insight)
                        .font(.body)
                        .foregroundStyle(AppTheme.secondary)
                        .lineSpacing(4)
                }
                .padding(18)
                .background(AppTheme.limeSoft)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                SectionTitle(title: kind == .spending ? "Largest expenses" : "Recent movement")
                VStack(spacing: 8) {
                    ForEach(filtered.prefix(8)) { transaction in
                        NavigationLink {
                            TransactionDetailView(transaction: transaction)
                        } label: {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filtered: [FinanceTransaction] {
        switch kind {
        case .netBalance: store.scopedTransactions
        case .income: store.scopedTransactions.filter { $0.kind == .income }
        case .spending: store.scopedTransactions.filter { $0.kind == .expense }
        }
    }
}

struct IncomeSourcesView: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        List(store.incomeSources) { source in
            NavigationLink {
                SourceDetailView(source: source.name)
            } label: {
                HStack(spacing: 13) {
                    IconBubble(systemName: source.icon, color: source.color)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(source.name).font(.headline)
                        Text("Tracked income")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    Spacer()
                    Text(store.total(for: source.name).currency)
                        .font(.headline)
                        .foregroundStyle(AppTheme.forest)
                }
                .padding(.vertical, 5)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Income sources")
    }
}

struct SourceDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    let source: String

    private var entries: [FinanceTransaction] {
        store.scopedTransactions.filter { $0.source == source }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(store.total(for: source).currency)
                    .font(.system(size: 40, weight: .medium, design: .default))
                    .foregroundStyle(AppTheme.forest)
                Text("This source is contributing \(share)% of your tracked income. Consistent weekly entries will make forecasts more accurate.")
                    .foregroundStyle(AppTheme.secondary)
                    .padding(18)
                    .background(AppTheme.limeSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                SectionTitle(title: "Full history")
                ForEach(entries) { TransactionRow(transaction: $0) }
            }
            .padding(20)
        }
        .navigationTitle(source)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var share: Int {
        guard store.totalIncome > 0 else { return 0 }
        return Int((store.total(for: source) / store.totalIncome) * 100)
    }
}

struct TransactionDetailView: View {
    let transaction: FinanceTransaction

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    IconBubble(
                        systemName: transaction.kind == .income ? "arrow.down.left" : "arrow.up.right",
                        color: transaction.kind == .income ? AppTheme.forest : AppTheme.expense,
                        size: 62
                    )
                    Text((transaction.kind == .income ? "+" : "−") + transaction.amount.currency)
                        .font(.system(size: 34, weight: .medium, design: .default))
                        .foregroundStyle(transaction.kind == .income ? AppTheme.forest : AppTheme.expense)
                    Text(transaction.title).font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            Section("Details") {
                LabeledContent("Category", value: transaction.category)
                LabeledContent("Source", value: transaction.source)
                LabeledContent("Account", value: transaction.accountType.rawValue)
                LabeledContent("Date", value: transaction.date.formatted(date: .long, time: .omitted))
            }
            Section {
                ReceiptBreakdownCard(transaction: transaction)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            Section("Insight") {
                Text(transaction.kind == .income
                    ? "Keep tagging this income source consistently so TRACK IT can forecast your strongest work days."
                    : "Compare this purchase with your monthly category average before repeating it.")
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
    }
}
