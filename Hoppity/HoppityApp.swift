import SwiftUI
import Supabase

@main
struct HoppityApp: App {
    @StateObject private var auth = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .task { await auth.checkSession() }
                .onOpenURL { url in
                    // Handle Google OAuth + magic link callbacks
                    // Supabase.session(from:) requires this file to import Supabase
                    Task { await auth.handleOAuthCallback(url: url) }
                }
        }
    }
}
