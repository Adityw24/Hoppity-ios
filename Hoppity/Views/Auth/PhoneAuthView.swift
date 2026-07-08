import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

struct PhoneAuthView: View {
    @StateObject private var ownedAuth: AuthManager
    @ObservedObject private var injectedAuth: AuthManager
    private let useInjected: Bool
    private var auth: AuthManager { useInjected ? injectedAuth : ownedAuth }
    @Environment(\.dismiss) var dismiss
    @State private var phone   = ""
    @State private var otp     = ""
    @State private var otpSent = false

    init(auth: AuthManager? = nil) {
        if let auth {
            _ownedAuth = StateObject(wrappedValue: AuthManager())
            _injectedAuth = ObservedObject(wrappedValue: auth)
            useInjected = true
        } else {
            let defaultAuth = AuthManager()
            _ownedAuth = StateObject(wrappedValue: defaultAuth)
            _injectedAuth = ObservedObject(wrappedValue: defaultAuth)
            useInjected = false
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0d0020"), Color(hex: "#3d1070"), AppTheme.primary],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            Color.black.opacity(0.20).ignoresSafeArea()
            Color.white.opacity(0.10).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(AppTheme.primary).frame(width: 85, height: 85)
                    Text("H").font(.system(size: 44, weight: .black, design: .rounded)).foregroundColor(.white)
                }

                Spacer().frame(height: 20)

                Text(otpSent ? "VERIFY OTP" : "PHONE LOGIN")
                    .font(AppTheme.F.h1).foregroundColor(.black)

                Text(otpSent ? "Enter the 6-digit code sent to +91\(phone)" : "Enter your mobile number")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.black).multilineTextAlignment(.center).padding(.top, 6)

                Spacer().frame(height: 32)

                if !otpSent {
                    HStack(spacing: 10) {
                        Text("+91")
                            .font(AppTheme.F.bodyB).foregroundColor(.black)
                            .frame(width: 54, height: 54)
                            .background(AppTheme.glassField).clipShape(Capsule())
                        GlassField(hint: "10-digit number", text: $phone,
                                   icon: "phone", keyboard: .phonePad)
                    }
                } else {
                    GlassField(hint: "6-digit OTP", text: $otp, icon: "lock.shield", keyboard: .numberPad)
                }

                if let err = auth.errorMessage {
                    Text(err).font(AppTheme.F.caption).foregroundColor(.red).padding(.top, 8)
                }

                Spacer().frame(height: 24)

                if !otpSent {
                    GlassButton(label: "Send OTP", loading: auth.isLoading) {
                        Task { await auth.sendPhoneOTP(phone: phone); if auth.errorMessage == nil { otpSent = true } }
                    }
                } else {
                    GlassButton(label: "Verify OTP", loading: auth.isLoading) {
                        Task {
                            await auth.verifyPhoneOTP(phone: phone, token: otp)
                            if auth.isAuthenticated { dismiss() }
                        }
                    }
                    Spacer().frame(height: 14)
                    Button(action: { Task { await auth.sendPhoneOTP(phone: phone) } }) {
                        Text("Resend OTP").font(AppTheme.F.small).foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer().frame(height: 22)
                Text("Or continue with")
                    .font(AppTheme.F.small)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 4)
                GoogleSignInButtonView(auth: auth)

#if targetEnvironment(simulator)
                Spacer().frame(height: 8)
                Text("Simulator detected: Use test phone numbers for OTP (e.g., with Firebase). Real SMS won't arrive on the simulator.")
                    .font(AppTheme.F.small)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
#endif
                Spacer()
            }
            .padding(.horizontal, 32)
#if canImport(GoogleSignIn)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
#endif
        }
    }
}

struct PhoneAuthViewHost: View {
    @StateObject private var auth = AuthManager()
    var body: some View {
        PhoneAuthView(auth: auth)
    }
}

#Preview("PhoneAuthView") {
    PhoneAuthViewHost()
}
