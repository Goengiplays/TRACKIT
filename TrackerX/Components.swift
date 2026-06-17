import SwiftUI

struct TrackerHeader: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showingNotifications = false
    let eyebrow: String
    let title: String
    var showAvatar = true

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.secondary)
                Text(title)
                    .font(.system(size: 34, weight: .medium, design: .default))
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer()
            if showAvatar {
                HStack(spacing: 10) {
                    Button {
                        showingNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.forest)
                                .frame(width: 46, height: 46)
                                .background(AppTheme.limeSoft)
                                .clipShape(Circle())

                            if !store.moneyInsightAlerts.isEmpty {
                                Text("\(min(store.moneyInsightAlerts.count, 9))")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 18, height: 18)
                                    .background(AppTheme.expense)
                                    .clipShape(Circle())
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Notifications")

                    NavigationLink {
                        ProfileView()
                    } label: {
                        ZStack {
                            Circle().fill(AppTheme.limeSoft)
                            Text(store.profile.initials)
                                .font(.headline.weight(.medium))
                                .foregroundStyle(AppTheme.forest)
                        }
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(AppTheme.surface, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
    }
}

struct AnimatedCurrencyText: View {
    let value: Double
    var size: CGFloat = 42
    var color: Color = AppTheme.ink

    var body: some View {
        Text(value.currency)
            .font(.system(size: size, weight: .medium, design: .default))
            .tracking(-1.4)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: value))
            .animation(.snappy(duration: 0.55), value: value)
    }
}

struct AccountVisualCard: View {
    let account: MoneyAccount

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if account.institution.localizedCaseInsensitiveContains("American Express") || account.name.localizedCaseInsensitiveContains("Gold") {
                Image("AmexGold")
                    .resizable()
                    .scaledToFill()
            } else {
                bankCardBackground
            }

            LinearGradient(
                colors: [.clear, .black.opacity(account.type == .card ? 0.05 : 0.28)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(account.institution.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(1.1)
                    Spacer()
                    Image(systemName: account.type.icon)
                        .font(.title3.weight(.medium))
                }
                Spacer()
                Text(account.detail.replacingOccurrences(of: "· Due Jun 28", with: ""))
                    .font(.title3.weight(.medium))
                    .monospacedDigit()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.scope.rawValue.uppercased())
                            .font(.caption2.weight(.bold))
                            .opacity(0.7)
                        Text(account.name)
                            .font(.subheadline.weight(.medium))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BALANCE")
                            .font(.caption2.weight(.bold))
                            .opacity(0.7)
                        Text(account.balance.currency)
                            .font(.headline.weight(.medium))
                    }
                }
            }
            .foregroundStyle(account.type == .card ? Color(red: 0.09, green: 0.07, blue: 0.03) : .white)
            .padding(20)
        }
        .frame(height: 215)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 10)
    }

    private var bankCardBackground: some View {
        LinearGradient(
            colors: [account.type.color, account.type.color.opacity(0.72), AppTheme.ink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct IconBubble: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.11))
            .clipShape(Circle())
    }
}

struct SectionTitle: View {
    let title: String
    var action: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            if let action {
                Text(action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
            }
        }
    }
}

struct ScopeSwitcher: View {
    @EnvironmentObject private var store: FinanceStore

    var body: some View {
        Picker("Account type", selection: $store.activeScope) {
            ForEach(AccountScope.allCases) { scope in
                Label(scope.rawValue, systemImage: scope.icon).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct TransactionRow: View {
    let transaction: FinanceTransaction

    private var icon: String {
        if transaction.kind == .income { return "arrow.down.left" }
        switch transaction.category {
        case "Food": return "fork.knife"
        case "Gas": return "fuelpump.fill"
        case "Rent": return "house.fill"
        case "Bills": return "bolt.fill"
        case "Subscriptions": return "repeat"
        case "Shopping": return "bag.fill"
        case "Business": return "briefcase.fill"
        default: return "creditcard.fill"
        }
    }

    var body: some View {
        HStack(spacing: 13) {
            IconBubble(
                systemName: icon,
                color: transaction.kind == .income ? AppTheme.forest : AppTheme.expense,
                size: 46
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(transaction.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text((transaction.kind == .income ? "+" : "−") + abs(transaction.amount).currency)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(transaction.kind == .income ? AppTheme.forest : AppTheme.expense)
                Text(transaction.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            IconBubble(systemName: icon, color: AppTheme.forest, size: 58)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(36)
        .trackerCard()
    }
}
