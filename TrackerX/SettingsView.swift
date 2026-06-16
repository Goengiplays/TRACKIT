import SwiftUI

struct SettingsView: View {
    @State private var notifications = true
    @State private var hideBalances = false
    @State private var weeklyReport = true

    var body: some View {
        List {
            Section("Preferences") {
                Toggle("Notifications", isOn: $notifications)
                Toggle("Weekly money report", isOn: $weeklyReport)
                Toggle("Hide balances by default", isOn: $hideBalances)
                NavigationLink("Categories") { SimpleSettingsDetail(title: "Categories", message: "Customize spending categories and rules for automatic organization.") }
                NavigationLink("Income sources") { IncomeSourcesView() }
            }

            Section("Data") {
                NavigationLink("Connected institutions") { PlaidConnectionView() }
                NavigationLink("Export transactions") { SimpleSettingsDetail(title: "Export", message: "Exporting CSV and PDF reports will be available from this screen.") }
                NavigationLink("Delete financial data") { SimpleSettingsDetail(title: "Delete data", message: "This permanently removes manually tracked data after identity confirmation.") }
            }

            Section {
                HStack {
                    Text("TRACK IT")
                    Spacer()
                    Text("Version 1.1")
                        .foregroundStyle(AppTheme.secondary)
                }
            }
        }
        .tint(AppTheme.forest)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SimpleSettingsDetail: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            IconBubble(systemName: "checkmark.shield.fill", color: AppTheme.forest, size: 68)
            Text(title).font(.title2.weight(.medium))
            Text(message)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .navigationTitle(title)
    }
}
