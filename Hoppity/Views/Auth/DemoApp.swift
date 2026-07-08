#if DEMO_APP
import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@main
struct DemoApp: App {
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            PhoneAuthView(auth: auth)
                #if canImport(GoogleSignIn)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                #endif
        }
    }
}
#endif
