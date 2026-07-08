import SwiftUI

// Mirrors Flutter WelcomeScreen exactly:
// Full bleed photo bg + white bottom sheet + WELCOME + Sign In / Sign Up / Phone
struct WelcomeView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var showSignIn  = false
    @State private var showSignUp  = false
    @State private var showPhone   = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background photo — use a gradient as placeholder (app doesn't have bundled image)
                LinearGradient(colors: [Color(hex: "#1a0533"), Color(hex: "#4a1a8a"), Color(hex: "#7B39EA")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                // Dark overlay
                Color.black.opacity(0.20).ignoresSafeArea()

                // Logo — centred at ~14% from top
                VStack {
                    Spacer().frame(height: geo.size.height * 0.14)
                    logoView
                    Spacer()
                }

                // White bottom sheet — 42% of screen height
                VStack {
                    Spacer()
                    bottomSheet(geo: geo)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .sheet(isPresented: $showSignIn) { SignInView().environmentObject(auth) }
        .sheet(isPresented: $showSignUp) { SignUpView().environmentObject(auth) }
        .sheet(isPresented: $showPhone)  { PhoneAuthView().environmentObject(auth) }
    }

    private var logoView: some View {
        // Purple H logo placeholder
        ZStack {
            RoundedRectangle(cornerRadius: 24).fill(AppTheme.primary)
                .frame(width: 160, height: 160)
            Text("H").font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private func bottomSheet(geo: GeometryProxy) -> some View {
        let sheetH = geo.size.height * 0.42 + geo.safeAreaInsets.bottom
        return VStack(alignment: .center, spacing: 0) {
            Spacer().frame(height: 32)

            Text("WELCOME")
                .font(AppTheme.F.h1)
                .foregroundColor(.black)

            Text("Explore your favourite journey")
                .font(AppTheme.F.h3).fontWeight(.bold)
                .foregroundColor(.black.opacity(0.62))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer().frame(height: 32)

            // Sign In — purple filled
            PrimaryBtn(label: "Sign In") { showSignIn = true }
                .padding(.horizontal, 48)

            Spacer().frame(height: 16)

            // Sign Up — outlined
            OutlineBtn(label: "Sign up") { showSignUp = true }
                .padding(.horizontal, 48)

            Spacer().frame(height: 12)

            // Phone
            Button(action: { showPhone = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "phone").font(.system(size: 18))
                    Text("Continue with Phone").font(AppTheme.F.bodyB)
                }
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity).frame(height: 52)
                .overlay(Capsule().stroke(AppTheme.primary, lineWidth: 1))
                .padding(.horizontal, 48)
            }

            Spacer()
        }
        .frame(height: sheetH)
        .background(
            Color.white
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        )
    }
}
