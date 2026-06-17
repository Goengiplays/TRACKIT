import Charts
import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: FinanceStore
    @Binding var showingAddEntry: Bool
    @State private var period = "Month"
    @State private var selectedSpendingCategory: String?

    private var categoryData: [(String, Double)] {
        store.categories
            .map { ($0, store.total(forCategory: $0)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    private var incomeData: [(String, Double)] {
        store.incomeSources
            .map { ($0.name, store.total(for: $0.name)) }
            .filter { $0.1 > 0 }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                TrackerHeader(eyebrow: "Clear insights", title: "Analytics")
                ScopeSwitcher()
                quickActions

                Picker("Period", selection: $period) {
                    ForEach(["Week", "Month", "Year"], id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                NavigationLink {
                    InsightDetailView(kind: .netBalance)
                } label: {
                    summaryCard
                }
                .buttonStyle(.plain)

                FloatingBarChartCard(
                    title: "Monthly flow",
                    amount: store.totalIncome + store.totalSpending,
                    values: [520, 1180, 940, 1460, 1710, 1280, 780],
                    labels: ["Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug"]
                )

                SmoothLineChartCard(
                    title: "Spending wave",
                    amount: store.totalSpending,
                    values: [380, 460, 420, 760, 640, 880, 720],
                    labels: ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                )

                NavigationLink {
                    IncomeSourcesView()
                } label: {
                    incomeChart
                }
                .buttonStyle(.plain)

                spendingChart
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button {
                showingAddEntry = true
            } label: {
                Label("Add money", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.lime)
                    .clipShape(Capsule())
            }

            Button {
                period = period == "Month" ? "Year" : "Month"
            } label: {
                Label(period, systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.limeSoft)
                    .clipShape(Capsule())
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Net profit")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
                Spacer()
                Label("+12.8%", systemImage: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(AppTheme.limeSoft)
                    .clipShape(Capsule())
            }
            Text(store.netProfit.currency)
                .font(.system(size: 38, weight: .medium, design: .default))
                .foregroundStyle(AppTheme.ink)
            HStack {
                MetricLabel(title: "Income", value: store.totalIncome, color: AppTheme.forest)
                Spacer()
                MetricLabel(title: "Expenses", value: store.totalSpending, color: AppTheme.expense)
            }
        }
        .padding(20)
        .trackerCard(radius: 26)
    }

    private var incomeChart: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "Income by job")
            Chart(incomeData, id: \.0) { item in
                BarMark(
                    x: .value("Source", item.0),
                    y: .value("Amount", item.1)
                )
                .foregroundStyle(AppTheme.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .chartYAxis(.hidden)
            .frame(height: 240)
        }
        .padding(20)
        .trackerCard(radius: 26)
    }

    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "Spending breakdown")
            Chart(categoryData, id: \.0) { item in
                SectorMark(
                    angle: .value("Amount", item.1),
                    innerRadius: .ratio(0.68),
                    angularInset: 3
                )
                .foregroundStyle(by: .value("Category", item.0))
                .cornerRadius(5)
            }
            .chartLegend(.hidden)
            .frame(height: 210)
            .overlay {
                VStack(spacing: 2) {
                    Text("SPENT")
                        .font(.caption2.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(AppTheme.secondary)
                    Text(store.totalSpending.compactCurrency)
                        .font(.title2.weight(.medium))
                }
            }

            VStack(spacing: 12) {
                ForEach(categoryData.prefix(5), id: \.0) { item in
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            selectedSpendingCategory = item.0
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(color(for: item.0))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.ink.opacity(selectedSpendingCategory == item.0 ? 0.18 : 0), lineWidth: 5)
                                )
                            Text(item.0)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(item.1.currency)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selected = selectedSpendingCategory ?? categoryData.first?.0,
               let amount = categoryData.first(where: { $0.0 == selected })?.1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selected) insight")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text("You spent \(amount.currency) here. If this is higher than expected, set a weekly cap and review every recurring charge inside this category.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.canvas)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(20)
        .trackerCard(radius: 26)
    }

    private func color(for category: String) -> Color {
        let colors: [Color] = [AppTheme.forest, AppTheme.lime, .orange, AppTheme.crypto, AppTheme.gold, .pink]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
}

private struct MetricLabel: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 9) {
            Circle().fill(color).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(AppTheme.secondary)
                Text(value.compactCurrency).font(.headline.weight(.medium))
            }
        }
    }
}
