import Foundation
import SwiftUI

struct FeatureDemoView: View {
    let feature: ShowcaseFeature
    @ObservedObject var store: DemoStore
    @State private var stepIndex = 0
    @State private var exitPresentation: ExitPresentation = .hidden
    @State private var hasPresentedExit = false
    @State private var exitTask: Task<Void, Never>?
    @State private var isSetupVideoPlaying = false
    @State private var isDeviceHowToExpanded = true
    @State private var isDeviceWarningExpanded = true
    @State private var deviceTipPageIndex = 0
    @State private var deviceSetupStepIndex = 0
    @State private var deviceAgentReturnStepIndex: Int?
    @State private var agentDraft = ""
    @State private var agentMessages: [DeviceAgentMessage] = []
    @State private var isAgentResponding = false
    @State private var voiceRecordingSeconds = 1
    @State private var isVoiceRecording = false
    @State private var isVoiceRecordingReady = false
    @State private var voiceRecordingTask: Task<Void, Never>?
    @State private var agentConnectionStatus: DeviceAgentConnectionStatus = AIAgentClient.isConfigured
        ? .configured
        : .local
    @FocusState private var isAgentInputFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if feature == .lactationPlan {
                    LactationPlanDemoView(store: store)
                } else if feature == .lactationTimeline {
                    TimelineDemoView(store: store)
                } else if isCommunityIntroStep {
                    CommunityIntroDemoView(
                        store: store,
                        step: stepIndex,
                        onNext: advance,
                        onBack: goBack
                    )
                    .id(stepIndex)
                } else if isCommunityGroupStep {
                    CommunityExactFinalDemoView(store: store, onBack: goBack)
                } else if isDeviceVideoStep {
                    deviceVideoStep(in: proxy.size)
                } else if currentStep.scrollsVertically {
                    scrollableStep(in: proxy.size)
                } else {
                    if isDeviceAgentStep {
                        deviceAgentBackground(in: proxy.size)
                    } else {
                        FigmaScreenView(assetName: visibleScreenAssetName)
                            .id(visibleScreenAssetName)
                    }

                    if isDeviceAgentStep {
                        deviceAgentChat(in: proxy.size)
                    }

                    ForEach(Array(currentStep.targets.enumerated()), id: \.offset) { _, target in
                        hotspot(target, in: proxy.size)
                    }

                    if isVoiceRecordingStep {
                        voiceRecordingInteraction(in: proxy.size)
                    }
                }

                if isDeviceAgentStep {
                    deviceAgentBackControl(in: proxy.size)
                } else if feature != .lactationPlan
                    && !isCommunityIntroStep
                    && currentStep.hasBackButton
                    && !currentStep.scrollsVertically {
                    hotspot(
                        DemoTarget(
                            rect: CGRect(x: 0.02, y: 0.055, width: 0.20, height: 0.12),
                            label: "Previous screen",
                            action: .back
                        ),
                        in: proxy.size
                    )
                }

                if exitPresentation != .hidden && !isAgentInputFocused {
                    exitButton(in: proxy.size)
                }
            }
        }
        // Keep the keyboard safe area active so the live Agent composer
        // follows the real iOS keyboard instead of remaining underneath it.
        .ignoresSafeArea(.container, edges: .all)
        .onAppear {
            configureExitButton()
        }
        .onChange(of: stepIndex) { _, _ in
            if !isDeviceVideoStep {
                isSetupVideoPlaying = false
            }
            isDeviceHowToExpanded = currentStep.assetName == "device-video-phase1"
            isDeviceWarningExpanded = true
            deviceTipPageIndex = 0
            if currentStep.assetName == "device-video-phase1" {
                deviceSetupStepIndex = 0
            } else if currentStep.assetName == "device-video-phase2" {
                deviceSetupStepIndex = 2
            }
            if isVoiceRecordingStep {
                startVoiceRecording()
            } else {
                resetVoiceRecording()
            }
            configureExitButton()
        }
        .task(id: stepIndex) {
            guard let delay = currentStep.automaticAdvanceDelay else { return }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            advance()
        }
        .onDisappear {
            exitTask?.cancel()
            voiceRecordingTask?.cancel()
        }
    }

    private var currentStep: DemoStep {
        let steps = feature.demoSteps
        return steps[min(stepIndex, steps.count - 1)]
    }

    private var isDeviceVideoStep: Bool {
        feature == .deviceAssistant && currentStep.assetName.hasPrefix("device-video-phase")
    }

    private var isDeviceAgentStep: Bool {
        feature == .deviceAssistant && currentStep.assetName == "device-chat"
    }

    private var isVoiceRecordingStep: Bool {
        feature == .voiceLog && currentStep.assetName == "voice-log-2"
    }

    private var isCommunityGroupStep: Bool {
        feature == .community && currentStep.assetName == "community-group-full"
    }

    private var isCommunityIntroStep: Bool {
        feature == .community && stepIndex < 3
    }

    private var visibleScreenAssetName: String {
        return currentStep.assetName
    }

    private func advance() {
        let steps = feature.demoSteps
        if stepIndex < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.18)) {
                stepIndex += 1
            }
        }
    }

    private func goBack() {
        // Dismiss the real iOS keyboard before changing screens. Without this,
        // the keyboard-sized GeometryReader can leave the old transparent hit
        // area active and make the visible back button appear unresponsive.
        isAgentInputFocused = false

        if isDeviceAgentStep, let returnStepIndex = deviceAgentReturnStepIndex {
            deviceAgentReturnStepIndex = nil
            withAnimation(.easeInOut(duration: 0.18)) {
                stepIndex = returnStepIndex
            }
            return
        }

        if stepIndex > 0 {
            withAnimation(.easeInOut(duration: 0.18)) {
                stepIndex -= 1
            }
        } else {
            store.showCover(feature)
        }
    }

    @ViewBuilder
    private func voiceRecordingInteraction(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402

        // Replace the original Figma label in-place. The background patch is
        // cropped from an empty area of this same approved frame, so the old
        // static "5s" is removed without adding a second label or a visible box.
        FigmaAssetCropView(
            assetName: "voice-log-2",
            cropRect: CGRect(x: 16, y: 637, width: 130, height: 36)
        )
        .frame(width: 130 * scale, height: 36 * scale)
            .position(
                x: frame.minX + 201 * scale,
                y: frame.minY + 655 * scale
            )

        Text("Listening...\(voiceRecordingSeconds)s")
            .font(.custom(Font.aeonikRegularName, size: 17 * scale, relativeTo: .body))
            .foregroundStyle(Color.brandInk)
            .contentTransition(.numericText(countsDown: false))
            .animation(.easeOut(duration: 0.22), value: voiceRecordingSeconds)
            .frame(width: 130 * scale, height: 28 * scale)
            .position(
                x: frame.minX + 201 * scale,
                y: frame.minY + 655 * scale
            )

        Button {
            store.userDidInteract()
            advance()
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 126 * scale, height: 128 * scale)
        .position(
            x: frame.minX + 201 * scale,
            y: frame.minY + 783 * scale
        )
        .accessibilityLabel("Continue after recording")
        .accessibilityValue("Listening for \(voiceRecordingSeconds) seconds")
        .accessibilityHint("Tap once to continue")
    }

    private func startVoiceRecording() {
        guard !isVoiceRecording else { return }

        isVoiceRecording = true
        voiceRecordingSeconds = 1
        voiceRecordingTask?.cancel()
        voiceRecordingTask = Task { @MainActor in
            var elapsedSeconds = 1
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                elapsedSeconds += 1
                withAnimation(.easeInOut(duration: 0.12)) {
                    voiceRecordingSeconds = elapsedSeconds
                }
            }
        }
    }

    private func resetVoiceRecording() {
        voiceRecordingTask?.cancel()
        voiceRecordingTask = nil
        isVoiceRecording = false
        isVoiceRecordingReady = false
        voiceRecordingSeconds = 1
    }

    @ViewBuilder
    private func hotspot(_ target: DemoTarget, in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        hotspot(target, inDesignFrame: frame)
    }

    @ViewBuilder
    private func hotspot(_ target: DemoTarget, inDesignFrame frame: CGRect) -> some View {
        Button {
            store.userDidInteract()
            switch target.action {
            case .advance:
                advance()
            case .back:
                if feature == .voiceLog {
                    // Voice Log uses an X here: close the flow to its Cover Page.
                    store.showCover(feature)
                } else {
                    // A left chevron only moves one screen backwards.
                    goBack()
                }
            case .finish:
                store.showHighlights()
            case .cover:
                store.showCover(feature)
            case .restart:
                withAnimation(.easeInOut(duration: 0.18)) {
                    stepIndex = 0
                }
            case .unavailable:
                store.showDemoUnavailableToast()
            }
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: frame.width * target.rect.width,
            height: frame.height * target.rect.height
        )
        .position(
            x: frame.minX + frame.width * target.rect.midX,
            y: frame.minY + frame.height * target.rect.midY
        )
        .accessibilityLabel(target.label)
    }

    /// The Agent screen keeps its approved 402x874 layout while the keyboard is
    /// presented. Anchor its back hit target to that same fixed-width canvas so
    /// it never moves when the available height becomes shorter.
    private func deviceAgentBackControl(in size: CGSize) -> some View {
        let frame = fixedWidthDesignFrame(in: size)
        let scale = frame.width / 402

        return Button {
            store.userDidInteract()
            isAgentInputFocused = false
            goBack()
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 104 * scale, height: 112 * scale)
        .position(
            x: frame.minX + 52 * scale,
            y: frame.minY + 102 * scale
        )
        .zIndex(50)
        .accessibilityLabel("Previous screen")
    }

    @ViewBuilder
    private func scrollableStep(in size: CGSize) -> some View {
        let viewportDesignAspect: CGFloat = 402 / 874
        let contentWidth = min(size.width, size.height * viewportDesignAspect)
        let contentHeight = contentWidth * currentStep.designHeight / 402
        let designFrame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)

        ScrollView(.vertical) {
            ZStack {
                FigmaScreenView(assetName: currentStep.assetName)
                    .id(currentStep.assetName)

                ForEach(Array(currentStep.targets.enumerated()), id: \.offset) { _, target in
                    hotspot(target, inDesignFrame: designFrame)
                }

                if currentStep.hasBackButton {
                    hotspot(
                        DemoTarget(
                            rect: CGRect(
                                x: 0.02,
                                y: 48 / currentStep.designHeight,
                                width: 0.20,
                                height: 104 / currentStep.designHeight
                            ),
                            label: "Previous screen",
                            action: .back
                        ),
                        inDesignFrame: designFrame
                    )
                }
            }
            .frame(width: contentWidth, height: contentHeight)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.visible)
        .background(Color.brandCanvas)
    }

    @ViewBuilder
    private func deviceVideoStep(in size: CGSize) -> some View {
        interactiveDeviceSetupGuide(in: size)
    }

    @ViewBuilder
    private func interactiveDeviceSetupGuide(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size, designSize: CGSize(width: 402, height: 874))
        let scale = frame.width / 402
        let guide = DeviceSetupGuideStep.steps[deviceSetupStepIndex]

        ZStack {
            Color.brandCanvas

            VStack(spacing: 0) {
                HStack {
                    Button {
                        store.userDidInteract()
                        store.showCover(feature)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 19 * scale, weight: .regular))
                            .foregroundStyle(Color.brandInk)
                            .frame(width: 44 * scale, height: 44 * scale)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .tint(Color.white.opacity(0.82))
                    .accessibilityLabel("Close to Device Assistant cover")

                    Spacer()

                    Text("Air 1 Setup")
                        .font(.brandMedium(16 * scale, relativeTo: .headline))
                        .foregroundStyle(Color.brandInk)

                    Spacer()

                    Button {
                        store.userDidInteract()
                        openDeviceAgent()
                    } label: {
                        FigmaAssetCropView(
                            assetName: "device-video-latest",
                            cropRect: CGRect(x: 338, y: 70, width: 48, height: 48)
                        )
                        .frame(width: 44 * scale, height: 44 * scale)
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open AI Device Assistant")
                }
                .padding(.horizontal, 20 * scale)
                .padding(.top, 52 * scale)
                .padding(.bottom, 12 * scale)

                VStack(alignment: .leading, spacing: 8 * scale) {
                    Text("Step \(deviceSetupStepIndex + 1)")
                        .font(.brandBody(14 * scale, relativeTo: .subheadline))
                        .foregroundStyle(Color.brandPlum)

                    Text(guide.title)
                        .font(.custom(Font.exposureMinus10Name, size: 28 * scale, relativeTo: .title))
                        .foregroundStyle(Color.brandInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: 4 * scale) {
                        ForEach(DeviceSetupGuideStep.steps.indices, id: \.self) { index in
                            Button {
                                selectDeviceSetupStep(index)
                            } label: {
                                Capsule()
                                    .fill(index <= deviceSetupStepIndex
                                          ? Color.brandPlum
                                          : Color.brandInk.opacity(0.16))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 3 * scale)
                                    .contentShape(Rectangle().inset(by: -10 * scale))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open setup step \(index + 1)")
                        }
                    }
                    .frame(height: 24 * scale)
                }
                .padding(.horizontal, 20 * scale)
                .padding(.bottom, 10 * scale)
                .contentShape(Rectangle())
                .simultaneousGesture(deviceSetupStepSwipeGesture)

                ZStack {
                    SourceMaterialImageView(
                        assetName: guide.images[0].assetName,
                        cropUnitRect: guide.images[0].cropUnitRect
                    )
                    .frame(height: 221 * scale)
                    .clipped()
                    .overlay(Color.black.opacity(0.12))

                    if
                        isSetupVideoPlaying,
                        let url = Bundle.main.url(forResource: guide.videoResourceName, withExtension: "mp4")
                    {
                        InlineVideoPlayerView(
                            url: url,
                            isPlaying: true
                        )
                            .id(guide.videoResourceName)
                            .frame(height: 221 * scale)
                            .clipped()
                    }

                    Button {
                        store.userDidInteract()
                        isSetupVideoPlaying.toggle()
                    } label: {
                        Image(systemName: isSetupVideoPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28 * scale, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 62 * scale, height: 62 * scale)
                            .background(Color.black.opacity(0.14), in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSetupVideoPlaying ? "Pause setup video" : "Play setup video")

                    Text("How-to video · Step \(deviceSetupStepIndex + 1)")
                        .font(.brandBody(13 * scale, relativeTo: .footnote))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12 * scale)
                        .frame(height: 34 * scale)
                        .background(Color.brandInk.opacity(0.42), in: RoundedRectangle(cornerRadius: 9 * scale))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.leading, 16 * scale)
                        .padding(.bottom, 14 * scale)
                }
                .frame(height: 221 * scale)
                .contentShape(Rectangle())
                .simultaneousGesture(deviceSetupStepSwipeGesture)

                deviceSetupInformationCard(guide, scale: scale)
            }
            .frame(width: frame.width, height: frame.height, alignment: .top)
            .background(Color.brandCanvas)
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }

    @ViewBuilder
    private func deviceSetupInformationCard(
        _ guide: DeviceSetupGuideStep,
        scale: CGFloat
    ) -> some View {
        let images = guide.images
        let safeImageIndex = min(max(deviceTipPageIndex, 0), max(images.count - 1, 0))
        let imageHeight = images.isEmpty
            ? 173 * scale
            : images[safeImageIndex].displayHeight(for: 329 * scale, maximumHeight: 585 * scale)

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                Text(guide.caption)
                    .font(.brandBody(15 * scale, relativeTo: .body))
                    .foregroundStyle(Color.brandInk.opacity(0.62))
                    .padding(.bottom, 18 * scale)

                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isDeviceHowToExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10 * scale) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 23 * scale, weight: .regular))
                        Text("How to do it")
                            .font(.brandMedium(17 * scale, relativeTo: .headline))
                        Spacer()
                        Image(systemName: isDeviceHowToExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 15 * scale, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandInk)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, isDeviceHowToExpanded ? 14 * scale : 16 * scale)

                if isDeviceHowToExpanded {
                    TabView(selection: $deviceTipPageIndex) {
                        ForEach(images.indices, id: \.self) { index in
                            SourceMaterialImageView(
                                assetName: images[index].assetName,
                                cropUnitRect: images[index].cropUnitRect
                            )
                                .tag(index)
                                .accessibilityLabel("Reference image \(index + 1) of \(images.count)")
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: imageHeight)
                    .background(Color.white)
                    .animation(.easeInOut(duration: 0.18), value: imageHeight)

                    if images.count > 1 {
                        HStack(spacing: 5 * scale) {
                            Spacer()
                            ForEach(images.indices, id: \.self) { index in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        deviceTipPageIndex = index
                                    }
                                } label: {
                                    Circle()
                                        .fill(index == deviceTipPageIndex
                                              ? Color.brandPlum
                                              : Color.brandInk.opacity(0.18))
                                        .frame(width: 5 * scale, height: 5 * scale)
                                        .contentShape(Rectangle().inset(by: -7 * scale))
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 11 * scale)
                    } else {
                        Spacer().frame(height: 12 * scale)
                    }

                    Text(guide.description)
                        .font(.brandBody(15 * scale, relativeTo: .body))
                        .foregroundStyle(Color.brandInk.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 18 * scale)
                }

                Divider()

                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isDeviceWarningExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10 * scale) {
                        Image(systemName: "exclamationmark.shield")
                            .font(.system(size: 23 * scale, weight: .regular))
                        Text("What to watch out for")
                            .font(.brandMedium(17 * scale, relativeTo: .headline))
                        Spacer()
                        Image(systemName: isDeviceWarningExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 15 * scale, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandInk)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 15 * scale)

                if isDeviceWarningExpanded {
                    Text(guide.warning)
                        .font(.brandBody(15 * scale, relativeTo: .body))
                        .foregroundStyle(Color.brandInk.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 18 * scale)
                }

                if deviceSetupStepIndex == DeviceSetupGuideStep.steps.count - 1 {
                    Button {
                        store.userDidInteract()
                        openDeviceAgent()
                    } label: {
                        Text("Continue to AI Device Assistant")
                            .font(.brandSemiBold(16 * scale, relativeTo: .headline))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, minHeight: 52 * scale)
                            .background(Color.brandPlum, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20 * scale)
                }
            }
            .padding(.horizontal, 16 * scale)
            .padding(.top, 22 * scale)
        }
        .scrollIndicators(.visible)
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24 * scale, topTrailingRadius: 24 * scale))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectDeviceSetupStep(_ index: Int) {
        guard DeviceSetupGuideStep.steps.indices.contains(index) else { return }
        store.userDidInteract()
        withAnimation(.easeInOut(duration: 0.22)) {
            deviceSetupStepIndex = index
            deviceTipPageIndex = 0
            isDeviceHowToExpanded = true
            isDeviceWarningExpanded = true
            isSetupVideoPlaying = false
        }
    }

    private var deviceSetupStepSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 1.25 else { return }
                if value.translation.width < -48 {
                    selectDeviceSetupStep(min(deviceSetupStepIndex + 1, DeviceSetupGuideStep.steps.count - 1))
                } else if value.translation.width > 48 {
                    selectDeviceSetupStep(max(deviceSetupStepIndex - 1, 0))
                }
            }
    }

    @ViewBuilder
    private func expandedDeviceVideoStep(in size: CGSize) -> some View {
        let isPhaseOne = currentStep.assetName == "device-video-phase1"
        let designSize = isPhaseOne
            ? CGSize(width: 402, height: 874)
            : CGSize(width: 393, height: 852)
        let frame = fittedDesignFrame(in: size, designSize: designSize)
        let backgroundAsset = isPhaseOne ? "device-video-latest" : "device-video-phase2"

        FigmaScreenView(assetName: backgroundAsset)
            .id(backgroundAsset)

        if !isPhaseOne {
            latestDeviceVideoHeader(inDesignFrame: frame)
        }

        setupVideo(
            inDesignFrame: frame,
            designSize: designSize,
            videoRect: isPhaseOne
                ? CGRect(x: 0, y: 242, width: 402, height: 221)
                : CGRect(x: 0, y: 219, width: 393, height: 221)
        )
        deviceVideoControl(
            isPhaseOne
                ? CGRect(x: 8, y: 58, width: 72, height: 72)
                : CGRect(x: 8, y: 48, width: 72, height: 76),
            label: "Close to Device Assistant cover",
            action: .cover,
            in: frame,
            designSize: designSize
        )
        deviceAgentEntryControl(
            isPhaseOne
                ? CGRect(x: 322, y: 58, width: 80, height: 72)
                : CGRect(x: 313, y: 48, width: 80, height: 76),
            in: frame,
            designSize: designSize
        )

        deviceTipsPanel(
            in: frame,
            designSize: designSize,
            topY: isPhaseOne ? 488 : 500,
            bottomY: isPhaseOne ? designSize.height : 750
        )
    }

    @ViewBuilder
    private func standardDeviceVideoStep(in size: CGSize) -> some View {
        let designSize = CGSize(width: 393, height: 852)
        let frame = fittedDesignFrame(in: size, designSize: designSize)
        let isPhaseOne = currentStep.assetName == "device-video-phase1"
        let assetName = isPhaseOne ? "device-video-phase1-collapsed" : "device-video-phase2"

        FigmaScreenView(assetName: assetName)
            .id(assetName)

        // The current Figma toolbar uses the AI mascot on every setup step.
        // The older collapsed/step-two exports predate that toolbar revision,
        // so only the approved Figma header crop is layered over them.
        latestDeviceVideoHeader(inDesignFrame: frame)

        setupVideo(inDesignFrame: frame, designSize: designSize)
        deviceVideoControl(
            CGRect(x: 8, y: 48, width: 72, height: 76),
            label: "Close to Device Assistant cover",
            action: .cover,
            in: frame,
            designSize: designSize
        )
        deviceAgentEntryControl(
            CGRect(x: 313, y: 48, width: 80, height: 76),
            in: frame,
            designSize: designSize
        )

        if isPhaseOne {
            deviceHowToToggle(
                CGRect(x: 16, y: 500, width: 361, height: 76),
                in: frame,
                designSize: designSize
            )
            deviceVideoControl(
                CGRect(x: 8, y: 750, width: 377, height: 88),
                label: "Next setup step",
                action: .advance,
                in: frame,
                designSize: designSize
            )
        } else {
            deviceHowToToggle(
                CGRect(x: 16, y: 500, width: 361, height: 76),
                in: frame,
                designSize: designSize
            )
            deviceVideoControl(
                CGRect(x: 8, y: 750, width: 136, height: 88),
                label: "Previous setup step",
                action: .back,
                in: frame,
                designSize: designSize
            )
            deviceVideoControl(
                CGRect(x: 138, y: 750, width: 247, height: 88),
                label: "Continue to Device Assistant",
                action: .advance,
                in: frame,
                designSize: designSize
            )
        }
    }

    @ViewBuilder
    private func setupVideo(
        inDesignFrame frame: CGRect,
        designSize: CGSize,
        videoRect: CGRect = CGRect(x: 0, y: 219, width: 393, height: 221)
    ) -> some View {

        if
            isSetupVideoPlaying,
            let url = Bundle.main.url(
                forResource: "Air1SetupStep\(deviceSetupStepIndex + 1)",
                withExtension: "mp4"
            )
        {
            InlineVideoPlayerView(url: url, isPlaying: true)
                .frame(
                    width: frame.width * videoRect.width / designSize.width,
                    height: frame.height * videoRect.height / designSize.height
                )
                .clipped()
                .position(
                    x: frame.minX + frame.width * videoRect.midX / designSize.width,
                    y: frame.minY + frame.height * videoRect.midY / designSize.height
                )
        }

        Button {
            store.userDidInteract()
            isSetupVideoPlaying.toggle()
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: frame.width * videoRect.width / designSize.width,
            height: frame.height * videoRect.height / designSize.height
        )
        .position(
            x: frame.minX + frame.width * videoRect.midX / designSize.width,
            y: frame.minY + frame.height * videoRect.midY / designSize.height
        )
        .accessibilityLabel(isSetupVideoPlaying ? "Pause Air 1 setup video" : "Play Air 1 setup video")
    }

    @ViewBuilder
    private func latestDeviceVideoHeader(inDesignFrame frame: CGRect) -> some View {
        let headerHeight = frame.width * 122 / 402

        FigmaAssetCropView(
            assetName: "device-video-latest",
            cropRect: CGRect(x: 0, y: 0, width: 402, height: 122)
        )
        .frame(width: frame.width, height: headerHeight)
        .position(x: frame.midX, y: frame.minY + headerHeight / 2)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func deviceAgentEntryControl(
        _ rect: CGRect,
        in frame: CGRect,
        designSize: CGSize
    ) -> some View {
        Button {
            store.userDidInteract()
            openDeviceAgent()
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: frame.width * rect.width / designSize.width,
            height: frame.height * rect.height / designSize.height
        )
        .position(
            x: frame.minX + frame.width * rect.midX / designSize.width,
            y: frame.minY + frame.height * rect.midY / designSize.height
        )
        .accessibilityLabel("Open AI Device Assistant")
    }

    private func openDeviceAgent() {
        guard let agentIndex = feature.demoSteps.firstIndex(where: { $0.assetName == "device-chat" }) else {
            return
        }

        deviceAgentReturnStepIndex = stepIndex
        withAnimation(.easeInOut(duration: 0.18)) {
            stepIndex = agentIndex
        }
    }

    @ViewBuilder
    private func deviceVideoControl(
        _ rect: CGRect,
        label: String,
        action: DemoAction,
        in frame: CGRect,
        designSize: CGSize
    ) -> some View {
        hotspot(
            DemoTarget(
                rect: CGRect(
                    x: rect.minX / designSize.width,
                    y: rect.minY / designSize.height,
                    width: rect.width / designSize.width,
                    height: rect.height / designSize.height
                ),
                label: label,
                action: action
            ),
            inDesignFrame: frame
        )
    }

    @ViewBuilder
    private func deviceHowToToggle(
        _ rect: CGRect,
        in frame: CGRect,
        designSize: CGSize
    ) -> some View {
        Button {
            store.userDidInteract()
            withAnimation(.easeInOut(duration: 0.18)) {
                isDeviceHowToExpanded.toggle()
            }
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: frame.width * rect.width / designSize.width,
            height: frame.height * rect.height / designSize.height
        )
        .position(
            x: frame.minX + frame.width * rect.midX / designSize.width,
            y: frame.minY + frame.height * rect.midY / designSize.height
        )
        .accessibilityLabel(isDeviceHowToExpanded ? "Collapse How to do it" : "Expand How to do it")
    }

    @ViewBuilder
    private func deviceTipsPanel(
        in frame: CGRect,
        designSize: CGSize,
        topY: CGFloat,
        bottomY: CGFloat
    ) -> some View {
        let isPhaseOne = currentStep.assetName == "device-video-phase1"
        let scale = frame.width / designSize.width
        let panelWidth = (designSize.width - 32) * scale
        let panelHeight = (bottomY - topY) * scale
        let imageHeight = 173 * scale
        let pageCount = isPhaseOne ? 3 : 2

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                Text(isPhaseOne
                     ? "Confirm all accessories are included"
                     : "Remove parts in the correct order")
                    .font(.custom(Font.aeonikRegularName, size: 15 * scale, relativeTo: .body))
                    .foregroundStyle(Color.brandInk.opacity(0.62))
                    .padding(.bottom, 20 * scale)

                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isDeviceHowToExpanded = false
                    }
                } label: {
                    HStack(spacing: 10 * scale) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 24 * scale, weight: .regular))
                        Text("How to do it")
                            .font(.custom(Font.aeonikMediumName, size: 17 * scale, relativeTo: .headline))
                        Spacer()
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16 * scale, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandInk)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16 * scale)

                TabView(selection: $deviceTipPageIndex) {
                    if isPhaseOne {
                        SourceMaterialImageView(
                            assetName: "air1-tip-unbox",
                            cropUnitRect: CGRect(x: 0, y: 0, width: 1, height: 0.333)
                        )
                        .tag(0)

                        SourceMaterialImageView(
                            assetName: "air1-tip-unbox",
                            cropUnitRect: CGRect(x: 0, y: 0.333, width: 1, height: 0.333)
                        )
                        .tag(1)

                        SourceMaterialImageView(
                            assetName: "air1-tip-unbox",
                            cropUnitRect: CGRect(x: 0, y: 0.666, width: 1, height: 0.334)
                        )
                        .tag(2)
                    } else {
                        SourceMaterialImageView(assetName: "air1-tip-disassemble-a")
                            .tag(0)
                        SourceMaterialImageView(assetName: "air1-tip-disassemble-b")
                            .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: imageHeight)
                .background(Color(red: 0.975, green: 0.975, blue: 0.975))
                .clipShape(RoundedRectangle(cornerRadius: 16 * scale, style: .continuous))

                HStack(spacing: 5 * scale) {
                    Spacer()
                    ForEach(0..<pageCount, id: \.self) { page in
                        Circle()
                            .fill(page == deviceTipPageIndex
                                  ? Color.brandPlum
                                  : Color.brandInk.opacity(0.18))
                            .frame(width: 5 * scale, height: 5 * scale)
                    }
                    Spacer()
                }
                .padding(.vertical, 12 * scale)

                Text(isPhaseOne
                     ? "Parts overview: main unit, collection cups, flanges, membranes, valves, power cable, etc. Use the checklist to verify each item."
                     : "Follow the illustrated order to remove each part before cleaning.")
                    .font(.custom(Font.aeonikRegularName, size: 15 * scale, relativeTo: .body))
                    .foregroundStyle(Color.brandInk.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 18 * scale)

                Divider()

                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isDeviceWarningExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10 * scale) {
                        Image(systemName: "exclamationmark.shield")
                            .font(.system(size: 24 * scale, weight: .regular))
                        Text("What to watch out for")
                            .font(.custom(Font.aeonikMediumName, size: 17 * scale, relativeTo: .headline))
                        Spacer()
                        Image(systemName: isDeviceWarningExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 16 * scale, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandInk)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 16 * scale)

                if isDeviceWarningExpanded {
                    Text(isPhaseOne
                         ? "Missing or damaged parts? Contact customer support and have your order number and proof of purchase ready."
                         : "Remove each part gently and keep the small valve and membrane pieces together.")
                        .font(.custom(Font.aeonikRegularName, size: 15 * scale, relativeTo: .body))
                        .foregroundStyle(Color.brandInk.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 20 * scale)
                }
            }
            .padding(.horizontal, 16 * scale)
            .padding(.top, 24 * scale)
        }
        .scrollIndicators(.hidden)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
        .frame(width: panelWidth, height: panelHeight)
        .position(
            x: frame.midX,
            y: frame.minY + (topY + bottomY) * scale / 2
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isPhaseOne ? "Unbox and inspect tips" : "Disassemble parts tips")
    }

    @ViewBuilder
    private func deviceAgentChat(in size: CGSize) -> some View {
        // Preserve the design width while the available height changes with
        // the keyboard. The Figma screen is cropped, never scaled down.
        let frame = fixedWidthDesignFrame(in: size)
        let scale = frame.width / 402
        let composerHeight = 62 * scale
        let bottomSpacing = (isAgentInputFocused ? 10 : 28) * scale
        let restingComposerCenter = frame.minY + 814 * scale
        let availableComposerCenter = size.height - bottomSpacing - composerHeight / 2
        let composerCenterY = min(restingComposerCenter, availableComposerCenter)
        // Once the first question is sent, the conversation replaces the IP
        // hero area instead of leaving the rasterized mascot above the chat.
        let conversationTopDesignY: CGFloat = agentMessages.isEmpty ? 274 : 118
        let conversationTop = frame.minY + conversationTopDesignY * scale
        let conversationBottom = composerCenterY - composerHeight / 2 - 8 * scale

        if agentMessages.isEmpty && isAgentInputFocused {
            focusedAgentPrompts(
                in: frame,
                top: frame.minY + 196 * scale,
                bottom: conversationBottom
            )
        } else if agentMessages.isEmpty {
            agentPromptButton(
                "How do I know the flange fits?",
                rect: CGRect(x: 16, y: 565, width: 272, height: 62),
                in: frame
            )
            agentPromptButton(
                "What if the suction feels weak?",
                rect: CGRect(x: 16, y: 628, width: 370, height: 74),
                in: frame
            )
            agentPromptButton(
                "Connection issues.",
                rect: CGRect(x: 16, y: 704, width: 198, height: 66),
                in: frame
            )
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1, green: 0.956, blue: 0.958),
                        Color(red: 0.996, green: 0.914, blue: 0.920)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    isAgentInputFocused = false
                }

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 10 * scale) {
                            ForEach(agentMessages) { message in
                                deviceAgentBubble(message, scale: scale)
                                    .id(message.id)
                            }

                            if isAgentResponding {
                                HStack {
                                    ProgressView()
                                        .tint(Color.brandPlum)
                                    Text("Cozie AI is searching…")
                                        .font(.system(size: 13 * scale))
                                        .foregroundStyle(Color.brandPlum.opacity(0.7))
                                    Spacer()
                                }
                                .padding(12 * scale)
                                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18 * scale))
                                .id("agent-loading")
                            }
                        }
                        .padding(16 * scale)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: agentMessages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo(agentMessages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: isAgentResponding) { _, responding in
                        guard responding else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo("agent-loading", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(
                width: frame.width,
                height: max(110 * scale, conversationBottom - conversationTop)
            )
            .clipped()
            .position(
                x: frame.midX,
                y: (conversationTop + conversationBottom) / 2
            )
        }

        HStack(spacing: 10 * scale) {
            Image(systemName: "plus")
                .font(.system(size: 21 * scale, weight: .regular))
                .foregroundStyle(Color.brandPlum)

            TextField("Ask about your Momcozy Air 1", text: $agentDraft, axis: .vertical)
                .font(.system(size: 15 * scale))
                .foregroundStyle(Color.brandInk)
                .lineLimit(1...3)
                .focused($isAgentInputFocused)
                .submitLabel(.send)
                .textInputAutocapitalization(.sentences)
                .onSubmit { sendAgentMessage() }

            if isAgentResponding {
                ProgressView()
                    .tint(Color.brandPlum)
                    .frame(width: 28 * scale, height: 28 * scale)
            } else if !agentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    sendAgentMessage()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15 * scale, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32 * scale, height: 32 * scale)
                        .background(Color.brandPlum, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send question")
            }
        }
        .padding(.horizontal, 18 * scale)
        .frame(width: 370 * scale)
        .frame(minHeight: composerHeight)
        .background(Color.white.opacity(0.97), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.brandPlum.opacity(isAgentInputFocused ? 0.22 : 0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12 * scale, y: 3 * scale)
        .contentShape(Capsule())
        .onTapGesture {
            isAgentInputFocused = true
        }
        .position(x: frame.midX, y: composerCenterY)
        .animation(.easeInOut(duration: 0.24), value: isAgentInputFocused)
    }

    @ViewBuilder
    private func focusedAgentPrompts(in frame: CGRect, top: CGFloat, bottom: CGFloat) -> some View {
        let scale = frame.width / 402
        let height = max(210 * scale, bottom - top)

        VStack(alignment: .leading, spacing: 12 * scale) {
            focusedAgentPrompt("How do I know the flange fits?", scale: scale)
            focusedAgentPrompt("What if the suction feels weak?", scale: scale, fillsWidth: true)
            focusedAgentPrompt("Connection Issues.", scale: scale)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16 * scale)
        .padding(.top, 34 * scale)
        .frame(width: frame.width, height: height, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1, green: 0.956, blue: 0.958),
                    Color(red: 0.996, green: 0.914, blue: 0.920)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isAgentInputFocused = false
        }
        .clipped()
        .position(x: frame.midX, y: top + height / 2)
        .transition(.opacity)
    }

    private func focusedAgentPrompt(
        _ prompt: String,
        scale: CGFloat,
        fillsWidth: Bool = false
    ) -> some View {
        Button {
            sendAgentMessage(prompt)
        } label: {
            Text(prompt)
                .font(.system(size: 16 * scale))
                .foregroundStyle(Color.brandInk)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.horizontal, 16 * scale)
                .padding(.vertical, 12 * scale)
                .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
                .frame(minHeight: (fillsWidth ? 66 : 46) * scale, alignment: .leading)
                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 24 * scale))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(prompt)
    }

    @ViewBuilder
    private func deviceAgentBackground(in size: CGSize) -> some View {
        let frame = fixedWidthDesignFrame(in: size)
        let scale = frame.width / 402

        ZStack {
            FigmaScreenView(assetName: currentStep.assetName)
                .id(currentStep.assetName)
                .frame(width: frame.width, height: frame.height)

            // The approved frame already contains a static composer. Cover
            // that rasterized control before placing the real TextField so
            // the Agent always shows exactly one editable input.
            LinearGradient(
                colors: [
                    Color(red: 0.997, green: 0.930, blue: 0.935),
                    Color(red: 1.000, green: 0.956, blue: 0.958)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: frame.width, height: 97 * scale)
            .position(x: frame.midX, y: frame.minY + 825.5 * scale)
        }
        .frame(width: frame.width, height: frame.height)
        .frame(width: size.width, height: size.height, alignment: .top)
        .clipped()
    }


    private func agentPromptButton(_ prompt: String, rect: CGRect, in frame: CGRect) -> some View {
        Button {
            sendAgentMessage(prompt)
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: frame.width * rect.width / 402,
            height: frame.height * rect.height / 874
        )
        .position(
            x: frame.minX + frame.width * rect.midX / 402,
            y: frame.minY + frame.height * rect.midY / 874
        )
        .accessibilityLabel(prompt)
    }

    private func deviceAgentBubble(_ message: DeviceAgentMessage, scale: CGFloat) -> some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 7 * scale) {
            Text(message.text)
                .font(.system(size: 14 * scale))
                .foregroundStyle(message.role == .user ? Color.white : Color.brandInk)
                .padding(.horizontal, 14 * scale)
                .padding(.vertical, 10 * scale)
                .background(
                    message.role == .user ? Color.brandPlum : Color.white.opacity(0.94),
                    in: RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                )

            if !message.sources.isEmpty {
                VStack(alignment: .leading, spacing: 4 * scale) {
                    Text("Sources")
                        .font(.system(size: 10 * scale, weight: .semibold))
                        .foregroundStyle(Color.brandPlum.opacity(0.62))
                    ForEach(message.sources.prefix(3)) { source in
                        if source.url.scheme == "momcozy" {
                            HStack(spacing: 4 * scale) {
                                Image(systemName: "doc.text")
                                Text(source.title)
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10 * scale))
                            .foregroundStyle(Color.brandPlum)
                            .accessibilityLabel("Knowledge source: \(source.title)")
                        } else {
                            Link(destination: source.url) {
                                HStack(spacing: 4 * scale) {
                                    Image(systemName: "link")
                                    Text(source.title)
                                        .lineLimit(1)
                                }
                                .font(.system(size: 10 * scale))
                                .foregroundStyle(Color.brandPlum)
                            }
                        }
                    }
                }
                .padding(.horizontal, 6 * scale)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private func sendAgentMessage(_ suggestedPrompt: String? = nil) {
        let question = (suggestedPrompt ?? agentDraft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isAgentResponding else { return }

        store.userDidInteract()
        agentDraft = ""
        isAgentInputFocused = false
        agentMessages.append(DeviceAgentMessage(role: .user, text: question))
        isAgentResponding = true
        agentConnectionStatus = AIAgentClient.isConfigured ? .connecting : .local
        let conversation = agentMessages

        Task {
            do {
                let reply = try await AIAgentClient.shared.reply(to: question, conversation: conversation)
                agentMessages.append(
                    DeviceAgentMessage(
                        role: .assistant,
                        text: reply.text,
                        sources: reply.sources
                    )
                )
                agentConnectionStatus = .live
            } catch {
                let errorMessage = error.localizedDescription
                agentMessages.append(
                    DeviceAgentMessage(
                        role: .assistant,
                        text: "Live connection failed: \(errorMessage)\n\n\(AIAgentClient.localReply(for: question))"
                    )
                )
                agentConnectionStatus = .failed(errorMessage)
                store.showToast("Live Agent error: \(errorMessage)")
            }
            isAgentResponding = false
        }
    }

    @ViewBuilder
    private func exitButton(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let isExpanded = exitPresentation == .expanded
        let designRect = isExpanded
            ? CGRect(x: 252, y: 698, width: 134, height: 56)
            : CGRect(x: 330, y: 698, width: 56, height: 56)

        Button {
            store.userDidInteract()
            exitTask?.cancel()
            // The curved exhibition return button always leaves the feature.
            store.showHighlights()
        } label: {
            FigmaAssetCropView(
                assetName: isExpanded ? "device-welcome-exit" : "device-welcome",
                cropRect: designRect
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(
            width: frame.width * designRect.width / 402,
            height: frame.height * designRect.height / 874
        )
        .position(
            x: frame.minX + frame.width * designRect.midX / 402,
            y: frame.minY + frame.height * designRect.midY / 874
        )
        .accessibilityLabel("Back to selling points")
    }

    private func configureExitButton() {
        exitTask?.cancel()

        // The custom plan/timeline flows manage their own internal stages.
        // Voice Log uses the original Figma step sequence and still keeps the
        // exhibition exit control available after its first highlighted step.
        guard feature == .lactationPlan
                || feature == .lactationTimeline
                || feature == .voiceLog
                || feature == .community
                || !currentStep.hidesExitButton else {
            exitPresentation = .hidden
            return
        }

        guard !hasPresentedExit else {
            exitPresentation = .collapsed
            return
        }

        hasPresentedExit = true
        exitPresentation = .expanded
        exitTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                exitPresentation = .collapsed
            }
        }
    }

    private func fittedDesignFrame(in size: CGSize) -> CGRect {
        fittedDesignFrame(in: size, designSize: CGSize(width: 402, height: 874))
    }

    private func fittedDesignFrame(in size: CGSize, designSize: CGSize) -> CGRect {
        let designAspect = designSize.width / designSize.height
        let availableAspect = size.width / size.height

        if availableAspect > designAspect {
            let width = size.height * designAspect
            return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        }

        let height = size.width / designAspect
        return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
    }

    private func fixedWidthDesignFrame(in size: CGSize) -> CGRect {
        let width = size.width
        return CGRect(x: 0, y: 0, width: width, height: width * 874 / 402)
    }
}

private struct DeviceGuideSourceImage {
    let assetName: String
    var cropUnitRect: CGRect? = nil

    func displayHeight(for width: CGFloat, maximumHeight: CGFloat) -> CGFloat {
        guard let image = FigmaScreenImageLoader.image(named: assetName) else {
            return min(width * 173 / 329, maximumHeight)
        }

        let crop = cropUnitRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        let sourceWidth = max(image.size.width * crop.width, 1)
        let sourceHeight = max(image.size.height * crop.height, 1)
        return min(width * sourceHeight / sourceWidth, maximumHeight)
    }
}

private struct DeviceGuideInstruction {
    let title: String
    let detail: String
    let image: DeviceGuideSourceImage
}

/// The seven Air 1 setup chapters mirror the source order and guidance from
/// the approved product knowledge base. The interface remains native so text
/// and controls stay sharp while the supplied instructional imagery is reused.
private struct DeviceSetupGuideStep {
    let title: String
    let videoResourceName: String
    let caption: String
    let description: String
    let warning: String
    let instructions: [DeviceGuideInstruction]

    var images: [DeviceGuideSourceImage] {
        instructions.map(\.image)
    }


    static let steps: [DeviceSetupGuideStep] = [
        DeviceSetupGuideStep(
            title: "Unbox & Inspect",
            videoResourceName: "Air1SetupStep1",
            caption: "Confirm all accessories are included",
            description: "Parts overview: main unit, collection cups, flanges, membranes, valves, power cable, etc. Use the checklist to verify each item.",
            warning: "Missing or damaged parts? Contact customer support and have your order number and proof of purchase ready.",
            instructions: [
                DeviceGuideInstruction(
                    title: "Check the Air 1 set",
                    detail: "Confirm the Air 1 main units and the supplied accessories are present and free from visible damage.",
                    image: DeviceGuideSourceImage(assetName: "air1-step1-product")
                )
            ]
        ),
        DeviceSetupGuideStep(
            title: "Choose Your Flange Size",
            videoResourceName: "Air1SetupStep2",
            caption: "Measure before selecting a flange",
            description: "Measure the nipple diameter with the included sizing tool, then choose the recommended flange or insert size.",
            warning: "Measure the nipple only—not the areola. Recheck the fit if rubbing, pinching, or swelling occurs.",
            instructions: [
                DeviceGuideInstruction(
                    title: "Measure nipple diameter",
                    detail: "Use the sizing tool around the nipple only and note the closest comfortable diameter.",
                    image: DeviceGuideSourceImage(assetName: "air1-step2-a")
                ),
                DeviceGuideInstruction(
                    title: "Select the matching flange",
                    detail: "Choose the recommended flange or insert size, then confirm the nipple moves freely in the tunnel.",
                    image: DeviceGuideSourceImage(assetName: "air1-step2-b")
                )
            ]
        ),
        DeviceSetupGuideStep(
            title: "Disassemble Parts",
            videoResourceName: "Air1SetupStep3",
            caption: "Remove parts in the correct order",
            description: "Detach the flange, release the milk collector from the main unit, remove the diaphragm, then separate the collector and valve.",
            warning: "Pull gently at the marked edges. Never wash the main unit, charging case, charging cable, or adapter.",
            instructions: [
                DeviceGuideInstruction(
                    title: "Detach the flange",
                    detail: "Lift the flange edge away from the pump without twisting it.",
                    image: DeviceGuideSourceImage(assetName: "air1-step3-a")
                ),
                DeviceGuideInstruction(
                    title: "Detach the milk collector",
                    detail: "Grip the protrusions and release the milk collector from the main unit.",
                    image: DeviceGuideSourceImage(assetName: "air1-step3-b")
                ),
                DeviceGuideInstruction(
                    title: "Remove the diaphragm",
                    detail: "Lift the diaphragm straight out of the milk collector.",
                    image: DeviceGuideSourceImage(assetName: "air1-step3-c")
                ),
                DeviceGuideInstruction(
                    title: "Separate the collector and valve",
                    detail: "Open the milk collector, then gently separate the valve from its base.",
                    image: DeviceGuideSourceImage(assetName: "air1-step3-d")
                )
            ]
        ),
        DeviceSetupGuideStep(
            title: "Clean & Sterilize",
            videoResourceName: "Air1SetupStep4",
            caption: "Clean every washable part before use",
            description: "Wash the washable parts with warm water and mild detergent, then sterilize using boiling water or a steam bag.",
            warning: "Do not wash or sterilize the pump motor. Keep parts away from the heated container’s edges.",
            instructions: [
                DeviceGuideInstruction(
                    title: "Wash every washable part",
                    detail: "Use warm water and mild detergent on the flange, cup, membrane and valve after each use.",
                    image: DeviceGuideSourceImage(assetName: "air1-step4-a")
                ),
                DeviceGuideInstruction(
                    title: "Sterilize and dry",
                    detail: "Sterilize using boiling water or a steam bag, then air-dry every part completely.",
                    image: DeviceGuideSourceImage(assetName: "air1-step4-b")
                )
            ]
        ),
        DeviceSetupGuideStep(
            title: "Assemble the Pump",
            videoResourceName: "Air1SetupStep5",
            caption: "Reassemble every part securely",
            description: "Install the valve and membrane, attach the collection cup, and press around every edge until the seal is even.",
            warning: "A loose membrane or valve can reduce suction. Check that each part is flat and fully seated.",
            instructions: [
                DeviceGuideInstruction(
                    title: "Install the valve and membrane",
                    detail: "Seat the valve fully, then press the membrane flat around the connector.",
                    image: DeviceGuideSourceImage(assetName: "air1-step5-a")
                ),
                DeviceGuideInstruction(
                    title: "Attach the collection cup",
                    detail: "Align the collection cup with the assembled membrane and press it fully into place.",
                    image: DeviceGuideSourceImage(assetName: "air1-step5-b")
                ),
                DeviceGuideInstruction(
                    title: "Close and check the seal",
                    detail: "Press around the entire rim until every edge is even and securely sealed.",
                    image: DeviceGuideSourceImage(assetName: "air1-step5-c")
                )
            ]
        ),
        DeviceSetupGuideStep(
            title: "Wear & Position",
            videoResourceName: "Air1SetupStep6",
            caption: "Center the nipple before pumping",
            description: "Place the pump inside the bra and align the nipple with the flange tunnel. Keep the pump upright against the breast.",
            warning: "Avoid tilting the pump or compressing the breast. Reposition if the nipple rubs the tunnel.",
            instructions: [
                DeviceGuideInstruction(
                    title: "Center the nipple",
                    detail: "Align the nipple with the center of the flange tunnel before pressing the pump against the breast.",
                    image: DeviceGuideSourceImage(assetName: "air1-step6-a")
                ),
                DeviceGuideInstruction(
                    title: "Secure the pump in your bra",
                    detail: "Keep the pump upright and supported without compressing breast tissue.",
                    image: DeviceGuideSourceImage(assetName: "air1-step6-b")
                )
            ]
        ),
        DeviceSetupGuideStep(
            title: "Start Pumping",
            videoResourceName: "Air1SetupStep7",
            caption: "Learn the controls before your first session",
            description: "Use the mode, decrease, increase, and power buttons to start and adjust a comfortable pumping session.",
            warning: "Keep the pump upright when removing it and pour milk through the spout. Stop if pumping feels painful.",
            instructions: [
                DeviceGuideInstruction(
                    title: "Learn the controls",
                    detail: "Use the power, mode, increase and decrease buttons to begin at a comfortable level.",
                    image: DeviceGuideSourceImage(assetName: "air1-step7-a")
                ),
                DeviceGuideInstruction(
                    title: "Remove and pour safely",
                    detail: "Keep the cup upright when removing it, then pour milk slowly through the collection spout.",
                    image: DeviceGuideSourceImage(assetName: "air1-step7-b")
                )
            ]
        )
    ]
}

/// Displays only source imagery supplied in the Air 1 knowledge base. Optional
/// normalized cropping lets a tall checklist become the three landscape pages
/// shown by the approved Figma tip-card component without rasterizing UI text.
private struct SourceMaterialImageView: View {
    let assetName: String
    var cropUnitRect: CGRect?

    init(assetName: String, cropUnitRect: CGRect? = nil) {
        self.assetName = assetName
        self.cropUnitRect = cropUnitRect
    }

    var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
        } else {
            Color.white
        }
    }

    private var image: UIImage? {
        guard let source = FigmaScreenImageLoader.image(named: assetName) else {
            return nil
        }
        guard
            let cropUnitRect,
            let cgImage = source.cgImage
        else {
            return source
        }

        let unitBounds = CGRect(x: 0, y: 0, width: 1, height: 1)
        let safeUnitRect = cropUnitRect.intersection(unitBounds)
        let pixelRect = CGRect(
            x: safeUnitRect.minX * CGFloat(cgImage.width),
            y: safeUnitRect.minY * CGFloat(cgImage.height),
            width: safeUnitRect.width * CGFloat(cgImage.width),
            height: safeUnitRect.height * CGFloat(cgImage.height)
        ).integral

        guard let cropped = cgImage.cropping(to: pixelRect) else {
            return source
        }
        return UIImage(cgImage: cropped, scale: source.scale, orientation: source.imageOrientation)
    }
}

private enum ExitPresentation {
    case hidden
    case expanded
    case collapsed
}

private enum DemoAction {
    case advance
    case back
    case finish
    case cover
    case restart
    case unavailable
}

private struct DemoTarget {
    let rect: CGRect
    let label: String
    let action: DemoAction

    static func next(_ rect: CGRect, _ label: String) -> DemoTarget {
        DemoTarget(rect: rect, label: label, action: .advance)
    }

    static func finish(_ rect: CGRect, _ label: String) -> DemoTarget {
        DemoTarget(rect: rect, label: label, action: .finish)
    }

    static func cover(_ rect: CGRect, _ label: String) -> DemoTarget {
        DemoTarget(rect: rect, label: label, action: .cover)
    }

    static func restart(_ rect: CGRect, _ label: String) -> DemoTarget {
        DemoTarget(rect: rect, label: label, action: .restart)
    }

    static func unavailable(_ rect: CGRect, _ label: String) -> DemoTarget {
        DemoTarget(rect: rect, label: label, action: .unavailable)
    }
}

private struct DemoStep {
    let assetName: String
    var targets: [DemoTarget] = []
    var automaticAdvanceDelay: Double?
    var hidesExitButton = false
    var hasBackButton = false
    var designHeight: CGFloat = 874
    var scrollsVertically = false
}

private extension ShowcaseFeature {
    var demoSteps: [DemoStep] {
        switch self {
        case .deviceAssistant:
            return [
                DemoStep(
                    assetName: "device-pair-hd",
                    targets: [
                        .next(CGRect(x: 0.07, y: 0.86, width: 0.86, height: 0.10), "Connect"),
                        .next(CGRect(x: 0.05, y: 0.39, width: 0.90, height: 0.11), "Device pairing tip")
                    ],
                    hidesExitButton: true
                ),
                DemoStep(
                    assetName: "device-welcome-hd",
                    targets: [
                        .next(CGRect(x: 0.05, y: 0.86, width: 0.90, height: 0.09), "Get started"),
                        .finish(CGRect(x: 0.78, y: 0.77, width: 0.18, height: 0.11), "Back to selling points")
                    ]
                ),
                DemoStep(
                    assetName: "device-guide-1",
                    targets: [
                        .next(CGRect(x: 0.80, y: 0.06, width: 0.19, height: 0.13), "Open device assistant"),
                        .next(CGRect(x: 0.05, y: 0.07, width: 0.90, height: 0.11), "AI Assistant tip")
                    ],
                    hidesExitButton: true
                ),
                DemoStep(
                    assetName: "device-guide-2",
                    targets: [
                        .next(CGRect(x: 0.00, y: 0.25, width: 1.00, height: 0.22), "Watch setup video"),
                        .next(CGRect(x: 0.05, y: 0.45, width: 0.90, height: 0.12), "Setup video tip")
                    ],
                    hidesExitButton: true
                ),
                DemoStep(
                    assetName: "device-video-phase1",
                    hidesExitButton: true
                ),
                DemoStep(
                    assetName: "device-video-phase2",
                    hidesExitButton: true
                ),
                DemoStep(assetName: "device-chat", hasBackButton: true)
            ]

        case .voiceLog:
            return [
                DemoStep(
                    assetName: "voice-home",
                    targets: [
                        .next(CGRect(x: 0.04, y: 0.55, width: 0.92, height: 0.11), "AI Quick Log"),
                        .next(CGRect(x: 0.04, y: 0.43, width: 0.92, height: 0.13), "Daily Summary tip")
                    ],
                    hidesExitButton: true
                ),
                DemoStep(
                    assetName: "voice-log-1",
                    targets: [.next(CGRect(x: 0.38, y: 0.83, width: 0.24, height: 0.14), "Start voice logging")],
                    hasBackButton: true
                ),
                DemoStep(assetName: "voice-log-2", hasBackButton: true),
                DemoStep(assetName: "voice-log-3", automaticAdvanceDelay: 1.8, hasBackButton: true),
                DemoStep(
                    assetName: "voice-log-4",
                    targets: [.next(CGRect(x: 0.03, y: 0.75, width: 0.94, height: 0.10), "Save")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "voice-logged",
                    automaticAdvanceDelay: 1.8,
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "voice-home-final",
                    designHeight: 2441,
                    scrollsVertically: true
                )
            ]

        case .lactationPlan:
            return [
                DemoStep(
                    assetName: "plan-home-scroll",
                    targets: [.next(CGRect(x: 0.684, y: 0.391, width: 0.261, height: 0.033), "Add Lactation Plan")],
                    hidesExitButton: true,
                    designHeight: 2441,
                    scrollsVertically: true
                ),
                DemoStep(
                    assetName: "plan-start",
                    targets: [.next(CGRect(x: 0.03, y: 0.85, width: 0.94, height: 0.12), "Get Started")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-info",
                    targets: [.next(CGRect(x: 0.03, y: 0.68, width: 0.94, height: 0.15), "Select Power Pumping")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-feed-choice",
                    targets: [.next(CGRect(x: 0.040, y: 0.474, width: 0.920, height: 0.092), "Exclusively Pumping")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-feed-count",
                    targets: [.next(CGRect(x: 0.050, y: 0.874, width: 0.900, height: 0.061), "Next")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-night-choice",
                    targets: [.next(CGRect(x: 0.040, y: 0.505, width: 0.450, height: 0.066), "Yes, pump at night")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-time-preference",
                    targets: [.next(CGRect(x: 0.040, y: 0.601, width: 0.920, height: 0.064), "Choose preferred pumping time")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-time-picker",
                    targets: [.next(CGRect(x: 0.771, y: 0.659, width: 0.189, height: 0.055), "Done")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-time-multiple",
                    targets: [
                        DemoTarget(
                            rect: CGRect(x: 0.040, y: 0.749, width: 0.920, height: 0.066),
                            label: "Add another preferred time",
                            action: .back
                        ),
                        .next(CGRect(x: 0.050, y: 0.874, width: 0.900, height: 0.061), "Next")
                    ],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-confirm",
                    targets: [.next(CGRect(x: 0.050, y: 0.874, width: 0.900, height: 0.061), "Generate")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-generating-v2",
                    targets: [.next(CGRect(x: 0.050, y: 0.874, width: 0.900, height: 0.061), "Got It")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-first",
                    targets: [.next(CGRect(x: 0.03, y: 0.88, width: 0.94, height: 0.10), "Confirm")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-notification",
                    targets: [.next(CGRect(x: 0.03, y: 0.07, width: 0.94, height: 0.14), "View Lactation Data")]
                ),
                DemoStep(
                    assetName: "plan-schedule",
                    targets: [.next(CGRect(x: 0.50, y: 0.78, width: 0.20, height: 0.18), "Open pumping summary")],
                    hidesExitButton: true,
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "plan-data-scroll",
                    targets: [.next(CGRect(x: 0.587, y: 0.398, width: 0.254, height: 0.047), "Share accomplishment")],
                    hidesExitButton: true,
                    hasBackButton: true,
                    designHeight: 1376,
                    scrollsVertically: true
                ),
                DemoStep(assetName: "plan-share")
            ]

        case .lactationTimeline:
            return [
                DemoStep(
                    assetName: "timeline-home",
                    targets: [.next(CGRect(x: 0.50, y: 0.36, width: 0.28, height: 0.13), "Timeline")],
                    hidesExitButton: true
                ),
                DemoStep(
                    assetName: "timeline-entry",
                    targets: [.next(CGRect(x: 0.44, y: 0.82, width: 0.38, height: 0.13), "Personalize timeline")],
                    hidesExitButton: true,
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "timeline-privacy-1",
                    targets: [.next(CGRect(x: 0.03, y: 0.85, width: 0.94, height: 0.12), "Get Started")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "timeline-q1",
                    targets: [.next(CGRect(x: 0.03, y: 0.85, width: 0.94, height: 0.12), "Next")],
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "timeline-q2",
                    targets: [.next(CGRect(x: 0.03, y: 0.85, width: 0.94, height: 0.12), "Set Timeline")],
                    hasBackButton: true
                ),
                DemoStep(assetName: "timeline-privacy-2", automaticAdvanceDelay: 1.6),
                DemoStep(assetName: "timeline-result", hasBackButton: true)
            ]

        case .community:
            return [
                DemoStep(
                    assetName: "community-home-2",
                    targets: [.next(CGRect(x: 0.03, y: 0.52, width: 0.94, height: 0.13), "Pumping moms community")],
                    hidesExitButton: true
                ),
                DemoStep(
                    assetName: "community-status-2",
                    targets: [.next(CGRect(x: 0, y: 0, width: 1, height: 1), "Continue")],
                    hidesExitButton: true,
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "community-reaction",
                    targets: [.next(CGRect(x: 0.12, y: 0.74, width: 0.70, height: 0.12), "Send reaction")],
                    hidesExitButton: true,
                    hasBackButton: true
                ),
                DemoStep(
                    assetName: "community-group-full",
                    targets: [
                        .unavailable(
                            CGRect(x: 0.70, y: 0.132, width: 0.27, height: 0.038),
                            "Share your status"
                        ),
                        .unavailable(
                            CGRect(x: 0.31, y: 0.438, width: 0.39, height: 0.045),
                            "Join and post"
                        ),
                        .unavailable(
                            CGRect(x: 0.43, y: 0.548, width: 0.18, height: 0.035),
                            "Comment on first post"
                        ),
                        .unavailable(
                            CGRect(x: 0.43, y: 0.758, width: 0.18, height: 0.035),
                            "Comment on second post"
                        ),
                        .unavailable(
                            CGRect(x: 0.43, y: 0.963, width: 0.18, height: 0.035),
                            "Comment on third post"
                        )
                    ],
                    hasBackButton: true,
                    designHeight: 1791,
                    scrollsVertically: true
                )
            ]
        }
    }
}

// Retained for the legacy source files, which are no longer on the runtime path.
struct DemoTip: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: "lightbulb.max.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPlum)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.brandInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .demoCard()
    }
}

struct DemoProgress: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.brandPlum : Color.brandBlush)
                    .frame(maxWidth: index == current ? 32 : 12, minHeight: 5, maxHeight: 5)
            }
        }
    }
}

private struct DeviceAgentMessage: Identifiable, Hashable {
    enum Role: String, Hashable {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
    var sources: [DeviceAgentSource] = []
}

private struct DeviceAgentSource: Identifiable, Hashable {
    var id: String { url.absoluteString }
    let title: String
    let url: URL
}

private struct DeviceAgentReply {
    let text: String
    let sources: [DeviceAgentSource]
}

private enum DeviceAgentConnectionStatus: Equatable {
    case configured
    case connecting
    case live
    case local
    case failed(String)

    var color: Color {
        switch self {
        case .live:
            .green
        case .configured, .connecting:
            .orange
        case .local, .failed:
            .red
        }
    }

    var label: String {
        switch self {
        case .configured:
            "Proxy configured · send a message to verify"
        case .connecting:
            "Connecting to DeepSeek…"
        case .live:
            "DeepSeek · Live API"
        case .local:
            "Local demo · proxy is not configured"
        case let .failed(message):
            "Connection failed · \(message)"
        }
    }
}

private enum AIAgentError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case api(status: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            "AI Agent is not configured."
        case .invalidResponse:
            "The Agent returned an invalid response."
        case let .api(status, message):
            "AI API error \(status): \(message)"
        case .emptyResponse:
            "The Agent returned no message."
        }
    }
}

/// Calls the local server-side AI proxy. API keys must never ship in the iOS app.
private struct AIAgentClient {
    static let shared = AIAgentClient()

    static var isConfigured: Bool {
        configuration != nil
    }

    private static var configuration: URL? {
        let environment = ProcessInfo.processInfo.environment
        let proxyValue = environment["AI_PROXY_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "AI_PROXY_URL") as? String
            ?? environment["OPENAI_PROXY_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "OPENAI_PROXY_URL") as? String

        if let proxyValue,
           let proxyURL = URL(string: proxyValue),
           let scheme = proxyURL.scheme,
           ["https", "http"].contains(scheme.lowercased()) {
            return proxyURL
        }

        return nil
    }

    func reply(
        to question: String,
        conversation: [DeviceAgentMessage]
    ) async throws -> DeviceAgentReply {
        guard let endpoint = Self.configuration else {
            return DeviceAgentReply(text: Self.localReply(for: question), sources: [])
        }

        let messages: [[String: String]] = conversation.suffix(10).map { message in
            [
                "role": message.role == .user ? "user" : "assistant",
                "content": message.text
            ]
        }
        let body: [String: Any] = [
            "system": """
                You are Cozie AI for the Momcozy Air 1 wearable breast pump.
                Give concise, practical troubleshooting guidance in the user's language.
                Do not claim to diagnose medical conditions. For pain, injury, fever, bleeding, or urgent
                symptoms, advise the user to stop pumping and contact a qualified healthcare professional.
                """,
            "messages": messages,
            "max_tokens": 600
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("cologne-showcase-ios", forHTTPHeaderField: "X-Demo-Client")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIAgentError.invalidResponse
        }

        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            throw AIAgentError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = ((json["error"] as? [String: Any])?["message"] as? String)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw AIAgentError.api(status: httpResponse.statusCode, message: message)
        }

        if let simplifiedText = json["text"] as? String, !simplifiedText.isEmpty {
            let sources = Self.parseSimplifiedSources(json["sources"])
            return DeviceAgentReply(text: simplifiedText, sources: sources)
        }

        throw AIAgentError.emptyResponse
    }

    private static func parseResponsesAPI(_ json: [String: Any]) throws -> DeviceAgentReply {
        guard let output = json["output"] as? [[String: Any]] else {
            throw AIAgentError.emptyResponse
        }

        var textParts: [String] = []
        var sources: [DeviceAgentSource] = []

        for item in output where item["type"] as? String == "message" {
            guard let content = item["content"] as? [[String: Any]] else { continue }
            for part in content where part["type"] as? String == "output_text" {
                if let text = part["text"] as? String, !text.isEmpty {
                    textParts.append(text)
                }

                guard let annotations = part["annotations"] as? [[String: Any]] else { continue }
                for annotation in annotations {
                    let citation = (annotation["url_citation"] as? [String: Any]) ?? annotation
                    guard
                        let rawURL = citation["url"] as? String,
                        let url = URL(string: rawURL)
                    else { continue }
                    let title = (citation["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    sources.append(
                        DeviceAgentSource(
                            title: title?.isEmpty == false ? title! : (url.host ?? "Web source"),
                            url: url
                        )
                    )
                }
            }
        }

        let text = textParts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw AIAgentError.emptyResponse }

        var seen = Set<String>()
        let uniqueSources = sources.filter { seen.insert($0.url.absoluteString).inserted }
        return DeviceAgentReply(text: text, sources: uniqueSources)
    }

    private static func parseSimplifiedSources(_ value: Any?) -> [DeviceAgentSource] {
        guard let items = value as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            guard let rawURL = item["url"] as? String, let url = URL(string: rawURL) else { return nil }
            return DeviceAgentSource(
                title: item["title"] as? String ?? url.host ?? "Web source",
                url: url
            )
        }
    }

    static func localReply(for question: String) -> String {
        let normalized = question.lowercased()
        if normalized.contains("flange") || normalized.contains("fit") {
            return "Your nipple should move freely in the tunnel without rubbing, while little or no areola is pulled in. Start at low suction. If pumping hurts or leaves swelling or whitening, stop and try a different flange size."
        }
        if normalized.contains("suction") || normalized.contains("weak") {
            return "Check that the valve and membrane are clean, dry, undamaged, and seated flat. Reassemble the cup firmly, confirm the flange seal, then restart at a low level. Replace any stretched or torn soft parts."
        }
        if normalized.contains("connect") || normalized.contains("bluetooth") {
            return "Keep the Air 1 charged and close to the phone, turn Bluetooth on, and reopen the Momcozy app. If it still does not appear, restart the pump and phone, then remove the old pairing before trying again."
        }
        return "I can help with Air 1 setup, flange fit, suction, cleaning, charging, and connection issues. This offline demo response is general guidance; start the DeepSeek proxy for a live answer."
    }
}
