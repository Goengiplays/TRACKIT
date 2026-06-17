import SwiftUI
import UserNotifications

struct MoneyInsightAlert: Identifiable, Hashable {
    enum Priority: String {
        case urgent = "Urgent"
        case warning = "Watch"
        case insight = "Insight"
        case reminder = "Reminder"

        var color: Color {
            switch self {
            case .urgent: AppTheme.expense
            case .warning: .orange
            case .insight: AppTheme.forest
            case .reminder: AppTheme.crypto
            }
        }
    }

    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let priority: Priority
}

extension FinanceStore {
    var moneyInsightAlerts: [MoneyInsightAlert] {
        var alerts: [MoneyInsightAlert] = []
        let spendingRatio = totalIncome == 0 ? (totalSpending > 0 ? 1 : 0) : totalSpending / max(totalIncome, 1)

        if let lowAccount = scopedAccounts
            .filter({ $0.type != .card })
            .min(by: { $0.balance < $1.balance }),
           lowAccount.balance < 500 {
            alerts.append(
                MoneyInsightAlert(
                    title: "\(lowAccount.name) is getting low",
                    message: "Track AI noticed this balance is \(lowAccount.balance.currency). Move money here before bills or card payments hit.",
                    icon: "exclamationmark.triangle.fill",
                    priority: .urgent
                )
            )
        }

        if let nextBill = scopedBills
            .filter({ !$0.isPaid })
            .sorted(by: { $0.dueDay < $1.dueDay })
            .first {
            alerts.append(
                MoneyInsightAlert(
                    title: "\(nextBill.name) is coming up",
                    message: "Your \(nextBill.amount.currency) \(nextBill.category.lowercased()) bill is due around day \(nextBill.dueDay). I’d keep that cash untouched.",
                    icon: "calendar.badge.clock",
                    priority: .reminder
                )
            )
        }

        alerts.append(
            MoneyInsightAlert(
                title: spendingRatio > 0.75 ? "Spending is running hot" : "Spending is under control",
                message: spendingRatio > 0.75
                    ? "You’ve spent \(totalSpending.currency), over 75% of income. Start with the biggest category before it eats the month."
                    : "You’ve spent \(totalSpending.currency) against \(totalIncome.currency) income. Keep checking weekly so it stays clean.",
                icon: "chart.line.uptrend.xyaxis",
                priority: spendingRatio > 0.75 ? .warning : .insight
            )
        )

        alerts.append(
            MoneyInsightAlert(
                title: netProfit < 500 ? "Net profit needs attention" : "You’re protecting profit",
                message: netProfit < 500
                    ? "Your net is \(netProfit.currency). Add missing cash, tips, or side hustle income, then cut one recurring expense."
                    : "Your net is \(netProfit.currency). Track AI says keep the gap and avoid random impulse spending.",
                icon: "sparkles",
                priority: netProfit < 500 ? .warning : .insight
            )
        )

        return alerts
    }
}

struct NotificationsView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("trackit.assistantNotifications") private var assistantNotifications = false
    @State private var permissionStatus = "Not requested"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    assistantHero

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Assistant alerts")
                        ForEach(store.moneyInsightAlerts) { alert in
                            NotificationInsightRow(alert: alert)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 30)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.forest)
                }
            }
        }
    }

    private var assistantHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AssistantAvatar(size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Track AI watch mode")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Smart alerts from your assistant")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                }
                Spacer()
            }

            Text("I’ll watch balances, bills, income dips, spending spikes, and low accounts. Alerts are generated from your money data, so they feel like they came from your assistant instead of a basic reminder.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
                .lineSpacing(3)

            Toggle(isOn: $assistantNotifications) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable smart notifications")
                        .font(.headline.weight(.medium))
                    Text(permissionStatus)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
            }
            .tint(AppTheme.forest)
            .onChange(of: assistantNotifications) { _, enabled in
                enabled ? enableAssistantNotifications() : disableAssistantNotifications()
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppTheme.limeSoft, AppTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: AppTheme.blue.opacity(0.18), radius: 24, y: 12)
        .onAppear {
            permissionStatus = assistantNotifications ? "On. I’ll surface important changes." : "Off. Turn this on for assistant alerts."
        }
    }

    private func enableAssistantNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                permissionStatus = granted ? "On. I’ll surface important changes." : "Permission was not allowed in iOS Settings."
                assistantNotifications = granted
            }

            guard granted else { return }
            let alerts = Array(store.moneyInsightAlerts.prefix(4))
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: alerts.map { "trackit.ai.\($0.title)" })
            for (index, alert) in alerts.enumerated() {
                schedule(alert: alert, seconds: TimeInterval((index + 1) * 900))
            }
        }
    }

    private func disableAssistantNotifications() {
        permissionStatus = "Off. Turn this on for assistant alerts."
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func schedule(alert: MoneyInsightAlert, seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Track AI: \(alert.title)"
        content.body = alert.message
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "trackit.ai.\(alert.title)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

private struct NotificationInsightRow: View {
    let alert: MoneyInsightAlert

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            IconBubble(systemName: alert.icon, color: alert.priority.color, size: 42)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(alert.title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(alert.priority.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(alert.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(alert.priority.color.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .trackerCard(radius: 22)
    }
}
