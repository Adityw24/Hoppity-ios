import Foundation
import UIKit
import Combine
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: HoppityUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() { Task { await checkSession() } }

    // MARK: - Check session on launch
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            await fetchProfile(userId: session.user.id.uuidString)
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    // MARK: - Email Sign Up
    func signUp(email: String, password: String, fullName: String = "") async {
        isLoading = true; errorMessage = nil
        do {
            let r = try await supabase.auth.signUp(email: email, password: password)
            let uid = r.user.id.uuidString
            _ = try? await supabase.from("Users")
                .upsert(["user_id": uid, "email": email, "full_name": fullName])
                .execute()
            isAuthenticated = true
            await fetchProfile(userId: uid)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Email Sign In
    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let s = try await supabase.auth.signIn(email: email, password: password)
            isAuthenticated = true
            await fetchProfile(userId: s.user.id.uuidString)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Google Sign In
    // getOAuthSignInURL is synchronous in this SDK version — no await
    func signInWithGoogle() async {
        isLoading = true; errorMessage = nil
        do {
            let url = try supabase.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: URL(string: "io.supabase.hoppity://login-callback")!
            )
            await UIApplication.shared.open(url)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Handle OAuth callback URL (called from onOpenURL in HoppityApp)
    // session(from:) requires `import Supabase` in the calling file
    func handleOAuthCallback(url: URL) async {
        do {
            let session = try await supabase.auth.session(from: url)
            isAuthenticated = true
            await fetchProfile(userId: session.user.id.uuidString)
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Phone OTP - Send
    func sendPhoneOTP(phone: String) async {
        isLoading = true; errorMessage = nil
        let formatted = phone.hasPrefix("+") ? phone : "+91\(phone)"
        do {
            try await supabase.auth.signInWithOTP(phone: formatted)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Phone OTP - Verify
    func verifyPhoneOTP(phone: String, token: String) async {
        isLoading = true; errorMessage = nil
        let formatted = phone.hasPrefix("+") ? phone : "+91\(phone)"
        do {
            try await supabase.auth.verifyOTP(
                phone: formatted,
                token: token,
                type: .sms
            )
            let session = try await supabase.auth.session
            isAuthenticated = true
            await fetchProfile(userId: session.user.id.uuidString)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Reset Password
    func resetPassword(email: String) async {
        isLoading = true; errorMessage = nil
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() async {
        do { try await supabase.auth.signOut() } catch {}
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - Delete Account (Apple Guideline 5.1.1v)
    func deleteAccount() async -> Bool {
        isLoading = true; errorMessage = nil
        do {
            _ = try await supabase.rpc("delete_user_account").execute()
            try? await supabase.auth.signOut()
            isAuthenticated = false
            currentUser = nil
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Fetch Profile
    func fetchProfile(userId: String) async {
        do {
            let u: HoppityUser = try await supabase
                .from("Users")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            currentUser = u
        } catch {}
    }

    // MARK: - Update Profile
    func updateProfile(fullName: String?, bio: String?,
                       username: String?, location: String?) async {
        guard let uid = currentUser?.userId else { return }
        isLoading = true
        do {
            var updates: [String: String] = [:]
            if let v = fullName { updates["full_name"] = v }
            if let v = bio      { updates["bio"] = v }
            if let v = username { updates["username"] = v }
            if let v = location { updates["location"] = v }
            _ = try await supabase
                .from("Users")
                .update(updates)
                .eq("user_id", value: uid)
                .execute()
            await fetchProfile(userId: uid)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
