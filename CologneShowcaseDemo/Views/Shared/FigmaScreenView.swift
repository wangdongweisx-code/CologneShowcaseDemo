import SwiftUI
import UIKit

/// Displays the exact 3× PNG exported from the approved Figma frame.
/// SwiftUI supplies only scaling and interaction; the visual layer is not redrawn.
struct FigmaScreenView: View {
    let assetName: String

    var body: some View {
        GeometryReader { proxy in
            if let image = FigmaScreenImageLoader.image(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                Color.brandCanvas
                    .overlay {
                        Text("Missing Figma frame: \(assetName)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .background(Color.brandCanvas)
        .ignoresSafeArea()
        .accessibilityLabel("Figma screen \(assetName)")
    }

}

enum FigmaScreenImageLoader {
    static func image(named name: String) -> UIImage? {
        let urls = [
            Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "FigmaScreens"),
            Bundle.main.url(forResource: name, withExtension: "png"),
            Bundle.main.url(forResource: name, withExtension: "jpeg", subdirectory: "FigmaScreens"),
            Bundle.main.url(forResource: name, withExtension: "jpeg"),
            Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "FigmaScreens"),
            Bundle.main.url(forResource: name, withExtension: "jpg")
        ]

        for case let url? in urls {
            if let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return nil
    }
}

/// Reuses a small visual directly from an approved Figma frame. The crop is
/// expressed in the original 402×874 design coordinate space.
struct FigmaAssetCropView: View {
    let assetName: String
    let cropRect: CGRect

    var body: some View {
        if let image = croppedImage {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
        } else {
            Color.clear
        }
    }

    private var croppedImage: UIImage? {
        guard
            let source = FigmaScreenImageLoader.image(named: assetName),
            let cgImage = source.cgImage
        else { return nil }

        let scaleX = CGFloat(cgImage.width) / 402
        let scaleY = CGFloat(cgImage.height) / 874
        let pixelRect = CGRect(
            x: cropRect.minX * scaleX,
            y: cropRect.minY * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        ).integral

        guard let cropped = cgImage.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cropped, scale: source.scale, orientation: source.imageOrientation)
    }
}

/// Displays an isolated Figma illustration with a transparent background.
/// This keeps the IP aligned without importing a rectangular screen crop.
struct FigmaTransparentAssetView: View {
    let assetName: String

    var body: some View {
        if let image = FigmaScreenImageLoader.image(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Color.clear
        }
    }
}

extension ShowcaseFeature {
    var figmaCoverAsset: String {
        switch self {
        case .deviceAssistant: "cover-device"
        case .voiceLog: "cover-voice"
        case .lactationPlan: "cover-plan"
        case .lactationTimeline: "cover-timeline"
        case .community: "cover-community-hd"
        }
    }

    var figmaFlowAssets: [String] {
        switch self {
        case .deviceAssistant:
            [
                "device-pair", "device-welcome", "device-guide-1", "device-guide-2",
                "device-video-phase1", "device-video-phase1-collapsed",
                "device-video-phase2", "device-video-latest", "device-chat"
            ]
        case .voiceLog:
            ["voice-home", "voice-log-1", "voice-log-2", "voice-log-3", "voice-log-4", "voice-logged", "voice-home-final"]
        case .lactationPlan:
            [
                "plan-home-scroll", "plan-start", "plan-info", "plan-feed-choice",
                "plan-feed-count", "plan-night-choice", "plan-time-preference",
                "plan-time-picker", "plan-time-multiple", "plan-confirm",
                "plan-generating-v2", "plan-first", "plan-notification",
                "plan-schedule", "plan-data-scroll", "plan-share"
            ]
        case .lactationTimeline:
            [
                "timeline-home", "timeline-entry", "timeline-insights",
                "timeline-privacy-1", "timeline-q1-scroll", "timeline-q2-scroll",
                "timeline-privacy-2", "timeline-personalized", "timeline-personalized-long",
                "timeline-knowledge", "timeline-share",
                "timeline-community-share", "timeline-notification"
            ]
        case .community:
            ["community-home-2", "community-status-2", "community-reaction", "community-group-full"]
        }
    }
}
