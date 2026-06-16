import SwiftUI

enum AppTab: Hashable {
    case home, analytics, add, categories, bills
}

struct RootView: View {
    @AppStorage("trackerx.isAuthenticated") private var isAuthenticated = false
    @State private var selection: AppTab = .home
    @State private var showingAddEntry = false
    @State private var showingAssistant = false

    var body: some View {
        Group {
            if isAuthenticated {
                appTabs
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
    }

    private var appTabs: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                NavigationStack { AccountsView() }
                    .tag(AppTab.home)
                    .tabItem { Label("Home", systemImage: "wallet.bifold.fill") }

                NavigationStack { AnalyticsView(showingAddEntry: $showingAddEntry) }
                    .tag(AppTab.analytics)
                    .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }

                Color.clear
                    .tag(AppTab.add)
                    .tabItem { Text("") }

                NavigationStack { CategoriesView() }
                    .tag(AppTab.categories)
                    .tabItem { Label("Categories", systemImage: "square.grid.2x2.fill") }

                NavigationStack { BillsView() }
                    .tag(AppTab.bills)
                    .tabItem { Label("Bills", systemImage: "calendar.badge.clock") }
            }

            Button {
                showingAddEntry = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(AppTheme.blue)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.surface, lineWidth: 5))
                    .shadow(color: AppTheme.blue.opacity(0.28), radius: 14, y: 7)
            }
            .padding(.bottom, 17)
            .accessibilityLabel("Add transaction")

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingAssistant = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(
                                LinearGradient(colors: [AppTheme.blue, AppTheme.assistantPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                            .shadow(color: AppTheme.blue.opacity(0.3), radius: 14, y: 7)
                    }
                    .accessibilityLabel("Open Track AI")
                    .padding(.trailing, 18)
                    .padding(.bottom, 92)
                }
            }
        }
        .tint(AppTheme.forest)
        .onChange(of: selection) { _, newValue in
            if newValue == .add {
                showingAddEntry = true
                selection = .home
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView()
        }
        .fullScreenCover(isPresented: $showingAssistant) {
            AIAssistantView()
        }
    }
}
