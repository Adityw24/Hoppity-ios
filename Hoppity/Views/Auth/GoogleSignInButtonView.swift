import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// A small, self-contained Google Sign-In button.
// - If GoogleSignIn is present, it performs the sign-in flow using the modern async API.
// - If not present, it shows a disabled button with a setup hint.
struct GoogleSignInButtonView: View {
    @ObservedObject var auth: AuthManager
    @State private var status: String?

    var body: some View {
        VStack(spacing: 8) {
            Button(action: signIn) {
                HStack(spacing: 8) {
                    Image(systemName: "g.circle.fill")
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let status {
                Text(status)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            if let err = auth.errorMessage {
                Text(err)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func signIn() {
        #if canImport(GoogleSignIn)
        guard let presenter = UIApplication.shared.topMostViewController() else {
            status = "Unable to present Google Sign-In."
            return
        }
        Task {
            await auth.signInWithGoogle(presenter: presenter)
            if auth.isAuthenticated {
                status = "Signed in with Google"
            }
        }
        #else
        status = "GoogleSignIn SDK not found. Add the package and configure URL types."
        #endif
    }
}

#if canImport(UIKit)
extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC: UIViewController? = {
            if let base { return base }
            // Try to find a key window from connected scenes
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes
                .compactMap { $0 as? UIWindowScene }
                .first
            let keyWindow = windowScene?.windows.first { $0.isKeyWindow }
            return keyWindow?.rootViewController
        }()

        if let nav = baseVC as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = baseVC?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return baseVC
    }
}
#endif
