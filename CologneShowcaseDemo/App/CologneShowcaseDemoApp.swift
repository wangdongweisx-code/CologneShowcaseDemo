import SwiftUI

@main
struct CologneShowcaseDemoApp: App {
    init() {
        BrandFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            RootDemoView()
                .preferredColorScheme(.light)
                .tint(.brandPlum)
                .environment(\.font, .brandBody())
                // The approved Figma screens already include their own iOS
                // status bar. Hide the live one so time/Wi-Fi never doubles.
                .statusBarHidden(true)
        }
    }
}
