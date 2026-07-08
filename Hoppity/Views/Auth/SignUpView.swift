import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email      = ""
    @State private var password   = ""
    @State private var showPwd    = false
    @State private var agreeTerms = false
    @State private var showPhone  = false
    @State private var showTerms  = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0d0020"), Color(hex: "#3d1070"), AppTheme.primary],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()
            Color.black.opacity(0.20).ignoresSafeArea()
            Color.white.opacity(0.10).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 24)

                    ZStack {
                        RoundedRectangle(cornerRadius: 18).fill(AppTheme.primary)
                            .frame(width: 85, height: 85)
                        Text("H")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer().frame(height: 20)

                    Text("Create an Account!")
                        .font(AppTheme.F.h1).foregroundColor(.white)
                        .frame(maxWidth:.infinity, alignment: .leading)

                    Spacer().frame(height: 6)

                    Text("Sign up to start your journey")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.60))
                        .frame(maxWidth:.infinity, alignment: .leading)

                    Spacer().frame(height: 28)

                    GlassField(hint: "Email Id", text: $email,
                               icon: "envelope", keyboard: .emailAddress)

                    Spacer().frame(height: 16)

                    GlassField(
                        hint: "Password",
                        text: $password,
                        icon: "lock",
                        isSecure: !showPwd,
                        suffix: AnyView(
                            Button(action: { showPwd.toggle() }) {
                                Image(systemName: showPwd ? "eye" : "eye.slash")
                                    .foregroundColor(.black.opacity(0.54))
                                    .font(.system(size: 16))
                            }
                        )
                    )

                    Spacer().frame(height: 12)

                    // Terms
                    HStack(spacing: 6) {
                        Button(action: { agreeTerms.toggle() }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 18, height: 18)
                                if agreeTerms {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        Text("Agree with ")
                            .font(AppTheme.F.smallB).foregroundColor(.white)
                        Text("terms and conditions.")
                            .font(AppTheme.F.smallB).foregroundColor(.black)
                            .onTapGesture { showTerms = true }
                        Spacer()
                    }

                    if let err = auth.errorMessage {
                        Text(err).font(AppTheme.F.caption)
                            .foregroundColor(Color(hex: "#FF6B6B"))
                            .padding(.top, 8)
                    }

                    Spacer().frame(height: 16)

                    GlassButton(label: "Sign Up", loading: auth.isLoading) {
                        guard agreeTerms else {
                            auth.errorMessage = "Please agree to the terms."
                            return
                        }
                        Task {
                            await auth.signUp(email: email, password: password)
                            if auth.isAuthenticated { dismiss() }
                        }
                    }

                    Spacer().frame(height: 20)
                    Text("Or")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                    Spacer().frame(height: 20)

                    GlassButton(label: "Continue with Google",
                                icon: Image(systemName: "globe")) {
                        Task {
                            await auth.signInWithGoogle()
                            if auth.isAuthenticated { dismiss() }
                        }
                    }

                    Spacer().frame(height: 14)

                    GlassButton(label: "Continue with Phone",
                                icon: Image(systemName: "phone")) {
                        showPhone = true
                    }

                    Spacer().frame(height: 28)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(AppTheme.F.label).foregroundColor(.white)
                        Text("Sign In")
                            .font(AppTheme.F.label).foregroundColor(.black)
                            .onTapGesture { dismiss() }
                    }

                    Spacer().frame(height: 32)
                }
                .padding(.horizontal, 32)
            }
        }
        .sheet(isPresented: $showPhone) {
            PhoneAuthView().environmentObject(auth)
        }
        .alert("Terms & Conditions", isPresented: $showTerms) {
            Button("Close") {}
        } message: {
            Text("By creating an account you agree to Hoppity's terms of service. Bookings subject to individual tour cancellation policies. Visit hoppity.in/terms for full details.")
        }
    }
}
