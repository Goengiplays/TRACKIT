import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showingCategoryPrompt = false
    @State private var showingSourcePrompt = false
    @State private var newCategory = ""
    @State private var newSource = ""

    private var categoryRows: [(name: String, net: Double)] {
        store.categories
            .map { ($0, store.netTotal(forCategory: $0)) }
            .sorted { abs($0.1) > abs($1.1) }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    TrackerHeader(eyebrow: "Calendar breakdown", title: "Categories")
                    ScopeSwitcher()
                    HStack(spacing: 10) {
                        Button {
                            showingCategoryPrompt = true
                        } label: {
                            Label("Category", systemImage: "square.grid.2x2.badge.plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.canvas)
                                .clipShape(Capsule())
                        }
                        Button {
                            showingSourcePrompt = true
                        } label: {
                            Label("Source", systemImage: "briefcase.badge.plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.canvas)
                                .clipShape(Capsule())
                        }
                    }
                    Text("Tap any category to see the calendar, total made or lost, exact daily totals, and hours worked.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .lineSpacing(3)
                }
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 12, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section("Categories") {
                ForEach(categoryRows, id: \.name) { item in
                    NavigationLink {
                        CategoryDetailView(category: item.name)
                    } label: {
                        CategoryBudgetCard(
                            name: item.name,
                            spent: abs(item.net),
                            icon: icon(for: item.name)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }

            Section("Sources") {
                ForEach(store.incomeSources) { source in
                    HStack {
                        IconBubble(systemName: source.icon, color: source.color, size: 38)
                        Text(source.name)
                        Spacer()
                        Text(store.total(for: source.name).compactCurrency)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.forest)
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Create category", isPresented: $showingCategoryPrompt) {
            TextField("Category name", text: $newCategory)
            Button("Add") {
                store.addCategory(newCategory)
                newCategory = ""
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Create income source", isPresented: $showingSourcePrompt) {
            TextField("Source name", text: $newSource)
            Button("Add") {
                store.addSource(newSource)
                newSource = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func icon(for category: String) -> String {
        switch category {
        case "Food": "fork.knife"
        case "Rent": "house.fill"
        case "Bills": "bolt.fill"
        case "Shopping": "bag.fill"
        case "Gas": "fuelpump.fill"
        case "Subscriptions": "repeat"
        case "Business": "briefcase.fill"
        case "Tips", "Income": "arrow.down.left"
        default: "square.grid.2x2"
        }
    }
}

struct CategoryDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    let category: String
    @State private var selectedDate = Date()

    private var allEntries: [FinanceTransaction] {
        store.scopedTransactions.filter { $0.category == category }
    }

    private var dayEntries: [FinanceTransaction] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var dayNet: Double {
        store.netTotal(forCategory: category, on: selectedDate)
    }

    private var dayIncome: Double {
        dayEntries.filter { $0.kind == .income }.reduce(0) { $0 + abs($1.amount) }
    }

    private var daySpending: Double {
        dayEntries.filter { $0.kind == .expense }.reduce(0) { $0 + abs($1.amount) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.netTotal(forCategory: category).currency)
                        .font(.system(size: 40, weight: .medium, design: .default))
                        .foregroundStyle(store.netTotal(forCategory: category) >= 0 ? AppTheme.forest : AppTheme.expense)
                    Text("Total \(store.netTotal(forCategory: category) >= 0 ? "made" : "lost") in \(category.lowercased()).")
                        .foregroundStyle(AppTheme.secondary)
                }

                MonthCalendarCard(
                    selectedDate: selectedDate,
                    transactions: allEntries,
                    onSelect: { selectedDate = $0 }
                )

                HStack(spacing: 12) {
                    CategoryMetric(title: "Income", value: dayIncome.currency, color: AppTheme.blue)
                    CategoryMetric(title: "Expenses", value: daySpending.currency, color: AppTheme.expense)
                }

                HStack(spacing: 12) {
                    CategoryMetric(title: "Net day", value: dayNet.currency, color: dayNet >= 0 ? AppTheme.forest : AppTheme.expense)
                    CategoryMetric(title: "Hours", value: String(format: "%.1f", store.totalHours(forCategory: category, on: selectedDate)), color: AppTheme.ink)
                }

                Text("On \(selectedDate.formatted(date: .abbreviated, time: .omitted)), you \(dayNet >= 0 ? "made" : "lost") \(abs(dayNet).currency). Track hours on income entries to see what each day actually paid you.")
                    .foregroundStyle(AppTheme.secondary)
                    .padding(18)
                    .background(AppTheme.limeSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                SectionTitle(title: "That day")
                if dayEntries.isEmpty {
                    EmptyState(icon: "calendar", title: "No entries", message: "No \(category.lowercased()) entries are tracked for this day.")
                } else {
                    ForEach(dayEntries) { TransactionRow(transaction: $0) }
                }
            }
            .padding(20)
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CategoryMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondary)
            Text(value)
                .font(.title3.weight(.medium))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .trackerCard(radius: 18)
    }
}
