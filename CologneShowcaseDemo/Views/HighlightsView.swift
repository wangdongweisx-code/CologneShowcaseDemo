import SwiftUI

/// Selling-points page rebuilt from Figma node 2311:1468
/// (the development handoff frame inside page 2213:5891).
///
/// All decorative artwork is exported from its original Figma layer at 3x.
/// Titles remain native SwiftUI text and no additional card frame is drawn.
struct HighlightsView: View {
    @ObservedObject var store: DemoStore

    private let designSize = CGSize(width: 402, height: 871.67)

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / designSize.width,
                proxy.size.height / designSize.height
            )

            ZStack {
                Color(red: 87 / 255, green: 10 / 255, blue: 28 / 255)
                    .ignoresSafeArea()

                sellingCanvas
                    .frame(width: designSize.width, height: designSize.height)
                    .scaleEffect(scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private var sellingCanvas: some View {
        ZStack(alignment: .topLeading) {
            Image("SellingBackground")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: designSize.width, height: designSize.height)
                .clipped()

            header

            sellingCard(
                feature: .deviceAssistant,
                title: "AI Device Assistant",
                assetName: "SellingDevice",
                frame: CGRect(x: 31.15, y: 170.42, width: 163.72, height: 323.24),
                titleWidth: 143.19
            )

            sellingCard(
                feature: .voiceLog,
                title: "AI Voice Log",
                assetName: "SellingVoice",
                frame: CGRect(x: 31.15, y: 505.63, width: 163.72, height: 323.24),
                titleWidth: 143.77
            )

            sellingCard(
                feature: .lactationPlan,
                title: "AI Lactation Plan",
                assetName: "SellingPlan",
                frame: CGRect(x: 206.63, y: 170.42, width: 163.72, height: 211.19),
                titleWidth: 115.84
            )

            sellingCard(
                feature: .lactationTimeline,
                title: "Tailored Breastfeeding\nTimeline",
                assetName: "SellingTimeline",
                frame: CGRect(x: 207.14, y: 393.89, width: 163.72, height: 211.19),
                titleWidth: 163.72
            )

            sellingCard(
                feature: .community,
                title: "Mom Groups",
                assetName: "SellingGroups",
                frame: CGRect(x: 207.14, y: 617.35, width: 163.72, height: 211.19),
                titleWidth: 117.46
            )
        }
        .frame(width: designSize.width, height: designSize.height, alignment: .topLeading)
        .clipped()
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            Image("SellingLogo")
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .frame(width: 202.39, height: 25.95)
                .position(x: 134.95, y: 104.72)

            Text("Your Pumping Journey, All in One Place.")
                // The exhibition screen is a fixed Figma handoff canvas.
                // A fixed font size prevents the phone's Dynamic Type setting
                // from wrapping or clipping this one-line approved headline.
                .font(.custom(Font.aeonikRegularName, fixedSize: 16.366))
                .foregroundStyle(Color(red: 1, green: 221 / 255, blue: 225 / 255))
                .frame(width: 334.49, height: 20, alignment: .leading)
                .lineLimit(1)
                .position(x: 201, y: 135.87)

            Button {
                store.isDisclaimerPresented = true
                store.userDidInteract()
            } label: {
                Image("SellingInfo")
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .frame(width: 24.55, height: 24.55)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .position(x: 355.97, y: 104.02)
            .accessibilityLabel("Open disclaimer")
        }
    }

    private func sellingCard(
        feature: ShowcaseFeature,
        title: String,
        assetName: String,
        frame: CGRect,
        titleWidth: CGFloat
    ) -> some View {
        Button {
            store.showCover(feature)
        } label: {
            ZStack(alignment: .top) {
                Image(assetName)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: frame.width, height: frame.height)

                Text(title)
                    .font(.custom(Font.exposureMinus10Name, fixedSize: 13))
                    .foregroundStyle(Color(red: 62 / 255, green: 0, blue: 16 / 255))
                    .tracking(-0.26)
                    .multilineTextAlignment(.center)
                    .lineSpacing(0)
                    .frame(width: titleWidth, height: title.contains("\n") ? 32 : 16)
                    .padding(.top, 24)
            }
            .frame(width: frame.width, height: frame.height)
            // Figma node 2311:1468 uses a real 24.55 pt corner mask on
            // every card. `contentShape` alone only changes hit testing and
            // leaves the exported bitmap's rectangular canvas visible.
            .background(
                Color.white.opacity(0.8),
                in: RoundedRectangle(cornerRadius: 24.55, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24.55, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24.55, style: .continuous))
        }
        .buttonStyle(SellingCardButtonStyle())
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        .accessibilityLabel(title.replacingOccurrences(of: "\n", with: " "))
    }
}

private struct SellingCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}
