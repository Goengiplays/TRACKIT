import Charts
import SwiftUI

struct MonthlyMoneyRingCard: View {
    let income: Double
    let spending: Double
    @State private var drawProgress = 0.0

    private var total: Double { income + spending }
    private var incomeShare: Double { total == 0 ? 0 : income / total }
    private var spendingShare: Double { total == 0 ? 0 : spending / total }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This month")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text("Income vs spending")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
                Text((income - spending).currency)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(income >= spending ? AppTheme.forest : AppTheme.expense)
            }

            ZStack {
                Circle()
                    .stroke(AppTheme.blueSoft, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                Circle()
                    .trim(from: 0, to: max(0.06, incomeShare) * drawProgress)
                    .stroke(
                        LinearGradient(colors: [AppTheme.blue, AppTheme.assistantPurple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: 0, to: max(0.04, spendingShare) * drawProgress)
                    .stroke(AppTheme.forest.opacity(0.82), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(130))

                VStack(spacing: 4) {
                    Image(systemName: "wallet.pass.fill")
                        .foregroundStyle(AppTheme.blue)
                    Text(spending.currency)
                        .font(.title.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text("spent")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
            }
            .frame(width: 190, height: 190)

            HStack(spacing: 12) {
                RingMetric(title: "Income", value: income, color: AppTheme.blue)
                RingMetric(title: "Spent", value: spending, color: AppTheme.forest)
            }
        }
        .padding(20)
        .trackerCard(radius: 28)
        .onAppear {
            drawProgress = 0
            withAnimation(.easeOut(duration: 0.95).delay(0.08)) {
                drawProgress = 1
            }
        }
        .onChange(of: total) { _, _ in
            drawProgress = 0
            withAnimation(.easeOut(duration: 0.85)) {
                drawProgress = 1
            }
        }
    }
}

private struct RingMetric: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(AppTheme.secondary)
                Text(value.compactCurrency).font(.headline.weight(.medium)).foregroundStyle(AppTheme.ink)
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct FloatingBarChartCard: View {
    let title: String
    let amount: Double
    let values: [Double]
    let labels: [String]
    @State private var selectedIndex: Int?
    @State private var animateBars = false

    private var maxValue: Double { max(values.max() ?? 1, 1) }
    private var highlightedIndex: Int { selectedIndex ?? values.indices.max(by: { values[$0] < values[$1] }) ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(amount.currency)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(AppTheme.blue)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(labels.indices.contains(highlightedIndex) ? labels[highlightedIndex] : "")
                        .font(.caption.weight(.semibold))
                    Text(values.indices.contains(highlightedIndex) ? values[highlightedIndex].currency : "")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(AppTheme.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppTheme.blueSoft)
                .clipShape(Capsule())
            }

            HStack(alignment: .bottom, spacing: 13) {
                ForEach(values.indices, id: \.self) { index in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(index == highlightedIndex ? AppTheme.blue.gradient : AppTheme.blueSoft.gradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(index == highlightedIndex ? AppTheme.blue.opacity(0.75) : AppTheme.border, lineWidth: 1)
                            )
                            .frame(height: animateBars ? CGFloat(54 + (values[index] / maxValue) * 118) : 36)
                            .shadow(color: index == highlightedIndex ? AppTheme.blue.opacity(0.22) : .clear, radius: 10, y: 4)
                        Text(labels.indices.contains(index) ? labels[index] : "")
                            .font(.caption2.weight(index == highlightedIndex ? .semibold : .regular))
                            .foregroundStyle(index == highlightedIndex ? AppTheme.ink : AppTheme.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.25)) {
                            selectedIndex = index
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .trackerCard(radius: 28)
        .onAppear {
            withAnimation(.easeOut(duration: 0.85).delay(0.08)) {
                animateBars = true
            }
        }
    }
}

struct SmoothLineChartCard: View {
    let title: String
    let amount: Double
    let values: [Double]
    let labels: [String]
    @State private var selectedIndex: Int?

    private var highlightedIndex: Int { selectedIndex ?? values.indices.dropFirst().max(by: { values[$0] < values[$1] }) ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline.weight(.medium)).foregroundStyle(AppTheme.ink)
                    Text(amount.currency).font(.title2.weight(.medium)).foregroundStyle(AppTheme.ink)
                }
                Spacer()
                Text(labels.indices.contains(highlightedIndex) ? labels[highlightedIndex] : "")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.canvas)
                    .clipShape(Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Chart(Array(values.enumerated()), id: \.offset) { index, value in
                    LineMark(x: .value("Month", index), y: .value("Amount", value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.blue)
                        .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                    AreaMark(x: .value("Month", index), y: .value("Amount", value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(colors: [AppTheme.blue.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
                        )
                    if index == highlightedIndex {
                        PointMark(x: .value("Month", index), y: .value("Amount", value))
                            .symbolSize(150)
                            .foregroundStyle(AppTheme.surface)
                            .annotation(position: .top) {
                                Text(value.currency)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(AppTheme.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        RuleMark(x: .value("Month", index))
                            .foregroundStyle(AppTheme.secondary.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: Array(values.indices)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), labels.indices.contains(index) {
                                Text(labels[index])
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(width: max(CGFloat(values.count) * 74, 340), height: 210)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let origin = geometry[proxy.plotAreaFrame].origin
                                        let x = value.location.x - origin.x
                                        if let index: Int = proxy.value(atX: x), values.indices.contains(index) {
                                            selectedIndex = index
                                        }
                                    }
	                            )
	                    }
	                }
	            }
        }
        .padding(20)
        .trackerCard(radius: 28)
    }
}

struct CategoryBudgetCard: View {
    let name: String
    let spent: Double
    let icon: String

    private var budget: Double { max(100, ceil(max(spent, 1) * 1.35 / 50) * 50) }
    private var progress: Double { min(spent / budget, 1) }
    private var left: Double { max(budget - spent, 0) }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 13) {
                IconBubble(systemName: icon, color: AppTheme.blue, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(spent.currency)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.secondary)
            }

            ProgressView(value: progress)
                .tint(progress > 0.82 ? AppTheme.expense : AppTheme.blue)
                .scaleEffect(x: 1, y: 1.2, anchor: .center)

            HStack {
                Text("\(Int(progress * 100))% of budget")
                Spacer()
                Text("\(left.currency) left")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.secondary)
        }
        .padding(16)
        .trackerCard(radius: 20)
    }
}

struct MonthCalendarCard: View {
    let selectedDate: Date
    let transactions: [FinanceTransaction]
    let onSelect: (Date) -> Void

    private var calendar: Calendar { Calendar.current }
    private var monthInterval: DateInterval {
        calendar.dateInterval(of: .month, for: selectedDate) ?? DateInterval(start: selectedDate, duration: 0)
    }

    private var days: [Date?] {
        let firstDay = monthInterval.start
        let weekdayOffset = calendar.component(.weekday, from: firstDay) - 1
        let dayRange = calendar.range(of: .day, in: .month, for: firstDay) ?? 1..<2
        let realDays = dayRange.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstDay) }
        return Array(repeating: nil, count: weekdayOffset) + realDays
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Button {
                    if let previous = calendar.date(byAdding: .month, value: -1, to: selectedDate) { onSelect(previous) }
                } label: {
                    Image(systemName: "chevron.left")
                }
                Button {
                    if let next = calendar.date(byAdding: .month, value: 1, to: selectedDate) { onSelect(next) }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(AppTheme.ink)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) {
                    Text($0)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondary)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasIncome: total(on: date, kind: .income) > 0,
                            hasExpense: total(on: date, kind: .expense) > 0
                        )
                        .onTapGesture { onSelect(date) }
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
        }
        .padding(18)
        .trackerCard(radius: 24)
    }

    private func total(on date: Date, kind: EntryKind) -> Double {
        transactions
            .filter { calendar.isDate($0.date, inSameDayAs: date) && $0.kind == kind }
            .reduce(0) { $0 + abs($1.amount) }
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasIncome: Bool
    let hasExpense: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : AppTheme.ink)
                .frame(width: 36, height: 36)
                .background(isSelected ? AppTheme.blue : Color.clear)
                .clipShape(Circle())
            HStack(spacing: 3) {
                if hasIncome { Circle().fill(AppTheme.blue).frame(width: 4, height: 4) }
                if hasExpense { Circle().fill(AppTheme.expense).frame(width: 4, height: 4) }
            }
            .frame(height: 4)
        }
    }
}

struct ReceiptBreakdownCard: View {
    let transaction: FinanceTransaction

    private var rows: [(String, Double)] {
        guard transaction.kind == .expense else {
            return [("Gross income", transaction.amount), ("Tracked fees", 0), ("Net received", transaction.amount)]
        }
        let subtotal = transaction.amount * 0.78
        let tax = transaction.amount * 0.084
        let tip = transaction.category == "Food" ? transaction.amount * 0.12 : transaction.amount * 0.04
        let other = max(transaction.amount - subtotal - tax - tip, 0)
        return [
            (mainLabel, subtotal),
            ("Tax", tax),
            ("Tip / service", tip),
            ("Other items", other),
            ("Total", transaction.amount)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Receipt Scan")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Label("Estimate", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.blueSoft)
                    .clipShape(Capsule())
            }

            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.canvas)
                    VStack(spacing: 6) {
                        Text("CASH RECEIPT")
                            .font(.caption2.weight(.bold))
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.secondary.opacity(0.25))
                                .frame(height: 4)
                        }
                    }
                    .padding(10)
                }
                .frame(width: 84, height: 120)

                VStack(spacing: 9) {
                    ForEach(rows.indices, id: \.self) { index in
                        HStack {
                            Text(rows[index].0)
                                .font(.subheadline.weight(index == rows.count - 1 ? .semibold : .regular))
                                .foregroundStyle(index == rows.count - 1 ? AppTheme.ink : AppTheme.secondary)
                            Spacer()
                            Text(rows[index].1.currency)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        if index == rows.count - 2 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(18)
        .trackerCard(radius: 22)
    }

    private var mainLabel: String {
        switch transaction.category {
        case "Food": "Food items"
        case "Shopping": "Purchased items"
        case "Gas": "Fuel"
        default: transaction.category
        }
    }
}
