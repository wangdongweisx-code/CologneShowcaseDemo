import AVFoundation
import SwiftUI
import UIKit

struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    let startTime: TimeInterval
    let duration: TimeInterval?

    init(url: URL, startTime: TimeInterval = 0, duration: TimeInterval? = nil) {
        self.url = url
        self.startTime = startTime
        self.duration = duration
    }

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        LoopingPlayerUIView(url: url, startTime: startTime, duration: duration)
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.player.play()
    }

    static func dismantleUIView(_ uiView: LoopingPlayerUIView, coordinator: ()) {
        uiView.player.pause()
    }
}

final class LoopingPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?

    init(url: URL, startTime: TimeInterval = 0, duration: TimeInterval? = nil) {
        super.init(frame: .zero)
        backgroundColor = .clear
        player.isMuted = true
        player.actionAtItemEnd = .none
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        let item = AVPlayerItem(url: url)
        if let duration {
            let range = CMTimeRange(
                start: CMTime(seconds: startTime, preferredTimescale: 600),
                duration: CMTime(seconds: duration, preferredTimescale: 600)
            )
            looper = AVPlayerLooper(player: player, templateItem: item, timeRange: range)
        } else {
            looper = AVPlayerLooper(player: player, templateItem: item)
        }
        player.play()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Plays the real Air 1 setup movie inside the video rectangle exported from
/// Figma. Playback is controlled by the surrounding SwiftUI hotspot.
struct InlineVideoPlayerView: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool
    var startTime: TimeInterval = 0

    func makeUIView(context: Context) -> InlinePlayerUIView {
        InlinePlayerUIView(url: url, startTime: startTime)
    }

    func updateUIView(_ uiView: InlinePlayerUIView, context: Context) {
        if isPlaying {
            uiView.player.play()
        } else {
            uiView.player.pause()
        }
    }

    static func dismantleUIView(_ uiView: InlinePlayerUIView, coordinator: ()) {
        uiView.player.pause()
    }
}

final class InlinePlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    let player: AVPlayer

    init(url: URL, startTime: TimeInterval = 0) {
        player = AVPlayer(url: url)
        super.init(frame: .zero)
        backgroundColor = .black
        player.actionAtItemEnd = .pause
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        if startTime > 0 {
            player.seek(
                to: CMTime(seconds: startTime, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
