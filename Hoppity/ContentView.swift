import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab: AppTab = .home

    var body: some View {
        // TabView preserves each tab's state + NavigationStack when switching
        // .toolbar(.hidden) removes the native iOS tab bar
        // .safeAreaInset adds our dark nav to the safe area chain so ALL
        // child views (including TourDetailView's bottom bar) stack correctly above it
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .environmentObject(auth)
            }
            .tag(AppTab.home)

            NavigationStack {
                ForYouView()
                    .environmentObject(auth)
            }
            .tag(AppTab.forYou)

            NavigationStack {
                ItineraryListingView()
                    .environmentObject(auth)
            }
            .tag(AppTab.tours)

            NavigationStack {
                CommunityView()
                    .environmentObject(auth)
            }
            .tag(AppTab.community)

            NavigationStack {
                ProfileView()
                    .environmentObject(auth)
            }
            .tag(AppTab.profile)
        }
        .toolbar(.hidden, for: .tabBar)          // hide native tab bar
        .safeAreaInset(edge: .bottom, spacing: 0) { darkBottomNav } // our custom nav adds to safe area
    }

    // MARK: - Dark bottom nav (mirrors Flutter _buildBottomNav)
    private var darkBottomNav: some View {
        VStack(spacing: 0) {
            // Top border line
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(
                                    selectedTab == tab
                                        ? AppTheme.primary
                                        : Color.white.opacity(0.38)
                                )
                            Text(tab.title)
                                .font(
                                    selectedTab == tab
                                        ? AppTheme.F.navLabelB
                                        : AppTheme.F.navLabel
                                )
                                .foregroundColor(
                                    selectedTab == tab
                                        ? AppTheme.primary
                                        : Color.white.opacity(0.38)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8) // above home indicator
            .background(AppTheme.bgDarkNav)
        }
        .background(AppTheme.bgDarkNav)
    }
}
