import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(Supabase)
import Supabase
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@MainActor
final class AuthManager: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isAuthenticated: Bool = false

    #if canImport(Supabase)
    private var client: SupabaseClient?
    #endif

    init() {
        #if canImport(Supabase)
        if !SupabaseConfig.urlString.isEmpty,
           let url = URL(string: SupabaseConfig.urlString),
           !SupabaseConfig.anonKey.isEmpty {
            client = SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
        } else {
            client = nil
        }
        #endif
    }

    func sendPhoneOTP(phone: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if canImport(Supabase)
        guard let client else {
            errorMessage = "Supabase not configured. Set SupabaseConfig.urlString and anonKey."
            return
        }
        let phoneNumber = normalizedPhone(phone)
        do {
            _ = try await client.auth.signInWithOTP(phone: phoneNumber)
        } catch {
            errorMessage = "OTP send failed: \(error.localizedDescription)"
        }
        #else
        errorMessage = "Supabase SDK not found. Add the Supabase Swift package to enable OTP."
        #endif
    }

    func verifyPhoneOTP(phone: String, token: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if canImport(Supabase)
        guard let client else {
            errorMessage = "Supabase not configured. Set SupabaseConfig.urlString and anonKey."
            return
        }
        let phoneNumber = normalizedPhone(phone)
        do {
            _ = try await client.auth.verifyOTP(phone: phoneNumber, token: token, type: .sms)
            isAuthenticated = true
        } catch {
            errorMessage = "OTP verification failed: \(error.localizedDescription)"
        }
        #else
        errorMessage = "Supabase SDK not found. Add the Supabase Swift package to enable OTP."
        #endif
    }

    #if canImport(GoogleSignIn)
    func signInWithGoogle(presenter: UIViewController) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            let idToken = result.user.idToken?.tokenString ?? ""
            // Try a couple of access token paths to be resilient across SDK versions.
            let accessToken: String? = {
                // Preferred path
                if let token = (result.user as AnyObject).value(forKeyPath: "accessToken.tokenString") as? String {
                    return token
                }
                // Fallback path
                if let token = (result.user as AnyObject).value(forKey: "accessToken") as? String {
                    return token
                }
                return nil
            }()

            #if canImport(Supabase)
            guard let client else {
                // If Supabase isn’t configured, consider the Google step successful but don’t mark authenticated.
                errorMessage = "Supabase not configured. Set SupabaseConfig to complete Google sign-in."
                return
            }
            do {
                // Modern credentials-based API
                try await client.auth.signInWithIdToken(
                    credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
                )
                isAuthenticated = true
            } catch {
                // Fallback to an older signature if the above isn’t available in the linked SDK version
                do {
                    try await client.auth.signInWithIdToken(provider: .google, idToken: idToken, accessToken: accessToken)
                    isAuthenticated = true
                } catch {
                    errorMessage = "Supabase Google Sign-In failed: \(error.localizedDescription)"
                }
            }
            #else
            // Google sign-in succeeded, but Supabase isn’t linked.
            isAuthenticated = true
            #endif
        } catch {
            errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
        }
    }
    #endif

    private func normalizedPhone(_ phone: String) -> String {
        if phone.hasPrefix("+") { return phone }
        // Default country code to +91 if not provided. Adjust as needed.
        return "+91" + phone
    }
}
