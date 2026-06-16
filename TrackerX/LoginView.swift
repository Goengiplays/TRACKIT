import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("trackerx.isAuthenticated") private var isAuthenticated = false
    @AppStorage("trackerx.developerMode") private var developerMode = false
    @State private var showingForm = false
    @State private var authMode: AuthMode = .signup
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var rememberMe = true

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                BrandMark()
                    .padding(.top, 18)

                Spacer()

                Text("Track your\nmoney effortlessly")
                    .font(.system(size: 49, weight: .regular, design: .default))
                    .tracking(-1.8)
                    .foregroundStyle(AppTheme.ink)

                Text("All your accounts, income, spending, and goals in one calm place.")
                    .font(.body)
                    .foregroundStyle(AppTheme.secondary)
                    .lineSpacing(4)
                    .padding(.top, 18)

                Spacer()

                Button {
                    authMode = .signup
                    showingForm = true
                } label: {
                    Text("Create Account")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.forest)
                        .clipShape(Capsule())
                }

                Button {
                    store.restoreDemoData()
                    developerMode = true
                    isAuthenticated = true
                } label: {
                    Label("Developer Test Mode", systemImage: "wrench.and.screwdriver.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.forest)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .overlay(Capsule().stroke(AppTheme.forest.opacity(0.45), lineWidth: 1.5))
                }
                .padding(.top, 12)

                Button {
                    authMode = .login
                    email = store.profile.email
                    showingForm = true
                } label: {
                    Text("Already have an account? ")
                        .foregroundStyle(AppTheme.forest.opacity(0.7))
                    + Text("Log in")
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.forest)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 28)
        }
        .sheet(isPresented: $showingForm) {
            loginForm
        }
    }

    private var loginForm: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(authMode.title)
                        .font(.system(size: 34, weight: .medium, design: .default))
                    Text(authMode.subtitle)
                        .foregroundStyle(AppTheme.secondary)
                }

                VStack(spacing: 14) {
                    if authMode == .signup {
                        TextField("Full name", text: $fullName)
                            .textContentType(.name)
                            .padding(17)
                            .background(AppTheme.canvas)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        TextField("Phone", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .padding(17)
                            .background(AppTheme.canvas)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding(17)
                        .background(AppTheme.canvas)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(17)
                        .background(AppTheme.canvas)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Toggle("Remember me", isOn: $rememberMe)
                    .tint(AppTheme.forest)

                Button(authMode.primaryAction) {
                    if authMode == .signup {
                        store.updateProfile(
                            fullName: fullName,
                            email: email,
                            phone: phone,
                            password: password
                        )
                    }
                    developerMode = false
                    isAuthenticated = true
                    showingForm = false
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(AppTheme.forest)
                .clipShape(Capsule())
                .disabled(!canSubmit)

                Button(authMode == .signup ? "Already have an account? Log in" : "Need an account? Sign up") {
                    authMode = authMode == .signup ? .login : .signup
                    if authMode == .signup {
                        fullName = store.profile.fullName == UserProfile.placeholder.fullName ? "" : store.profile.fullName
                        phone = store.profile.phone == UserProfile.placeholder.phone ? "" : store.profile.phone
                    }
                }
                .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.forest)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(24)
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingForm = false }
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(30)
    }

    private var canSubmit: Bool {
        if authMode == .signup {
            return !fullName.isEmpty && !email.isEmpty && !phone.isEmpty && !password.isEmpty
        }
        return !email.isEmpty && !password.isEmpty
    }
}

private enum AuthMode {
    case login
    case signup

    var title: String {
        switch self {
        case .login: "Welcome back"
        case .signup: "Create your account"
        }
    }

    var subtitle: String {
        switch self {
        case .login: "Log in to see your complete financial picture."
        case .signup: "Your profile will use the name, email, and phone you enter here."
        }
    }

    var primaryAction: String {
        switch self {
        case .login: "Log In"
        case .signup: "Sign Up"
        }
    }
}

private struct BrandMark: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(AppTheme.forest).frame(width: 24, height: 24)
                RoundedRectangle(cornerRadius: 5).fill(AppTheme.forest).frame(width: 24, height: 24).offset(x: 18, y: 18)
            }
            .frame(width: 42, height: 42)
            Text("TRACK IT")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(AppTheme.forest)
        }
    }
}
