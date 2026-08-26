import SwiftUI
import UIKit

/// Native rebuild of the approved `device-chat` frame.
///
/// The screen keeps the 402×874 design metrics but composes them vertically, so
/// the real keyboard shortens the page instead of translating it. The rasterised
/// frame is only still used for the IP illustration, which cannot be redrawn.
struct DeviceAgentChatView: View {
    @ObservedObject var store: DemoStore
    let messages: [DeviceAgentMessage]
    let isResponding: Bool
    @Binding var draft: String
    var focus: FocusState<Bool>.Binding
    let onSend: (String?) -> Void
    let onBack: () -> Void

    @State private var keyboardInset: CGFloat = 0

    private static let suggestedPrompts = [
        "How do I know the flange fits?",
        "What if the suction feels weak?",
        "Connection issues."
    ]

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 402
            let metrics = Metrics(isCompact: keyboardInset > 0)
            let available = (proxy.size.height - keyboardInset) / scale
            let scrollHeight = metrics.scrollHeight(in: available, hasConversation: !messages.isEmpty)

            ZStack(alignment: .top) {
                DeviceAgentBackdrop()

                // The flow hides the live status bar, so the approved frame's
                // own one is reused here to stay in step with the raster screens.
                HStack(spacing: 0) {
                    FigmaTransparentAssetView(assetName: "device-agent-statusbar")
                        .frame(width: 324 * scale, height: 28 * scale)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 50 * scale)
                .padding(.top, 20 * scale)

                VStack(spacing: 0) {
                    navigationBar(scale: scale)
                        .frame(height: Metrics.navigationHeight * scale)

                    scrollArea(height: scrollHeight * scale, metrics: metrics, scale: scale)

                    Spacer(minLength: 0)

                    composer(scale: scale)
                        .padding(.top, metrics.composerTopGap * scale)

                    if metrics.showsDisclaimer {
                        Text("AI-generated, not professional advice")
                            .font(.brandBody(12 * scale, relativeTo: .caption))
                            .foregroundStyle(Color.agentDisclaimer)
                            .padding(.top, 14 * scale)
                    }
                }
                .padding(.top, Metrics.navigationTop * scale)
                .padding(.bottom, metrics.bottomInset * scale)
                .frame(height: proxy.size.height - keyboardInset, alignment: .top)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            apply(keyboardInset: keyboardHeight(from: note), from: note)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { note in
            apply(keyboardInset: 0, from: note)
        }
    }

    // MARK: - Navigation bar

    private func navigationBar(scale: CGFloat) -> some View {
        ZStack {
            HStack(spacing: 7 * scale) {
                Text("CozyAI Device")
                    .font(.brandSemiBold(16 * scale, relativeTo: .headline))
                    .foregroundStyle(Color.brandInk)

                Text("Beta")
                    .font(.brandMedium(12 * scale, relativeTo: .caption))
                    .foregroundStyle(Color.agentBadge)
                    .padding(.horizontal, 10 * scale)
                    .frame(height: 24 * scale)
                    .overlay {
                        Capsule().stroke(Color.agentBadge, lineWidth: 1)
                    }
            }

            HStack {
                Button {
                    store.userDidInteract()
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19 * scale, weight: .regular))
                        .foregroundStyle(Color.brandInk)
                        .frame(width: 44 * scale, height: 44 * scale)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.5))
                                .overlay { Circle().stroke(Color.white.opacity(0.85), lineWidth: 1) }
                                .shadow(color: Color.brandPlum.opacity(0.06), radius: 8 * scale, y: 2 * scale)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous screen")

                Spacer(minLength: 0)
            }
            .padding(.leading, 16 * scale)
        }
    }

    // MARK: - Hero, suggestions and conversation

    private func scrollArea(height: CGFloat, metrics: Metrics, scale: CGFloat) -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                Group {
                    if messages.isEmpty {
                        hero(metrics: metrics, availableHeight: height / scale, scale: scale)
                    } else {
                        conversation(scale: scale)
                    }
                }
                .frame(minHeight: height, alignment: .bottom)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: height)
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    scrollProxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: isResponding) { _, responding in
                guard responding else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    scrollProxy.scrollTo("agent-progress", anchor: .bottom)
                }
            }
        }
    }

    private func hero(metrics: Metrics, availableHeight: CGFloat, scale: CGFloat) -> some View {
        let mascotHeight = metrics.mascotHeight(in: availableHeight)

        return VStack(spacing: 0) {
            Spacer().frame(height: metrics.heroTopGap * scale)

            FigmaTransparentAssetView(assetName: "device-agent-mascot")
                .frame(width: mascotHeight * 190 / 146 * scale, height: mascotHeight * scale)

            Spacer().frame(height: metrics.mascotTextGap * scale)

            headline(size: metrics.headlineSize, scale: scale)
                .padding(.horizontal, 22 * scale)

            Spacer(minLength: Metrics.heroBottomGap * scale)

            VStack(alignment: .leading, spacing: 12 * scale) {
                ForEach(Self.suggestedPrompts, id: \.self) { prompt in
                    suggestionChip(prompt, scale: scale)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16 * scale)
        }
        .animation(.easeInOut(duration: 0.22), value: metrics.isCompact)
    }

    private func headline(size: CGFloat, scale: CGFloat) -> some View {
        let display = Font.custom(Font.exposureMinus10Name, size: size * scale, relativeTo: .title)

        return (
            Text("How can I help with your Momcozy ")
                + Text("Air 1").foregroundColor(Color.brandPlum)
                + Text(" ?")
        )
        .font(display)
        .foregroundStyle(Color.brandInk)
        .lineSpacing(4 * scale)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func suggestionChip(_ prompt: String, scale: CGFloat) -> some View {
        Button {
            onSend(prompt)
        } label: {
            Text(prompt)
                .font(.brandBody(16 * scale, relativeTo: .body))
                .foregroundStyle(Color.brandInk)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 17 * scale)
                .padding(.vertical, 13.5 * scale)
                .background(Color.agentSurface, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(prompt)
    }

    private func conversation(scale: CGFloat) -> some View {
        LazyVStack(spacing: 10 * scale) {
            ForEach(messages) { message in
                bubble(message, scale: scale).id(message.id)
            }

            if isResponding {
                HStack(spacing: 8 * scale) {
                    ProgressView().tint(Color.brandPlum)
                    Text("Cozie AI is searching…")
                        .font(.brandBody(13 * scale, relativeTo: .footnote))
                        .foregroundStyle(Color.brandPlum.opacity(0.7))
                    Spacer(minLength: 0)
                }
                .padding(12 * scale)
                .background(Color.agentSurface, in: .rect(cornerRadius: 18 * scale, style: .continuous))
                .id("agent-progress")
            }
        }
        .padding(.horizontal, 16 * scale)
        .padding(.vertical, 12 * scale)
    }

    private func bubble(_ message: DeviceAgentMessage, scale: CGFloat) -> some View {
        let isUser = message.role == .user

        return VStack(alignment: isUser ? .trailing : .leading, spacing: 7 * scale) {
            Text(message.text)
                .font(.brandBody(15 * scale, relativeTo: .body))
                .foregroundStyle(isUser ? Color.white : Color.brandInk)
                .padding(.horizontal, 14 * scale)
                .padding(.vertical, 11 * scale)
                .background(
                    isUser ? Color.brandPlum : Color.agentSurface,
                    in: .rect(cornerRadius: 18 * scale, style: .continuous)
                )

            if !message.sources.isEmpty {
                VStack(alignment: .leading, spacing: 4 * scale) {
                    Text("Sources")
                        .font(.brandSemiBold(10 * scale, relativeTo: .caption2))
                        .foregroundStyle(Color.brandPlum.opacity(0.62))

                    ForEach(message.sources.prefix(3)) { source in
                        sourceLabel(source, scale: scale)
                    }
                }
                .padding(.horizontal, 6 * scale)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    @ViewBuilder
    private func sourceLabel(_ source: DeviceAgentSource, scale: CGFloat) -> some View {
        if source.url.scheme == "momcozy" {
            Label(source.title, systemImage: "doc.text")
                .font(.brandBody(10 * scale, relativeTo: .caption2))
                .foregroundStyle(Color.brandPlum)
                .lineLimit(1)
                .accessibilityLabel("Knowledge source: \(source.title)")
        } else {
            Link(destination: source.url) {
                Label(source.title, systemImage: "link")
                    .font(.brandBody(10 * scale, relativeTo: .caption2))
                    .foregroundStyle(Color.brandPlum)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Composer

    private func composer(scale: CGFloat) -> some View {
        HStack(spacing: 13 * scale) {
            Image(systemName: "plus")
                .font(.system(size: 20 * scale, weight: .light))
                .foregroundStyle(Color.brandInk)

            TextField(
                "",
                text: $draft,
                prompt: Text("Ask about your Momcozy Air 1")
                    .font(.brandBody(16 * scale, relativeTo: .body))
                    .foregroundColor(Color.agentPlaceholder),
                axis: .vertical
            )
            .font(.brandBody(16 * scale, relativeTo: .body))
            .foregroundStyle(Color.brandInk)
            .tint(Color.brandPlum)
            .lineLimit(1...3)
            .focused(focus)
            .submitLabel(.send)
            .onSubmit { onSend(nil) }

            if isResponding {
                ProgressView()
                    .tint(Color.brandPlum)
                    .frame(width: 32 * scale, height: 32 * scale)
            } else if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    onSend(nil)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15 * scale, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 32 * scale, height: 32 * scale)
                        .background(Color.brandPlum, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send question")
            }
        }
        .padding(.horizontal, 22 * scale)
        .frame(minHeight: Metrics.composerHeight * scale)
        .background(Color.agentComposerFill, in: .capsule)
        .shadow(color: Color.brandPlum.opacity(0.07), radius: 14 * scale, y: 4 * scale)
        .contentShape(.capsule)
        .onTapGesture { focus.wrappedValue = true }
        .padding(.horizontal, 16 * scale)
    }

    // MARK: - Keyboard

    private func keyboardHeight(from note: Notification) -> CGFloat {
        guard let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return 0 }
        return end.height
    }

    private func apply(keyboardInset inset: CGFloat, from note: Notification) {
        let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        withAnimation(.easeOut(duration: max(duration, 0.2))) {
            keyboardInset = inset
        }
    }
}

// MARK: - Design metrics

/// All values are expressed in the 402×874 design space. The compact variant is
/// used while the keyboard is up: the IP shrinks and the disclaimer is dropped
/// so the header, the headline and every suggestion stay reachable.
private struct Metrics {
    static let navigationTop: CGFloat = 69
    static let navigationHeight: CGFloat = 48
    static let composerHeight: CGFloat = 56
    static let heroBottomGap: CGFloat = 16
    /// Three single-line capsules plus their gaps, with a little slack.
    static let suggestionsHeight: CGFloat = 168
    static let mascotHeight: CGFloat = 146

    let isCompact: Bool

    var heroTopGap: CGFloat { isCompact ? 16 : 48 }
    var mascotTextGap: CGFloat { isCompact ? 10 : 12 }
    var headlineSize: CGFloat { isCompact ? 23 : 28 }
    var composerTopGap: CGFloat { isCompact ? 16 : 33 }
    var bottomInset: CGFloat { isCompact ? 10 : 18 }
    var showsDisclaimer: Bool { !isCompact }

    private var disclaimerHeight: CGFloat { showsDisclaimer ? 29 : 0 }

    /// The IP absorbs whatever the keyboard takes, so every suggestion stays
    /// fully visible instead of being clipped at the bottom of the scroll area.
    func mascotHeight(in availableHeight: CGFloat) -> CGFloat {
        let headlineBlock = headlineSize * 2.4 + 4
        let budget = availableHeight
            - Self.suggestionsHeight
            - Self.heroBottomGap
            - heroTopGap
            - mascotTextGap
            - headlineBlock
        return min(Self.mascotHeight, max(0, budget))
    }

    /// Height left for the hero (or the conversation) once the pinned header and
    /// composer have taken their share.
    func scrollHeight(in available: CGFloat, hasConversation: Bool) -> CGFloat {
        let reserved = Self.navigationTop
            + Self.navigationHeight
            + (hasConversation ? 12 : composerTopGap)
            + Self.composerHeight
            + disclaimerHeight
            + bottomInset
        return max(available - reserved, 120)
    }
}

// MARK: - Backdrop

/// The frame's backdrop is a vertical wash with a warmer glow behind the header.
private struct DeviceAgentBackdrop: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 1.000, green: 0.886, blue: 0.902), location: 0.00),
                .init(color: Color(red: 1.000, green: 0.902, blue: 0.914), location: 0.05),
                .init(color: Color(red: 0.988, green: 0.929, blue: 0.933), location: 0.14),
                .init(color: Color(red: 0.996, green: 0.953, blue: 0.953), location: 0.24),
                .init(color: Color(red: 0.996, green: 0.961, blue: 0.961), location: 0.33),
                .init(color: Color(red: 0.996, green: 0.961, blue: 0.961), location: 0.62),
                .init(color: Color(red: 0.988, green: 0.945, blue: 0.945), location: 0.76),
                .init(color: Color(red: 0.988, green: 0.929, blue: 0.929), location: 0.90),
                .init(color: Color(red: 0.984, green: 0.918, blue: 0.918), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            GeometryReader { proxy in
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.796, blue: 0.847).opacity(0.5),
                        Color(red: 1.0, green: 0.796, blue: 0.847).opacity(0)
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: proxy.size.width * 0.52
                )
            }
        }
        .ignoresSafeArea()
    }
}

private extension Color {
    /// Chips and assistant bubbles: white with the faintest warm cast.
    static let agentSurface = Color(red: 1.000, green: 0.996, blue: 0.996)
    static let agentComposerFill = Color(red: 0.996, green: 0.988, blue: 0.988)
    static let agentPlaceholder = Color(red: 0.62, green: 0.58, blue: 0.60)
    static let agentDisclaimer = Color(red: 0.72, green: 0.65, blue: 0.66)
    static let agentBadge = Color(red: 0.78, green: 0.06, blue: 0.22)
}
