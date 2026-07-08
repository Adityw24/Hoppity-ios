import SwiftUI

struct SignInView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var email      = ""
    @State private var password   = ""
    @State private var showPwd    = false
    @State private var rememberMe = false
    @State private var showForgot = false
    @State private var showPhone  = false

    var body: some View {
        ZStack {
            // Dark gradient background (matches Flutter photo bg feel)
            LinearGradient(
                colors: [Color(hex: "#0d0020"), Color(hex: "#3d1070"), AppTheme.primary],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            Color.black.opacity(0.20).ignoresSafeArea()
            Color.white.opacity(0.10).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 24)

                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 18).fill(AppTheme.primary)
                            .frame(width: 85, height: 85)
                        Text("H")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer().frame(height: 20)

                    // WELCOME BACK — black, ExtraBold 34px (matches Flutter)
                    Text("WELCOME BACK")
                        .font(AppTheme.F.h1)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 6)

                    Text("Sign in to continue your journey")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 28)

                    // ── Email ────────────────────────────────────
                    GlassField(hint: "Email Id", text: $email,
                               icon: "envelope", keyboard: .emailAddress)

                    Spacer().frame(height: 16)

                    // ── Password ─────────────────────────────────
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

                    // Remember me + Forgot
                    HStack {
                        Button(action: { rememberMe.toggle() }) {
                            HStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white)
                                        .frame(width: 18, height: 18)
                                    if rememberMe {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppTheme.primary)
                                    }
                                }
                                Text("Remember me")
                                    .font(AppTheme.F.smallB)
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        Button(action: { showForgot = true }) {
                            Text("Forgot Password?")
                                .font(AppTheme.F.smallB)
                                .foregroundColor(.white)
                        }
                    }

                    // Error
                    if let err = auth.errorMessage {
                        Text(err).font(AppTheme.F.caption)
                            .foregroundColor(Color(hex: "#FF6B6B"))
                            .padding(.top, 8)
                    }

                    Spacer().frame(height: 16)

                    // Sign In button
                    GlassButton(label: "Sign In", loading: auth.isLoading) {
                        Task {
                            await auth.signIn(email: email, password: password)
                            if auth.isAuthenticated { dismiss() }
                        }
                    }

                    Spacer().frame(height: 20)

                    Text("Or")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)

                    Spacer().frame(height: 20)

                    // Google
                    GlassButton(
                        label: "Continue with Google",
                        icon: Image(systemName: "globe")
                    ) {
                        Task {
                            await auth.signInWithGoogle()
                            if auth.isAuthenticated { dismiss() }
                        }
                    }

                    Spacer().frame(height: 14)

                    // Phone
                    GlassButton(
                        label: "Continue with Phone",
                        icon: Image(systemName: "phone")
                    ) { showPhone = true }

                    Spacer().frame(height: 28)

                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(AppTheme.F.label).foregroundColor(.white)
                        Text("Sign up")
                            .font(AppTheme.F.label).foregroundColor(.black)
                            .onTapGesture { dismiss() }
                    }

                    Spacer().frame(height: 32)
                }
                .padding(.horizontal, 32)
            }
        }
        .sheet(isPresented: $showForgot) {
            ForgotPasswordView().environmentObject(auth)
        }
        .sheet(isPresented: $showPhone) {
            PhoneAuthView().environmentObject(auth)
        }
    }
}

// MARK: - Forgot Password
struct ForgotPasswordView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.S.lg) {
                Text("Reset Password").font(AppTheme.F.sectionH)
                Text("Enter your email to receive a reset link.")
                    .font(AppTheme.F.body).foregroundColor(AppTheme.textSub)
                    .multilineTextAlignment(.center)

                if sent {
                    Label("Reset link sent! Check your inbox.", systemImage: "envelope.fill")
                        .foregroundColor(AppTheme.success)
                    PrimaryBtn(label: "Done") { dismiss() }
                } else {
                    TextField("you@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    PrimaryBtn(label: "Send Reset Link", loading: auth.isLoading) {
                        Task { await auth.resetPassword(email: email); sent = true }
                    }
                }
                Spacer()
            }
            .padding(AppTheme.S.lg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
