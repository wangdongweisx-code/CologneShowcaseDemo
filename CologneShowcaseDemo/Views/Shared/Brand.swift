import CoreText
import SwiftUI

extension Color {
    static let brandPlum = Color("BrandPlum")
    static let brandInk = Color("BrandInk")
    static let brandBlush = Color("BrandBlush")
    static let brandCanvas = Color("BrandCanvas")
    static let brandSoft = Color("BrandSoft")
}

extension Font {
    static let aeonikRegularName = "AeonikSoftPro-Regular"
    static let aeonikMediumName = "AeonikSoftPro-Medium"
    static let aeonikSemiBoldName = "AeonikSoftPro-SemiBold"
    static let aeonikBoldName = "AeonikSoftPro-Bold"
    static let exposureMinus10Name = "Exposure-10-Regular"

    static var brandDisplay: Font {
        .custom(exposureMinus10Name, size: 34, relativeTo: .largeTitle)
    }

    static var brandDisplaySmall: Font {
        .custom(exposureMinus10Name, size: 22, relativeTo: .title2)
    }

    static func brandBody(
        _ size: CGFloat = 17,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        .custom(aeonikRegularName, size: size, relativeTo: style)
    }

    static func brandMedium(
        _ size: CGFloat = 17,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        .custom(aeonikMediumName, size: size, relativeTo: style)
    }

    static func brandSemiBold(
        _ size: CGFloat = 17,
        relativeTo style: Font.TextStyle = .headline
    ) -> Font {
        .custom(aeonikSemiBoldName, size: size, relativeTo: style)
    }
}

enum BrandFonts {
    /// `UIAppFonts` cannot be supplied through `INFOPLIST_KEY_*`, so the bundled
    /// families are registered at launch. Without this every `.brand*` font
    /// silently falls back to the system face.
    static func register() {
        guard
            let root = Bundle.main.url(forResource: "Fonts", withExtension: nil),
            let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        else { return }

        for case let url as URL in files where ["otf", "ttf"].contains(url.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

struct BrandBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.brandCanvas, .brandCanvas, .brandSoft],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct PrimaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brandSemiBold())
            .foregroundStyle(Color.white)
            .padding(.horizontal, 22)
            .frame(minHeight: 48)
            .background(Color.brandPlum.opacity(configuration.isPressed ? 0.78 : 1), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct DemoCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground), in: .rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.06), radius: 18, y: 6)
    }
}

extension View {
    func demoCard() -> some View {
        modifier(DemoCardModifier())
    }
}
