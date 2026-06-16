import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("trackerx.isAuthenticated") private var isAuthenticated = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(AppTheme.limeSoft)
                        Text(store.profile.initials)
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(AppTheme.forest)
                    }
                    .frame(width: 84, height: 84)
                    Text(store.profile.fullName)
                        .font(.title2.weight(.medium))
                    Text(store.profile.email)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                    Text("Personal account")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.forest)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.limeSoft)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Account") {
                NavigationLink("Personal information") {
                    ProfileFormView()
                }
                NavigationLink("Email & phone") {
                    SimpleSettingsDetail(title: "Contact details", message: "\(store.profile.email)\n\(store.profile.phone)")
                }
                NavigationLink("Change password") {
                    PasswordView()
                }
            }

            Section("Security & privacy") {
                NavigationLink("Face ID & passcode") {
                    SimpleSettingsDetail(title: "Face ID", message: "Use Face ID to protect your balances and financial activity.")
                }
                NavigationLink("Privacy center") {
                    PrivacyView()
                }
                NavigationLink("Connected banks") {
                    PlaidConnectionView()
                }
            }

            Section("TRACK IT") {
                NavigationLink("Settings") { SettingsView() }
                NavigationLink("Help & support") {
                    SimpleSettingsDetail(title: "Help & support", message: "Get help with accounts, transactions, bank connections, and privacy.")
                }
                NavigationLink("Legal") {
                    SimpleSettingsDetail(title: "Legal", message: "Terms of service, privacy policy, and financial data disclosures.")
                }
            }

            Section {
                Button("Log Out", role: .destructive) {
                    isAuthenticated = false
                }
                .frame(maxWidth: .infinity)
            }
        }
        .tint(AppTheme.forest)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        Form {
            TextField("Full name", text: $name)
            TextField("Email", text: $email)
            TextField("Phone", text: $phone)
            Button("Save changes") {
                store.updateProfile(fullName: name, email: email, phone: phone)
            }
        }
        .onAppear {
            name = store.profile.fullName
            email = store.profile.email
            phone = store.profile.phone
        }
        .navigationTitle("Personal information")
    }
}

private struct PasswordView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirmation = ""

    var body: some View {
        Form {
            SecureField("Current password", text: $current)
            SecureField("New password", text: $newPassword)
            SecureField("Confirm new password", text: $confirmation)
            Button("Update password") {
                store.updateProfile(
                    fullName: store.profile.fullName,
                    email: store.profile.email,
                    phone: store.profile.phone,
                    password: newPassword
                )
                current = ""
                newPassword = ""
                confirmation = ""
            }
                .disabled(newPassword.isEmpty || newPassword != confirmation)
        }
        .navigationTitle("Password")
    }
}

private struct PrivacyView: View {
    @State private var analytics = true
    @State private var personalization = true

    var body: some View {
        List {
            Section("Controls") {
                Toggle("Anonymous app analytics", isOn: $analytics)
                Toggle("Personalized insights", isOn: $personalization)
            }
            Section("Your data") {
                NavigationLink("Download my data") {
                    SimpleSettingsDetail(title: "Download data", message: "Prepare a copy of your profile, transactions, accounts, and settings.")
                }
                NavigationLink("Data retention") {
                    SimpleSettingsDetail(title: "Data retention", message: "Review how long TRACK IT stores financial and account data.")
                }
            }
        }
        .navigationTitle("Privacy")
    }
}
