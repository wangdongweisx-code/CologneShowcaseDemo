import SwiftUI

struct StandbyView: View {
    @ObservedObject var store: DemoStore

    private var videoURL: URL? {
        Bundle.main.url(forResource: "BrandLoop", withExtension: "mp4")
    }

    var body: some View {
        Button {
            store.showHighlights()
        } label: {
            Group {
                if let videoURL {
                    LoopingVideoView(url: videoURL)
                        .ignoresSafeArea()
                } else {
                    FigmaScreenView(assetName: "cover-device")
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Momcozy selling points")
    }
}
