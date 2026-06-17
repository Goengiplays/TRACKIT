import SwiftUI
#if canImport(LinkKit)
import LinkKit
#endif

struct PlaidConnectionView: View {
    @EnvironmentObject private var store: FinanceStore
    @AppStorage("trackerx.plaidBackendURL") private var backendURL = ""
    @State private var status = "Ready to connect"
    @State private var isLoading = false
    @State private var errorMessage: String?
    #if canImport(LinkKit)
    @State private var linkSession: PlaidLinkSession?
    @State private var isPresentingLink = false
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 14) {
                    IconBubble(systemName: "building.columns.fill", color: AppTheme.forest, size: 70)
                    Text("Connect your bank")
                        .font(.title2.weight(.medium))
                    Text("Plaid securely connects your financial institution. TRACK IT never sees or stores your bank password.")
                        .foregroundStyle(AppTheme.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("TRACK IT backend")
                        .font(.headline)
                    TextField("https://trackit-beige-sigma.vercel.app", text: $backendURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .padding(15)
                        .background(AppTheme.canvas)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text("Paste your Vercel backend URL here. On a real iPhone, use HTTPS from Vercel, not localhost.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                .padding(18)
                .trackerCard(radius: 20)

                Button {
                    connect()
                } label: {
                    HStack {
                        if isLoading { ProgressView().tint(.white) }
                        Text(isLoading ? "Preparing Plaid…" : "Connect financial account")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppTheme.forest)
                    .clipShape(Capsule())
                }
                .disabled(isLoading || backendURL.isEmpty)

                Label(status, systemImage: status.contains("Connected") ? "checkmark.circle.fill" : "lock.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(status.contains("Connected") ? AppTheme.forest : AppTheme.secondary)

                VStack(alignment: .leading, spacing: 14) {
                    SecurityRow(icon: "key.fill", text: "Credentials are handled by Plaid Link")
                    SecurityRow(icon: "arrow.triangle.2.circlepath", text: "Balances and transactions sync through your server")
                    SecurityRow(icon: "hand.raised.fill", text: "You can disconnect institutions at any time")
                }
                .padding(18)
                .background(AppTheme.limeSoft)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(22)
        }
        .background(AppTheme.background)
        .navigationTitle("Connect bank")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if backendURL.isEmpty {
                backendURL = "https://trackit-beige-sigma.vercel.app"
            }
        }
        .alert("Plaid connection", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        #if canImport(LinkKit)
        .sheet(isPresented: $isPresentingLink) {
            if let linkSession {
                linkSession.sheet()
            }
        }
        #endif
    }

    private func connect() {
        guard let baseURL = URL(string: backendURL) else {
            errorMessage = "Enter a valid HTTPS backend URL."
            return
        }
        isLoading = true
        status = "Requesting a secure Link token"

        Task {
            do {
                let token = try await PlaidAPI(baseURL: baseURL).createLinkToken()
                await MainActor.run {
                    isLoading = false
                    createPlaidSession(token: token, baseURL: baseURL)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    status = "Connection setup needed"
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    @MainActor
    private func createPlaidSession(token: String, baseURL: URL) {
        #if canImport(LinkKit)
        let configuration = LinkTokenConfiguration(
            token: token,
            onSuccess: { success in
                isPresentingLink = false
                status = "Finishing secure connection"
                Task {
                    do {
                        let snapshot = try await PlaidAPI(baseURL: baseURL).exchange(publicToken: success.publicToken)
                        await MainActor.run {
                            store.importPlaidSnapshot(snapshot)
                            status = "Connected with Plaid"
                        }
                    } catch {
                        await MainActor.run { errorMessage = error.localizedDescription }
                    }
                }
            },
            onExit: { exit in
                isPresentingLink = false
                status = exit.error == nil ? "Connection cancelled" : "Plaid needs attention"
            },
            onEvent: nil,
            onLoad: {
                status = "Plaid is ready"
            }
        )

        do {
            linkSession = try Plaid.createPlaidLinkSession(configuration: configuration)
            isPresentingLink = true
        } catch {
            errorMessage = error.localizedDescription
        }
        #else
        errorMessage = "LinkKit is not available in this build."
        #endif
    }
}

private struct SecurityRow: View {
    let icon: String
    let text: String

    var body: some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: icon).foregroundStyle(AppTheme.forest)
        }
    }
}

private struct PlaidAPI {
    let baseURL: URL

    func createLinkToken() async throws -> String {
        let url = baseURL.appending(path: "api/create_link_token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["client_user_id": "track-it-user"])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        let payload = try JSONDecoder().decode(LinkTokenResponse.self, from: data)
        return payload.linkToken
    }

    func exchange(publicToken: String) async throws -> PlaidSnapshot {
        let url = baseURL.appending(path: "api/exchange_public_token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["public_token": publicToken])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PlaidSnapshot.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw PlaidConnectionError.backendUnavailable
        }
    }
}

private struct LinkTokenResponse: Decodable {
    let linkToken: String

    enum CodingKeys: String, CodingKey {
        case linkToken = "link_token"
    }
}

private enum PlaidConnectionError: LocalizedError {
    case backendUnavailable

    var errorDescription: String? {
        "The TRACK IT Plaid backend is not configured or could not be reached."
    }
}
