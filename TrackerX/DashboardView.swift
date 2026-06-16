import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showingAddEntry: Bool
    @State private var balanceHidden = false

    private let trend = [56.0, 52, 54, 63, 60, 68, 65, 72, 70, 79]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 26) {
                TrackerHeader(eyebrow: "Welcome back", title: "Hi, \(store.profile.fullName)")
                ScopeSwitcher()
                balanceSection
                actionRow
                moneyOverview
                spendingTrend
                incomeSources
                recentActivity
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .defaultScrollAnchor(.top)
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var balanceSection: some View {
        NavigationLink {
            InsightDetailView(kind: .netBalance)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total balance")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                    Spacer()
                    Button {
                        balanceHidden.toggle()
                    } label: {
                        Image(systemName: balanceHidden ? "eye.slash" : "eye")
                            .foregroundStyle(AppTheme.ink)
                    }
                    .buttonStyle(.plain)
                }

                Text(balanceHidden ? "$••,•••" : store.totalBalance.currency)
                    .font(.system(size: 43, weight: .medium, design: .default))
                    .tracking(-1.2)
                    .foregroundStyle(AppTheme.ink)
                    .contentTransition(.numericText(value: store.totalBalance))
                    .animation(.snappy(duration: 0.55), value: store.totalBalance)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                    Text("8.4%")
                        .fontWeight(.semibold)
                    Text("from last month")
                        .foregroundStyle(AppTheme.secondary)
                }
                .font(.caption)
                .foregroundStyle(AppTheme.forest)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            ActionPill(title: "Income", icon: "arrow.down.left", color: AppTheme.forest) {
                showingAddEntry = true
            }
            ActionPill(title: "Expense", icon: "arrow.up.right", color: AppTheme.expense) {
                showingAddEntry = true
            }
            NavigationLink {
                PlaidConnectionView()
            } label: {
                Label("Connect", systemImage: "link")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.limeSoft)
                    .clipShape(Capsule())
            }
        }
    }

    private var moneyOverview: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "This month", action: nil)
            HStack(spacing: 12) {
                NavigationLink {
                    InsightDetailView(kind: .income)
                } label: {
                    MoneySummaryCard(
                        title: "Income",
                        amount: store.totalIncome,
                        change: "+12.8%",
                        icon: "arrow.down.left",
                        color: AppTheme.forest
                    )
                }
                NavigationLink {
                    InsightDetailView(kind: .spending)
                } label: {
                    MoneySummaryCard(
                        title: "Expenses",
                        amount: store.totalSpending,
                        change: "−4.9%",
                        icon: "arrow.up.right",
                        color: AppTheme.expense
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var spendingTrend: some View {
        NavigationLink {
            InsightDetailView(kind: .spending)
        } label: {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spending trend")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        Text("Your daily spending is moving down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondary)
                }

                Chart(Array(trend.enumerated()), id: \.offset) { index, amount in
                    LineMark(x: .value("Day", index), y: .value("Amount", amount))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.lime)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    AreaMark(x: .value("Day", index), y: .value("Amount", amount))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.lime.opacity(0.2), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 120)
            }
            .padding(18)
            .trackerCard(radius: 22)
        }
        .buttonStyle(.plain)
    }

    private var incomeSources: some View {
        VStack(spacing: 14) {
            NavigationLink {
                IncomeSourcesView()
            } label: {
                SectionTitle(title: "Income sources", action: "View all")
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                ForEach(store.incomeSources.prefix(3)) { source in
                    NavigationLink {
                        SourceDetailView(source: source.name)
                    } label: {
                        HStack(spacing: 13) {
                            IconBubble(systemName: source.icon, color: source.color, size: 42)
                            Text(source.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            Text(store.total(for: source.name).currency)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.forest)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondary)
                        }
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    if source.id != store.incomeSources.prefix(3).last?.id {
                        Divider().padding(.leading, 55)
                    }
                }
            }
        }
    }

    private var recentActivity: some View {
        VStack(spacing: 14) {
            NavigationLink {
                TransactionsView()
            } label: {
                SectionTitle(title: "Recent activity", action: "View all")
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                ForEach(store.scopedTransactions.prefix(4)) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction)
                    } label: {
                        TransactionRow(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                    if transaction.id != store.scopedTransactions.prefix(4).last?.id {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

private struct ActionPill: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(color.opacity(0.08))
                .clipShape(Capsule())
        }
    }
}

private struct MoneySummaryCard: View {
    let title: String
    let amount: Double
    let change: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                IconBubble(systemName: icon, color: color, size: 38)
                Spacer()
                Text(change)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
            Text(amount.compactCurrency)
                .font(.title2.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .trackerCard(radius: 20)
    }
}
