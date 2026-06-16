import Foundation
import SwiftUI

enum EntryKind: String, Codable, CaseIterable, Identifiable {
    case income = "Income"
    case expense = "Expense"

    var id: String { rawValue }
}

enum AccountType: String, Codable, CaseIterable {
    case bank = "Bank"
    case card = "Card"
    case cash = "Cash"
    case crypto = "Crypto"

    var icon: String {
        switch self {
        case .bank: "building.columns.fill"
        case .card: "creditcard.fill"
        case .cash: "banknote.fill"
        case .crypto: "bitcoinsign.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .bank: AppTheme.forest
        case .card: Color.blue
        case .cash: Color(red: 0.14, green: 0.62, blue: 0.36)
        case .crypto: AppTheme.crypto
        }
    }
}

enum AccountScope: String, Codable, CaseIterable, Identifiable {
    case personal = "Personal"
    case business = "Business"

    var id: String { rawValue }
    var icon: String { self == .personal ? "person.fill" : "briefcase.fill" }
}

struct MoneyAccount: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var detail: String
    var type: AccountType
    var balance: Double
    var isConnected: Bool
    var scope: AccountScope
    var institution: String

    init(
        id: UUID = UUID(),
        name: String,
        detail: String,
        type: AccountType,
        balance: Double,
        isConnected: Bool = true,
        scope: AccountScope = .personal,
        institution: String = ""
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.type = type
        self.balance = balance
        self.isConnected = isConnected
        self.scope = scope
        self.institution = institution.isEmpty ? name : institution
    }
}

struct FinanceTransaction: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String
    var amount: Double
    var date: Date
    var kind: EntryKind
    var category: String
    var source: String
    var accountType: AccountType
    var accountName: String?
    var scope: AccountScope?
    var hoursWorked: Double?

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        amount: Double,
        date: Date,
        kind: EntryKind,
        category: String,
        source: String,
        accountType: AccountType,
        accountName: String? = nil,
        scope: AccountScope? = nil,
        hoursWorked: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.date = date
        self.kind = kind
        self.category = category
        self.source = source
        self.accountType = accountType
        self.accountName = accountName
        self.scope = scope
        self.hoursWorked = hoursWorked
    }

    var signedAmount: Double {
        kind == .income ? abs(amount) : -abs(amount)
    }

    var effectiveScope: AccountScope { scope ?? .personal }
}

struct Bill: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var amount: Double
    var dueDay: Int
    var category: String
    var accountName: String
    var scope: AccountScope
    var isRecurring: Bool
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        dueDay: Int,
        category: String = "Bills",
        accountName: String,
        scope: AccountScope = .personal,
        isRecurring: Bool = true,
        isPaid: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dueDay = dueDay
        self.category = category
        self.accountName = accountName
        self.scope = scope
        self.isRecurring = isRecurring
        self.isPaid = isPaid
    }
}

struct UserProfile: Codable, Hashable {
    var fullName: String
    var email: String
    var phone: String
    var password: String

    static let placeholder = UserProfile(
        fullName: "Jonathan",
        email: "jonathan@example.com",
        phone: "+1 (000) 000-0000",
        password: ""
    )

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)
        return letters.isEmpty ? "J" : String(letters).uppercased()
    }
}

struct IncomeSource: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct PlaidSnapshot: Decodable {
    let accounts: [PlaidAccountSnapshot]
    let transactions: [PlaidTransactionSnapshot]
}

struct PlaidAccountSnapshot: Decodable {
    let id: String
    let name: String
    let mask: String?
    let type: String
    let balance: Double
    let scope: String?
}

struct PlaidTransactionSnapshot: Decodable {
    let id: String
    let name: String
    let amount: Double
    let date: Date
    let category: String
    let accountType: String
    let accountName: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case id, name, amount, date, category
        case accountType = "account_type"
        case accountName = "account_name"
        case scope
    }
}

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case income = "Income"
    case expenses = "Expenses"
    case cash = "Cash"
    case bank = "Bank"
    case crypto = "Crypto"

    var id: String { rawValue }
}
