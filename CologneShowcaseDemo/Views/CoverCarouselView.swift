import SwiftUI

struct CoverCarouselView: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                FigmaScreenView(assetName: store.selectedFeature.figmaCoverAsset)
                    .id(store.selectedFeature)

                correctedCoverHeading(in: proxy.size)

                coverMotion(in: proxy.size)

                Button {
                    store.showHighlights()
                } label: {
                    Color.clear
                }
                .frame(width: proxy.size.width * 0.22, height: proxy.size.height * 0.12)
                .position(x: proxy.size.width * 0.12, y: proxy.size.height * 0.10)
                .accessibilityLabel("Back to selling points")

                Button {
                    store.startDemo(store.selectedFeature)
                } label: {
                    Color.clear
                }
                .frame(width: proxy.size.width * 0.42, height: proxy.size.height * 0.12)
                .position(x: proxy.size.width * 0.78, y: proxy.size.height * 0.10)
                .accessibilityLabel("Start Demo")

                coverStepTabs(in: proxy.size)
            }
            .contentShape(.rect)
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -40 {
                            store.selectCoverFeature(store.selectedFeature.next)
                        } else if value.translation.width > 40 {
                            store.selectCoverFeature(store.selectedFeature.previous)
                        }
                    }
            )
            .onLongPressGesture(minimumDuration: 0.8) {
                store.isDisclaimerPresented = true
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func correctedCoverHeading(in size: CGSize) -> some View {
        if store.selectedFeature == .voiceLog || store.selectedFeature == .lactationPlan {
            let frame = fittedDesignFrame(in: size)
            let scale = frame.width / 402

            ZStack(alignment: .topLeading) {
                Color(red: 1, green: 0.976, blue: 0.980)

                Text(store.selectedFeature.coverTitle)
                    .font(.custom(
                        Font.exposureMinus10Name,
                        size: 34 * scale,
                        relativeTo: .largeTitle
                    ))
                    .foregroundStyle(Color.brandInk)
                    .tracking(0.25 * scale)
                    .lineSpacing(-3 * scale)
                    .frame(width: 354 * scale, alignment: .leading)
                    .padding(.leading, 24 * scale)
                    .padding(.top, 16 * scale)
            }
            .frame(width: frame.width, height: 110 * scale)
            .position(
                x: frame.midX,
                y: frame.minY + 167 * scale
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
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
            // Figma node 2068:14801 is the approved Motion container:
            // full cover width, y=222, height=572 in the 422×912 page.
            let motionHeight = frame.height * (572 / 912)
            let motionCenterY = frame.minY + frame.height * ((222 + 286) / 912)

            LoopingVideoView(
                url: videoURL,
                duration: featureVideoURL == nil ? 4.8 : nil
            )
                .id(videoURL)
                .frame(width: frame.width, height: motionHeight)
                .clipped()
                .position(x: frame.midX, y: motionCenterY)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func coverStepTabs(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402

        return ZStack {
            Color(red: 1, green: 0.976, blue: 0.980)

            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 8 * scale) {
                        ForEach(ShowcaseFeature.allCases) { feature in
                            Button {
                                store.selectCoverFeature(feature)
                            } label: {
                                Text(String(format: "%02d. %@", feature.ordinal, feature.tabTitle))
                                    .font(.system(
                                        size: 16 * scale,
                                        weight: feature == store.selectedFeature ? .medium : .regular
                                    ))
                                    .foregroundStyle(
                                        feature == store.selectedFeature
                                            ? Color.brandPlum
                                            : Color(red: 0.424, green: 0.400, blue: 0.412)
                                    )
                                    .lineLimit(1)
                                    .padding(.horizontal, 16 * scale)
                                    .frame(height: 44 * scale)
                                    .background(
                                        feature == store.selectedFeature
                                            ? Color(red: 1, green: 0.867, blue: 0.882)
                                            : Color.white,
                                        in: Capsule()
                                    )
                                    .shadow(
                                        color: .black.opacity(0.06),
                                        radius: 12 * scale,
                                        y: 4 * scale
                                    )
                            }
                            .buttonStyle(.plain)
                            .id(feature)
                            .accessibilityLabel(feature.tabTitle)
                        }
                    }
                    .padding(.horizontal, 20 * scale)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    scrollProxy.scrollTo(store.selectedFeature, anchor: .center)
                }
                .onChange(of: store.selectedFeature) { _, selected in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollProxy.scrollTo(selected, anchor: .center)
                    }
                }
            }
        }
        .frame(width: frame.width, height: 96 * scale)
        .position(
            x: frame.midX,
            y: frame.minY + 796 * scale
        )
    }

    private func fittedDesignFrame(in size: CGSize) -> CGRect {
        let designAspect: CGFloat = 402 / 872
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
    var previous: ShowcaseFeature {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index - 1 + all.count) % all.count]
    }

}
