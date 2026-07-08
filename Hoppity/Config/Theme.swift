import SwiftUI
import Supabase

enum AppTheme {
    static let primary      = Color(hex: "#7B39EA")
    static let teal         = Color(hex: "#007A63")
    static let bgWhite      = Color.white
    static let bgFeed       = Color.black
    static let bgDarkNav    = Color(hex: "#1A1A1A")
    static let bgLight      = Color(hex: "#F7F1FF")
    static let textPrimary  = Color(hex: "#020617")
    static let textSub      = Color(hex: "#475569")
    static let textMuted    = Color(hex: "#94A3B8")
    static let border       = Color(hex: "#E2E8F0")
    static let grey100      = Color(hex: "#F3F4F6")
    static let error        = Color(hex: "#EF4444")
    static let success      = Color(hex: "#10B981")
    static let whatsApp     = Color(hex: "#25D366")
    static let glassField   = Color.white.opacity(0.30)
    static let glassButton  = Color(hex: "#6F6F6F").opacity(0.50)

    enum F {
        static let appName  = ft(28, "Bold")
        static let h1       = ft(34, "ExtraBold")
        static let h2       = ft(26, "Bold")
        static let h3       = ft(20, "SemiBold")
        static let sectionH = ft(18, "SemiBold")
        static let body     = ft(15, "Medium")
        static let bodyB    = ft(15, "SemiBold")
        static let label    = ft(14, "SemiBold")
        static let caption  = ft(13, "Medium")
        static let captionB = ft(13, "SemiBold")
        static let small    = ft(12, "SemiBold")
        static let smallB   = ft(12, "Bold")
        static let tiny     = ft(10, "Bold")
        static let navLabel = ft(10, "Regular")
        static let navLabelB = ft(10, "SemiBold")

        static func ft(_ size: CGFloat, _ w: String) -> Font {
            let name = "Figtree-\(w)"
            if UIFont(name: name, size: size) != nil { return .custom(name, size: size) }
            switch w {
            case "ExtraBold": return .system(size: size, weight: .black,    design: .rounded)
            case "Bold":      return .system(size: size, weight: .bold,     design: .rounded)
            case "SemiBold":  return .system(size: size, weight: .semibold, design: .rounded)
            case "Medium":    return .system(size: size, weight: .medium,   design: .rounded)
            default:          return .system(size: size, weight: .regular,  design: .rounded)
            }
        }
    }

    enum S {
        static let xs: CGFloat = 4;  static let sm: CGFloat = 8
        static let md: CGFloat = 16; static let lg: CGFloat = 24
        static let xl: CGFloat = 32; static let xxl: CGFloat = 48
    }

    enum R {
        static let chip: CGFloat = 20;  static let field: CGFloat = 25
        static let btn:  CGFloat = 40;  static let card:  CGFloat = 16
        static let hero: CGFloat = 30;  static let full:  CGFloat = 999
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
