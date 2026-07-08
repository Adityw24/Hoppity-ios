import SwiftUI

// MARK: - Async image
struct HoppityImage: View {
    let url: String?
    var mode: ContentMode = .fill
    var body: some View {
        Group {
            if let s = url, let u = URL(string: s) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: mode)
                    case .empty:
                        ProgressView().frame(maxWidth:.infinity, maxHeight:.infinity)
                            .background(Color.gray.opacity(0.1))
                    default: placeholder
                    }
                }
            } else { placeholder }
        }
    }
    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.12)
            Image(systemName: "photo").foregroundColor(.gray).font(.title2)
        }
    }
}

// MARK: - Primary button (purple stadium)
struct PrimaryBtn: View {
    let label: String
    var loading = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if loading { ProgressView().tint(.white).scaleEffect(0.8) }
                Text(label).font(AppTheme.F.bodyB).foregroundColor(.white)
            }
            .frame(maxWidth:.infinity).frame(height: 52)
            .background(AppTheme.primary).clipShape(Capsule())
        }.disabled(loading).opacity(loading ? 0.7 : 1)
    }
}

// MARK: - Outline button
struct OutlineBtn: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(AppTheme.F.bodyB).foregroundColor(.black)
                .frame(maxWidth:.infinity).frame(height: 52)
                .overlay(Capsule().stroke(Color.black, lineWidth: 1))
        }
    }
}

// MARK: - Glass button (auth screens) - semi-transparent dark pill
struct GlassButton: View {
    let label: String
    var loading = false
    var icon: Image? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    if let ic = icon {
                        ic.resizable().scaledToFit().frame(width:18, height:18)
                            .foregroundColor(.white)
                    }
                    Text(label)
                        .font(AppTheme.F.bodyB)
                        .foregroundColor(.white)
                        .shadow(color:.black.opacity(0.25), radius:4, y:4)
                }
            }
            .frame(width: 266, height: 48)
            .background(AppTheme.glassButton)
            .clipShape(Capsule())
        }.disabled(loading)
    }
}

// MARK: - Glass text field (auth screens)
// FIX: Forces .colorScheme(.light) so text is always BLACK on the frosted field,
// regardless of the dark background behind it. Matches Flutter's black text style.
struct GlassField: View {
    let hint: String
    @Binding var text: String
    var icon: String = "envelope"
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var suffix: AnyView? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#000000").opacity(0.54))
                .font(.system(size: 18))

            Group {
                if isSecure {
                    SecureField("", text: $text, prompt:
                        Text(hint)
                            .font(AppTheme.F.bodyB)
                            .foregroundColor(Color(hex: "#595959").opacity(0.7))
                    )
                } else {
                    TextField("", text: $text, prompt:
                        Text(hint)
                            .font(AppTheme.F.bodyB)
                            .foregroundColor(Color(hex: "#595959").opacity(0.7))
                    )
                    .keyboardType(keyboard)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }
            }
            .font(AppTheme.F.bodyB)
            .foregroundColor(.black)   // typed text = black

            if let s = suffix { s }
        }
        .frame(height: 54)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.30))
        .clipShape(Capsule())
        // ↓ This is the key fix - forces light mode inside the field
        // so iOS renders black text even on a dark background
        .colorScheme(.light)
    }
}

// MARK: - Stat chip (tour detail quick-stats)
struct StatChip: View {
    let icon: String
    let label: String
    var color: Color = .black.opacity(0.54)
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
            Text(label).font(AppTheme.F.small).foregroundColor(.black)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(AppTheme.grey100)
        .clipShape(Capsule())
    }
}

// MARK: - Section header
struct SectionH: View {
    let title: String
    var body: some View {
        Text(title).font(AppTheme.F.sectionH).foregroundColor(.black)
    }
}

// MARK: - Bullet item
struct BulletItem: View {
    let text: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundColor(color).padding(.top, 1)
            Text(text).font(AppTheme.F.label).foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }.padding(.bottom, 4)
    }
}

// MARK: - Itinerary day row
struct ItineraryDayRow: View {
    let day: ItineraryDay
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(AppTheme.primary).frame(width:28, height:28)
                Text("\(day.dayNumber)").font(AppTheme.F.smallB).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(day.title).font(AppTheme.F.label).foregroundColor(.black)
                if !day.description.isEmpty {
                    Text(day.description).font(AppTheme.F.caption)
                        .foregroundColor(.black.opacity(0.54)).lineSpacing(2)
                }
            }
            Spacer()
        }.padding(.bottom, 10)
    }
}

// MARK: - Loading
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView().tint(AppTheme.primary).scaleEffect(1.2)
            Text("Loading...").font(AppTheme.F.caption).foregroundColor(AppTheme.textMuted)
        }.frame(maxWidth:.infinity, maxHeight:.infinity)
    }
}

// MARK: - WhatsApp
func launchWhatsApp(tourTitle: String) {
    let msg = "Hi Hoppity, I want to book: \(tourTitle)"
    let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    if let url = URL(string: "https://wa.me/919752377323?text=\(encoded)") {
        UIApplication.shared.open(url)
    }
}

// MARK: - Corner radius helper
extension View {
    func cornerRadius(_ r: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: r, corners: corners))
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat; var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

// MARK: - Flow layout (wrapping chips)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > w && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, s.height); x += s.width + spacing
        }
        return CGSize(width: w, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX {
                y += rowH + spacing; x = bounds.minX; rowH = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            rowH = max(rowH, s.height); x += s.width + spacing
        }
    }
}
