import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var messages: [AssistantMessage] = [
        AssistantMessage(role: .assistant, text: "Tell me what happened with your money. Example: Coffee $50, made $200 at Moxies, or paid rent $1450.")
    ]
    @State private var lastParsedEntry: ParsedAssistantEntry?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            introCard
                            ForEach(messages) { message in
                                AssistantBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(18)
                    }
                    .background(AppTheme.background)
                    .onChange(of: messages.count) { _, _ in
                        if let id = messages.last?.id {
                            withAnimation(.snappy) { proxy.scrollTo(id, anchor: .bottom) }
                        }
                    }
                }

                composer
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.canvas)
                    .clipShape(Circle())
            }

            AssistantAvatar(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("Track AI")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                Text("Spending and income assistant")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(AppTheme.secondary)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.canvas)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
    }

    private var introCard: some View {
        VStack(spacing: 16) {
            AssistantAvatar(size: 94)
                .shadow(color: AppTheme.blue.opacity(0.28), radius: 30)
            Text("Tell Track AI about your spending activities.")
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
            Text("I can log expenses, income, categories, jobs, and hours from plain text.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RadialGradient(
                colors: [AppTheme.blue.opacity(0.22), AppTheme.surface],
                center: .center,
                startRadius: 20,
                endRadius: 190
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var composer: some View {
        HStack(spacing: 10) {
            Button {
                send("Coffee $50")
            } label: {
                Image(systemName: "mic.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.blue)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.blueSoft)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Try voice example")

            TextField("Type your message here", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(AppTheme.canvas)
                .clipShape(Capsule())

            Button {
                send(draft)
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.blue)
                    .clipShape(Circle())
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(14)
        .background(AppTheme.surface)
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(AssistantMessage(role: .user, text: trimmed))
        draft = ""

        if let entry = AssistantParser.parse(trimmed, store: store) {
            store.addTransaction(
                kind: entry.kind,
                amount: entry.amount,
                title: entry.title,
                source: entry.source,
                category: entry.category,
                accountType: entry.accountType,
                date: entry.date,
                hoursWorked: entry.hoursWorked
            )
            lastParsedEntry = entry
            messages.append(AssistantMessage(role: .assistant, text: entry.confirmation))
        } else {
            messages.append(AssistantMessage(role: .assistant, text: "I need an amount to log it. Try something like “Coffee $50” or “made $200 at Moxies for 6 hours.”"))
        }
    }
}

private struct AssistantMessage: Identifiable {
    let id = UUID()
    let role: AssistantRole
    let text: String
}

private enum AssistantRole {
    case user
    case assistant
}

private struct AssistantBubble: View {
    let message: AssistantMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .user { Spacer(minLength: 48) }
            if message.role == .assistant { AssistantAvatar(size: 28) }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(message.role == .user ? .white : AppTheme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(message.role == .user ? AppTheme.blue : AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: message.role == .assistant ? 1 : 0)
                )

            if message.role == .assistant { Spacer(minLength: 48) }
        }
    }
}

struct AssistantAvatar: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [AppTheme.blue, AppTheme.assistantPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image("TrackItLogo")
                .resizable()
                .scaledToFit()
                .padding(size * 0.18)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }
}

private struct ParsedAssistantEntry {
    let kind: EntryKind
    let amount: Double
    let title: String
    let source: String
    let category: String
    let accountType: AccountType
    let date: Date
    let hoursWorked: Double?

    var confirmation: String {
        let direction = kind == .income ? "Recorded income" : "Recorded spending"
        let hours = hoursWorked.map { " · \(String(format: "%.1f", $0)) hours" } ?? ""
        return "\(direction) \(amount.currency) for \(title) in \(category)\(hours)."
    }
}

@MainActor
private enum AssistantParser {
    static func parse(_ text: String, store: FinanceStore) -> ParsedAssistantEntry? {
        guard let amount = firstAmount(in: text) else { return nil }
        let lower = text.lowercased()
        let incomeWords = ["made", "earned", "income", "paid me", "tips", "tip", "got paid"]
        let kind: EntryKind = incomeWords.contains(where: lower.contains) ? .income : .expense
        let category = category(for: lower, kind: kind)
        let source = source(for: lower, store: store, kind: kind)
        let title = title(for: text, source: source, category: category, kind: kind)
        let accountType: AccountType = lower.contains("cash") || category == "Tips" ? .cash : (kind == .income ? .bank : .card)
        let hours = hours(in: lower)

        return ParsedAssistantEntry(
            kind: kind,
            amount: amount,
            title: title,
            source: source,
            category: category,
            accountType: accountType,
            date: Date(),
            hoursWorked: hours
        )
    }

    private static func firstAmount(in text: String) -> Double? {
        let pattern = #"(?i)(?:\$|usd\s*)?([0-9]+(?:\.[0-9]{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Double(text[range])
    }

    private static func hours(in lower: String) -> Double? {
        let pattern = #"([0-9]+(?:\.[0-9])?)\s*(?:hours|hour|hrs|hr)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
              let range = Range(match.range(at: 1), in: lower) else {
            return nil
        }
        return Double(lower[range])
    }

    private static func category(for lower: String, kind: EntryKind) -> String {
        if kind == .income {
            if lower.contains("tip") { return "Tips" }
            if lower.contains("business") || lower.contains("shop") { return "Business" }
            return "Income"
        }
        if lower.contains("coffee") || lower.contains("food") || lower.contains("restaurant") || lower.contains("tea") { return "Food" }
        if lower.contains("rent") { return "Rent" }
        if lower.contains("gas") || lower.contains("fuel") { return "Gas" }
        if lower.contains("bill") || lower.contains("phone") || lower.contains("electric") { return "Bills" }
        if lower.contains("subscription") || lower.contains("netflix") || lower.contains("spotify") { return "Subscriptions" }
        if lower.contains("shop") || lower.contains("amazon") { return "Shopping" }
        return "Other"
    }

    private static func source(for lower: String, store: FinanceStore, kind: EntryKind) -> String {
        if kind == .income,
           let source = store.incomeSources.first(where: { lower.contains($0.name.lowercased()) }) {
            return source.name
        }
        return kind == .income ? "Manual income" : "AI assistant"
    }

    private static func title(for text: String, source: String, category: String, kind: EntryKind) -> String {
        if kind == .income, source != "Manual income" { return source }
        let withoutAmount = text
            .replacingOccurrences(of: #"\$?[0-9]+(?:\.[0-9]{1,2})?"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return withoutAmount.isEmpty ? category : String(withoutAmount.prefix(42))
    }
}
