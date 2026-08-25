import SwiftUI

struct CoverCarouselView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                FigmaScreenView(assetName: store.selectedFeature.figmaCoverAsset)
                    .id(store.selectedFeature)

                coverMotion(in: proxy.size)
                coverHeader(in: proxy.size)
                coverNavigationBackdrop(in: proxy.size)
                coverNavigation(in: proxy.size)
            }
            .onLongPressGesture(minimumDuration: 0.8) {
                store.isDisclaimerPresented = true
            }
        }
        .ignoresSafeArea()
    }

    private func coverHeader(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 420

        return ZStack {
            LinearGradient(
                colors: [
                    Color(red: 249 / 255, green: 247 / 255, blue: 245 / 255),
                    Color(red: 1, green: 247 / 255, blue: 250 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Button {
                store.showHighlights()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18 * scale, weight: .medium))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 44 * scale, height: 44 * scale)
                    .background(Color.white.opacity(0.68), in: Circle())
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.72), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.10), radius: 18 * scale, y: 7 * scale)
            }
            .buttonStyle(.plain)
            .position(x: 42 * scale, y: 30 * scale)
            .accessibilityLabel("Back to selling points")

            Button {
                store.startDemo(store.selectedFeature)
            } label: {
                Text("Start Demo")
                    .font(.custom(Font.aeonikSemiBoldName, size: 16 * scale, relativeTo: .headline))
                    .foregroundStyle(Color.white)
                    .frame(width: 117 * scale, height: 44 * scale)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 119 / 255, green: 5 / 255, blue: 35 / 255),
                                Color(red: 238 / 255, green: 156 / 255, blue: 167 / 255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
            .position(x: 341.5 * scale, y: 30 * scale)
            .accessibilityLabel("Start Demo")

            Text(store.selectedFeature.coverTitle)
                .font(.custom(Font.exposureMinus10Name, size: 32 * scale, relativeTo: .largeTitle))
                .foregroundStyle(Color.brandInk)
                .lineSpacing(0)
                .lineLimit(2)
                .frame(width: 380 * scale, height: 76 * scale, alignment: .topLeading)
                .position(x: 210 * scale, y: 120 * scale)
                .allowsHitTesting(false)
        }
        .frame(width: frame.width, height: 168 * scale)
        .position(x: frame.midX, y: frame.minY + 138 * scale)
    }

    @ViewBuilder
    private func coverMotion(in size: CGSize) -> some View {
        let featureVideoURL = Bundle.main.url(
            forResource: store.selectedFeature.motionResourceName,
            withExtension: "mp4"
        )
        let fallbackVideoURL = Bundle.main.url(forResource: "BrandLoop", withExtension: "mp4")

        if let videoURL = featureVideoURL ?? fallbackVideoURL {
            let frame = fittedDesignFrame(in: size)
            let scale = frame.width / 420

            LoopingVideoView(
                url: videoURL,
                duration: featureVideoURL == nil ? 4.8 : nil
            )
            .id(videoURL)
            .frame(width: frame.width, height: 572 * scale)
            .clipped()
            .position(x: frame.midX, y: frame.minY + 508 * scale)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func coverNavigationBackdrop(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 420

        return LinearGradient(
            colors: [
                Color(red: 1, green: 247 / 255, blue: 250 / 255),
                Color(red: 1, green: 241 / 255, blue: 243 / 255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: frame.width, height: 84 * scale)
        .position(x: frame.midX, y: frame.minY + 836 * scale)
        .allowsHitTesting(false)
    }

    private func coverNavigation(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 420

        return ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8 * scale) {
                    ForEach(ShowcaseFeature.allCases) { feature in
                        Button {
                            store.selectCoverFeature(feature)
                        } label: {
                            Text(feature.tabTitle)
                                .font(.custom(
                                    feature == store.selectedFeature
                                        ? Font.aeonikMediumName
                                        : Font.aeonikRegularName,
                                    size: 14 * scale,
                                    relativeTo: .subheadline
                                ))
                                .tracking(0.28 * scale)
                                .foregroundStyle(
                                    feature == store.selectedFeature
                                        ? Color.white
                                        : Color(red: 228 / 255, green: 226 / 255, blue: 227 / 255)
                                )
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .frame(width: 126 * scale, height: 68 * scale)
                                .background(
                                    feature == store.selectedFeature
                                        ? Color(red: 238 / 255, green: 156 / 255, blue: 167 / 255).opacity(0.24)
                                        : Color.white.opacity(0.05),
                                    in: Capsule()
                                )
                                .overlay {
                                    if feature == store.selectedFeature {
                                        Capsule()
                                            .stroke(Color.white.opacity(0.42), lineWidth: 1)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .id(feature)
                        .accessibilityLabel(feature.tabTitle)
                        .accessibilityAddTraits(
                            feature == store.selectedFeature ? .isSelected : []
                        )
                    }
                }
                .padding(8 * scale)
            }
            .scrollIndicators(.hidden)
            .frame(width: 390 * scale, height: 84 * scale)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 119 / 255, green: 5 / 255, blue: 35 / 255),
                        Color(red: 238 / 255, green: 156 / 255, blue: 167 / 255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .onAppear {
                scrollToSelectedFeature(using: scrollProxy, animated: false)
            }
            .onChange(of: store.selectedFeature) { _, _ in
                scrollToSelectedFeature(using: scrollProxy, animated: true)
            }
        }
        .position(x: frame.midX, y: frame.minY + 836 * scale)
    }

    private func scrollToSelectedFeature(
        using proxy: ScrollViewProxy,
        animated: Bool
    ) {
        let action = {
            proxy.scrollTo(store.selectedFeature, anchor: store.selectedFeature.coverTabAnchor)
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.24), action)
        } else {
            action()
        }
    }

    private func fittedDesignFrame(in size: CGSize) -> CGRect {
        let designAspect: CGFloat = 420 / 912
        let availableAspect = size.width / size.height

        if availableAspect > designAspect {
            let width = size.height * designAspect
            return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        }

        let height = size.width / designAspect
        return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
    }
}

private extension ShowcaseFeature {
    var coverTabAnchor: UnitPoint {
        switch self {
        case .deviceAssistant:
            .leading
        case .community:
            .trailing
        default:
            .center
        }
    }
}
