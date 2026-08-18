import SwiftUI
import UIKit

/// Stateful interaction layer for the approved Timeline Figma screens.
/// Questionnaire and personalized result screens are native SwiftUI; only
/// source illustrations and article photography remain image assets.
struct TimelineDemoView: View {
    @ObservedObject var store: DemoStore

    @State private var stage: TimelineStage = .home
    @State private var privacyAccepted = true
    @State private var breastfeedingGoalValue = 12
    @State private var breastfeedingGoalUnit: TimelineDurationUnit = .month
    @State private var maternityLeaveValue = 3
    @State private var maternityLeaveUnit: TimelineDurationUnit = .week
    @State private var showsMoreMenu = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if stage == .result {
                    personalizedResult(in: proxy.size)
                        .id(stage.assetName)
                } else if [.privacy, .goal, .leave, .ready].contains(stage) {
                    nativeQuestionnaire(in: proxy.size)
                        .id(stage.assetName)
                } else {
                    FigmaScreenView(assetName: stage.assetName)
                        .id(stage.assetName)

                    interactions(in: proxy.size)
                }
            }
        }
        .ignoresSafeArea()
        .confirmationDialog("Timeline options", isPresented: $showsMoreMenu, titleVisibility: .visible) {
            Button("Stage Knowledges") { move(to: .knowledge) }
            Button("Personalize Timeline") { move(to: .privacy) }
            Button("Preview Weekly Notification") { move(to: .notification) }
            Button("Cancel", role: .cancel) {}
        }
        .task(id: stage) {
            guard stage == .ready else { return }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            move(to: .result)
        }
    }

    @ViewBuilder
    private func interactions(in size: CGSize) -> some View {
        switch stage {
        case .home:
            tapArea(CGRect(x: 204, y: 354, width: 106, height: 70), label: "Open Timeline", in: size) {
                move(to: .entryTip)
            }
            tapArea(CGRect(x: 18, y: 418, width: 366, height: 142), label: "Pumping Timeline tip", in: size) {
                move(to: .entryTip)
            }

        case .entryTip:
            tapArea(CGRect(x: 24, y: 602, width: 354, height: 150), label: "Personalized Timeline tip", in: size) {
                move(to: .privacy)
            }
            tapArea(CGRect(x: 181, y: 778, width: 143, height: 76), label: "Personalize Timeline", in: size) {
                move(to: .privacy)
            }
            topBack(in: size, destination: .home)

        case .insights:
            insightInteractions(in: size, personalized: false)

        case .privacy:
            privacyCheckbox(in: size)
            tapArea(CGRect(x: 14, y: 696, width: 370, height: 72), label: "Toggle data processing consent", in: size) {
                privacyAccepted.toggle()
            }
            tapArea(
                CGRect(x: 20, y: 764, width: 362, height: 60),
                label: "Get Started",
                enabled: privacyAccepted,
                in: size
            ) {
                move(to: .goal)
            }
            topBack(in: size, destination: .entryTip)
            exitToPrevious(.entryTip, in: size)

        case .goal:
            durationWheel(in: size, mode: .goal)
            tapArea(CGRect(x: 20, y: 758, width: 362, height: 68), label: "Next", in: size) {
                move(to: .leave)
            }
            topBack(in: size, destination: .privacy)

        case .leave:
            durationWheel(in: size, mode: .leave)
            tapArea(CGRect(x: 20, y: 758, width: 362, height: 68), label: "Set Timeline", in: size) {
                move(to: .ready)
            }
            topBack(in: size, destination: .goal)

        case .ready:
            exitToPrevious(.leave, in: size)

        case .result:
            EmptyView()

        case .knowledge:
            tapArea(CGRect(x: 338, y: 116, width: 54, height: 60), label: "Share Stage Knowledge", in: size) {
                move(to: .share)
            }
            tapArea(CGRect(x: 176, y: 775, width: 151, height: 72), label: "Personalize Timeline", in: size) {
                move(to: .privacy)
            }
            tapArea(CGRect(x: 326, y: 775, width: 66, height: 72), label: "Collapse Stage Knowledge", in: size) {
                move(to: .insights)
            }
            topBack(in: size, destination: .insights)

        case .share:
            tapArea(CGRect(x: 10, y: 640, width: 70, height: 72), label: "Close sharing", in: size) {
                move(to: .knowledge)
            }
            tapArea(CGRect(x: 10, y: 716, width: 90, height: 118), label: "Share to Community", in: size) {
                move(to: .communityShare)
            }
            tapArea(CGRect(x: 98, y: 716, width: 90, height: 118), label: "Share to Facebook", in: size) {
                store.showToast("Facebook sharing simulated locally")
            }

        case .communityShare:
            tapArea(CGRect(x: 296, y: 52, width: 96, height: 72), label: "Post to Community", in: size) {
                store.showToast("Timeline moment posted locally")
                move(to: .result)
            }
            topBack(in: size, destination: .share)

        case .notification:
            tapArea(CGRect(x: 16, y: 640, width: 370, height: 110), label: "Open breastfeeding Timeline notification", in: size) {
                move(to: .result)
            }
        }
    }

    private func nativeQuestionnaire(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402

        return questionnaireDesign
            .frame(width: 402, height: 874)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: frame.width, height: frame.height, alignment: .topLeading)
            .position(x: frame.midX, y: frame.midY)
    }

    @ViewBuilder
    private var questionnaireDesign: some View {
        switch stage {
        case .privacy:
            nativePrivacyQuestionnaire
        case .goal:
            nativeDurationQuestionnaire(mode: .goal)
        case .leave:
            nativeDurationQuestionnaire(mode: .leave)
        case .ready:
            nativeTimelineReady
        default:
            Color.clear
        }
    }

    private var questionnaireBackground: some View {
        Color.white
            .overlay {
                RadialGradient(
                    colors: [
                        Color(red: 1, green: 0.80, blue: 0.84),
                        Color(red: 1, green: 0.91, blue: 0.93).opacity(0.72),
                        Color.white.opacity(0)
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 660
                )
            }
            .clipped()
    }

    private var nativePrivacyQuestionnaire: some View {
        ZStack {
            questionnaireBackground

            questionnaireBackButton(destination: .entryTip)
                .position(x: 42, y: 84)

            TimelineFigmaImage(assetName: "timeline-privacy-r1")
            .frame(width: 200, height: 200)
            .position(x: 201, y: 282)

            VStack(spacing: 12) {
                Text("Let's build your timeline!")
                    .font(.custom(Font.exposureMinus10Name, size: 24))
                    .tracking(0.48)
                    .foregroundStyle(Color.brandInk)

                Text("Answer only 2 quick questions to build your\nbreastfeeding timeline")
                    .font(.brandBody(14))
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.brandInk)
            }
            .frame(width: 338)
            .position(x: 201, y: 445)

            HStack(alignment: .top, spacing: 8) {
                Button {
                    store.userDidInteract()
                    privacyAccepted.toggle()
                } label: {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(privacyAccepted ? Color.brandInk : Color.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(Color.brandInk, lineWidth: 1)
                            if privacyAccepted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)

                (
                    Text("I agree to the collection of my breastfeeding duration, goals, and my baby's personal information. Learn more in the ")
                        .font(.brandBody(12))
                    + Text("Breastfeeding Plan Data Processing Notice")
                        .font(.custom(Font.aeonikBoldName, size: 12))
                        .underline()
                )
                .foregroundStyle(Color.brandInk)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 362, alignment: .leading)
            .position(x: 201, y: 730)

            questionnaireButton("Get Started", enabled: privacyAccepted) {
                move(to: .goal)
            }
            .position(x: 201, y: 792)
        }
    }

    private func nativeDurationQuestionnaire(mode: TimelinePickerMode) -> some View {
        let isGoal = mode == .goal
        let title = isGoal
            ? "What is your total\nbreastfeeding goal?"
            : "How long is your\nmaternity leave?"
        let detail = isGoal
            ? "Starting from your baby's birth, we'll automatically\ncalculate how much time remains toward your\nbreastfeeding goal."
            : "Please select based on your unique situation, with\nflexible units in days, weeks, or months."
        let wheelCenterY: CGFloat = isGoal ? 432 : 412

        return ZStack {
            questionnaireBackground

            questionnaireBackButton(destination: isGoal ? .privacy : .goal)
                .position(x: 42, y: 84)

            VStack(spacing: 24) {
                Text(isGoal ? "1/2" : "2/2")
                    .font(.custom(Font.exposureMinus10Name, size: 24))
                    .tracking(0.48)

                VStack(spacing: 12) {
                    Text(title)
                        .font(.custom(Font.exposureMinus10Name, size: 24))
                        .tracking(0.48)
                        .lineSpacing(0)
                    Text(detail)
                        .font(.brandBody(14))
                        .lineSpacing(2)
                }
            }
            .foregroundStyle(Color.brandInk)
            .multilineTextAlignment(.center)
            .frame(width: 338)
            .position(x: 201, y: isGoal ? 220 : 210)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.28))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    }
                    .frame(width: 362, height: 66)

                if isGoal {
                    TimelineDurationWheel(
                        value: $breastfeedingGoalValue,
                        unit: $breastfeedingGoalUnit,
                        values: Array(1...24),
                        units: [.week, .month],
                        scale: 1,
                        onInteraction: { store.userDidInteract() }
                    )
                    .accessibilityLabel("Breastfeeding goal duration")
                } else {
                    TimelineDurationWheel(
                        value: $maternityLeaveValue,
                        unit: $maternityLeaveUnit,
                        values: Array(1...52),
                        units: TimelineDurationUnit.allCases,
                        scale: 1,
                        onInteraction: { store.userDidInteract() }
                    )
                    .accessibilityLabel("Maternity leave duration")
                }
            }
            .frame(width: 362, height: 158)
            .clipped()
            .position(x: 201, y: wheelCenterY)

            questionnaireButton(isGoal ? "Next" : "Set Timeline") {
                move(to: isGoal ? .leave : .ready)
            }
            .position(x: 201, y: 792)
        }
    }

    private var nativeTimelineReady: some View {
        ZStack {
            questionnaireBackground

            ZStack {
                TimelineFigmaImage(assetName: "timeline-ready-r2")
                TimelineFigmaImage(assetName: "timeline-ready-r1")
            }
            .frame(width: 200, height: 200)
            .position(x: 201, y: 280)

            VStack(spacing: 12) {
                Text("Your timeline is ready, Alice!")
                    .font(.custom(Font.exposureMinus10Name, size: 24))
                    .tracking(0.48)

                Text("We've personalized your breastfeeding journey based\non your goals. Let's make every stage count.")
                    .font(.brandBody(14))
                    .lineSpacing(2)
            }
            .foregroundStyle(Color.brandInk)
            .multilineTextAlignment(.center)
            .frame(width: 338)
            .position(x: 201, y: 460)
        }
    }

    private func questionnaireBackButton(destination: TimelineStage) -> some View {
        Button {
            move(to: destination)
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.brandInk)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.52), in: Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.85), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Previous Timeline screen")
    }

    private func questionnaireButton(
        _ title: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.userDidInteract()
            action()
        } label: {
            Text(title)
                .font(.brandSemiBold(16))
                .foregroundStyle(.white)
                .frame(width: 362, height: 48)
                .background(Color.brandInk.opacity(enabled ? 1 : 0.32), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func personalizedResult(in size: CGSize) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                nativeResultHeader
                    .padding(.top, 56)
                    .padding(.bottom, 10)

                nativeResultSummary
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)

                nativeTimelineChartCard

                nativeStageInsight
            }
            .frame(maxWidth: 402)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.visible)
        .background(Color.white)
        .simultaneousGesture(
            DragGesture(minimumDistance: 2)
                .onChanged { _ in store.userDidInteract() }
        )
    }

    private var nativeResultHeader: some View {
        HStack {
            Button {
                move(to: .ready)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().stroke(Color(red: 0.945, green: 0.945, blue: 0.945), lineWidth: 0.8) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous Timeline screen")

            Spacer()
            Text("Timeline")
                .font(.brandMedium(14))
                .foregroundStyle(Color.brandInk)
            Spacer()

            Button {
                store.userDidInteract()
                showsMoreMenu = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().stroke(Color(red: 0.945, green: 0.945, blue: 0.945), lineWidth: 0.8) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More Timeline options")
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }

    private var nativeResultSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                timelineSummaryCard(label: "Plan", value: "1", suffix: "/ 12 months")
                timelineSummaryCard(label: "Stage", value: "2", suffix: "/ 5 stages")
            }

            Text("Lactation Initiation: Milk begins to come in")
                .font(.custom(Font.exposureMinus10Name, size: 24))
                .tracking(0.48)
                .foregroundStyle(Color.brandInk)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(timelineTodayDate) - \(timelineTodayDate)")
                .font(.brandBody(12))
                .foregroundStyle(Color(red: 0.486, green: 0.435, blue: 0.463))
        }
    }

    private func timelineSummaryCard(label: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.brandMedium(12))
                .foregroundStyle(Color(red: 0.467, green: 0.020, blue: 0.137))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.brandMedium(16))
                    .foregroundStyle(Color(red: 0.467, green: 0.020, blue: 0.137))
                Text(suffix)
                    .font(.brandBody(12))
                    .foregroundStyle(Color.brandInk.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 1, green: 0.969, blue: 0.973), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 1, green: 0.867, blue: 0.882), lineWidth: 0.7)
        }
    }

    private var nativeTimelineChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimelineIntakeChart(date: timelineTooltipDate)
                .frame(height: 232)

            HStack(spacing: 24) {
                timelineLegend(color: Color(red: 0.467, green: 0.020, blue: 0.137), title: "Average Intake")
                timelineLegend(color: Color(red: 0.933, green: 0.612, blue: 0.655), title: "Percentiles")
            }
            .frame(maxWidth: .infinity)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.brandInk)

                (
                    Text("Human-milk intake of Exclusively breastfed infants. Sources: WHO · ABM · LLLI. ")
                        .foregroundStyle(Color.brandInk)
                    + Text("Clinically informed reference ranges based on international breastfeeding research. Individual output may vary.")
                        .foregroundStyle(Color(red: 0.486, green: 0.435, blue: 0.463))
                )
                .font(.brandBody(12))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private func timelineLegend(color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.brandBody(12))
                .foregroundStyle(Color.brandInk)
        }
    }

    private var nativeStageInsight: some View {
        VStack(alignment: .leading, spacing: 24) {
            Capsule()
                .fill(Color.white.opacity(0.6))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            HStack {
                Text("Stage Insight")
                    .font(.brandMedium(16))
                Spacer()
                Button {
                    move(to: .share)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .regular))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share Stage Insight")
            }

            VStack(alignment: .leading, spacing: 16) {
                Label("Update Weekly", systemImage: "sparkles")
                    .font(.brandBody(12))
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

                Text("What you're experiencing is completely normal")
                    .font(.custom(Font.exposureMinus10Name, size: 24))
                    .tracking(0.48)

                Text("Many moms feel overwhelmed during this phase. What you're experiencing is completely normal.")
                    .font(.brandBody(16))

                Text("Colostrum transitions to mature milk. Frequent feeding signals your body to produce more, engorgement is normal and temporary.")
                    .font(.brandBody(16))
            }

            insightSection(icon: "clock", title: "Stage Timeline") {
                Text("Postpartum Days 0–3")
            }

            insightSection(icon: "binoculars", title: "Stage Characteristics") {
                Text("• Breast fullness increases\n• Milk volume begins rising\n• Hormonal transition phase")
            }

            insightSection(icon: "hand.thumbsup", title: "Warm Tips") {
                Text("• Feed frequently\n• Use warm compress before pumping\n• Stay hydrated and rest when possible")
            }

            insightSection(icon: "books.vertical", title: "Related Readings") {
                Text("This content is currently available in English only.")
            }

            timelineReading(
                image: "timeline-result-r2",
                title: "Lactation support: Tips for a smooth nursing journey"
            )
            timelineReading(
                image: "timeline-result-r3",
                title: "The ultimate guide to a smooth C-Section recovery"
            )
            timelineReading(
                image: "timeline-result-r6",
                title: "Pre-Pregnancy detox: Clearing the path for baby"
            )

            Button {
                move(to: .knowledge)
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("Open Stage Knowledges")
        }
        .font(.brandBody(16))
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.bottom, 44)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.933, green: 0.612, blue: 0.655),
                    Color(red: 0.467, green: 0.020, blue: 0.137)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
    }

    private func insightSection<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.brandMedium(16))
            content()
                .font(.brandBody(16))
                .lineSpacing(3)
        }
    }

    private func timelineReading(image: String, title: String) -> some View {
        Button {
            store.userDidInteract()
        } label: {
            HStack(spacing: 12) {
                TimelineFigmaImage(assetName: image, contentMode: .fill)
                    .frame(width: 114, height: 114)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.custom(Font.exposureMinus10Name, size: 20))
                        .multilineTextAlignment(.leading)
                    Text("Vorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulpe libero et velit...")
                        .font(.brandBody(12))
                        .tracking(0.24)
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                }
            }
            .foregroundStyle(.white)
            .padding(.vertical, 24)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.20))
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var timelineTodayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: .now)
    }

    private var timelineTooltipDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: .now)
    }

    private func longResultTapArea(
        _ rect: CGRect,
        label: String,
        in contentFrame: CGRect,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.userDidInteract()
            action()
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: contentFrame.width * rect.width / 402,
            height: contentFrame.height * rect.height / 1809
        )
        .position(
            x: contentFrame.width * rect.midX / 402,
            y: contentFrame.height * rect.midY / 1809
        )
        .accessibilityLabel(label)
    }

    private func insightInteractions(in size: CGSize, personalized: Bool) -> some View {
        ZStack {
            tapArea(CGRect(x: 203, y: 114, width: 184, height: 56), label: "Sleeping Timeline", in: size) {
                store.showToast("Sleeping timeline is available as a separate insight")
            }
            tapArea(CGRect(x: 20, y: 316, width: 366, height: 276), label: "Inspect chart data", in: size) {
                store.showToast(personalized ? "Stage 3 · Milk intake 6 oz" : "Stage 4 · Milk intake 6 oz")
            }
            tapArea(CGRect(x: 334, y: 688, width: 60, height: 68), label: "Share Stage Insight", in: size) {
                move(to: .share)
            }
            tapArea(CGRect(x: 176, y: 770, width: 150, height: 78), label: "Personalize Timeline", in: size) {
                move(to: .privacy)
            }
            tapArea(CGRect(x: 326, y: 770, width: 66, height: 78), label: "Open Stage Knowledges", in: size) {
                move(to: .knowledge)
            }
            tapArea(CGRect(x: 326, y: 48, width: 68, height: 76), label: "More Timeline options", in: size) {
                store.userDidInteract()
                showsMoreMenu = true
            }
            topBack(in: size, destination: .home)
        }
    }

    private func privacyCheckbox(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return RoundedRectangle(cornerRadius: frame.width * 3 / 402, style: .continuous)
            .fill(privacyAccepted ? Color.brandPlum : Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: frame.width * 3 / 402, style: .continuous)
                    .stroke(Color.brandPlum, lineWidth: 1)
                if privacyAccepted {
                    Image(systemName: "checkmark")
                        .font(.system(size: max(9, frame.width * 12 / 402), weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: frame.width * 18 / 402, height: frame.width * 18 / 402)
            .position(
                x: frame.minX + frame.width * 29 / 402,
                y: frame.minY + frame.height * 718 / 874
            )
            .allowsHitTesting(false)
    }

    private func durationWheel(in size: CGSize, mode: TimelinePickerMode) -> some View {
        let frame = fittedDesignFrame(in: size)
        let rect = mode == .goal
            ? CGRect(x: 0, y: 353, width: 402, height: 158)
            : CGRect(x: 0, y: 333, width: 402, height: 158)
        let scale = frame.width / 402

        return ZStack {
            // Remove only the static Figma wheel values. A horizontal strip
            // from the same approved frame preserves its exact pink gradient.
            FigmaAssetCropView(
                assetName: mode == .goal ? "timeline-q1-scroll" : "timeline-q2-scroll",
                cropRect: CGRect(x: 0, y: 520, width: 402, height: 4)
            )
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                .fill(Color.white.opacity(0.30))
                .overlay {
                    RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.82), lineWidth: max(0.7, scale))
                }
                .frame(width: 362 * scale, height: 66 * scale)
                .offset(y: 4 * scale)
                .allowsHitTesting(false)

            if mode == .goal {
                TimelineDurationWheel(
                    value: $breastfeedingGoalValue,
                    unit: $breastfeedingGoalUnit,
                    values: Array(1...24),
                    units: [.week, .month],
                    scale: scale,
                    onInteraction: { store.userDidInteract() }
                )
                .frame(width: 362 * scale, height: 150 * scale)
                .offset(y: 4 * scale)
                .accessibilityLabel("Breastfeeding goal duration")
            } else {
                TimelineDurationWheel(
                    value: $maternityLeaveValue,
                    unit: $maternityLeaveUnit,
                    values: Array(1...52),
                    units: TimelineDurationUnit.allCases,
                    scale: scale,
                    onInteraction: { store.userDidInteract() }
                )
                .frame(width: 362 * scale, height: 150 * scale)
                .offset(y: 4 * scale)
                .accessibilityLabel("Maternity leave duration")
            }
        }
        .frame(width: frame.width * rect.width / 402, height: frame.height * rect.height / 874)
        .clipped()
        .position(
            x: frame.minX + frame.width * rect.midX / 402,
            y: frame.minY + frame.height * rect.midY / 874
        )
    }

    private func topBack(in size: CGSize, destination: TimelineStage) -> some View {
        tapArea(CGRect(x: 8, y: 48, width: 82, height: 82), label: "Previous Timeline screen", in: size) {
            move(to: destination)
        }
    }

    private func exitToPrevious(_ destination: TimelineStage, in size: CGSize) -> some View {
        tapArea(CGRect(x: 326, y: 684, width: 76, height: 94), label: "Previous Timeline screen", in: size) {
            move(to: destination)
        }
    }

    private func goBackFromCurrentStage() {
        switch stage {
        case .home:
            store.showCover(.lactationTimeline)
        case .entryTip:
            move(to: .home)
        case .insights:
            move(to: .entryTip)
        case .privacy:
            move(to: .entryTip)
        case .goal:
            move(to: .privacy)
        case .leave:
            move(to: .goal)
        case .ready:
            move(to: .leave)
        case .result:
            move(to: .ready)
        case .knowledge:
            move(to: .insights)
        case .share:
            move(to: .knowledge)
        case .communityShare:
            move(to: .share)
        case .notification:
            move(to: .insights)
        }
    }

    private func tapArea(
        _ rect: CGRect,
        label: String,
        enabled: Bool = true,
        in size: CGSize,
        action: @escaping () -> Void
    ) -> some View {
        let frame = fittedDesignFrame(in: size)
        return Button {
            store.userDidInteract()
            action()
        } label: {
            Rectangle().fill(Color.clear).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .frame(
            width: frame.width * rect.width / 402,
            height: frame.height * rect.height / 874
        )
        .position(
            x: frame.minX + frame.width * rect.midX / 402,
            y: frame.minY + frame.height * rect.midY / 874
        )
        .accessibilityLabel(label)
    }

    private func move(to nextStage: TimelineStage) {
        store.userDidInteract()
        withAnimation(.easeInOut(duration: 0.18)) {
            stage = nextStage
        }
    }

    private func fittedDesignFrame(in size: CGSize) -> CGRect {
        let designAspect: CGFloat = 402 / 874
        let availableAspect = size.width / size.height
        if availableAspect > designAspect {
            let width = size.height * designAspect
            return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        }
        let height = size.width / designAspect
        return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
    }
}

private struct TimelineFigmaImage: View {
    let assetName: String
    var contentMode: ContentMode = .fit

    var body: some View {
        if let image = FigmaScreenImageLoader.image(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: contentMode)
        } else {
            Color.clear
        }
    }
}

private struct TimelineIntakeChart: View {
    let date: String

    private let plum = Color(red: 0.467, green: 0.020, blue: 0.137)
    private let rose = Color(red: 0.933, green: 0.612, blue: 0.655)
    private let tertiary = Color(red: 0.486, green: 0.435, blue: 0.463)

    var body: some View {
        GeometryReader { proxy in
            let plot = CGRect(x: 28, y: 48, width: max(240, proxy.size.width - 48), height: 150)
            let selectedX = plot.minX + plot.width * 0.32

            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawBands(context: &context, plot: plot)
                    drawGrid(context: &context, plot: plot)

                    let lower = [0.0, 0.3, 0.8, 1.8, 3.2, 5.0, 7.7, 9.0, 8.2]
                    let average = [0.0, 0.5, 1.5, 3.8, 6.2, 9.0, 14.5, 18.0, 16.2]
                    let middle = [0.0, 0.8, 2.0, 5.0, 8.8, 13.0, 17.0, 20.0, 19.0]
                    let upper = [0.0, 1.2, 3.0, 7.0, 11.5, 16.5, 25.5, 28.5, 31.0]

                    context.stroke(smoothPath(lower, in: plot), with: .color(rose.opacity(0.72)), lineWidth: 1.2)
                    context.stroke(smoothPath(middle, in: plot), with: .color(rose.opacity(0.88)), lineWidth: 1.2)
                    context.stroke(smoothPath(upper, in: plot), with: .color(rose), lineWidth: 1.2)
                    context.stroke(smoothPath(average, in: plot), with: .color(plum), lineWidth: 1.8)

                    var slider = Path()
                    slider.move(to: CGPoint(x: selectedX, y: 10))
                    slider.addLine(to: CGPoint(x: selectedX, y: plot.maxY + 2))
                    context.stroke(slider, with: .color(plum), lineWidth: 1.4)
                    context.fill(Path(ellipseIn: CGRect(x: selectedX - 3, y: 7, width: 6, height: 6)), with: .color(plum))

                    drawAxisLabels(context: &context, plot: plot)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Day n (\(date))")
                        .font(.brandMedium(10))
                    Text("Milk Intake 6 oz\nRange 8-10 oz")
                        .font(.brandBody(10))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(plum, in: RoundedRectangle(cornerRadius: 7))
                .position(x: min(selectedX + 52, proxy.size.width - 58), y: 22)
            }
        }
    }

    private func drawBands(context: inout GraphicsContext, plot: CGRect) {
        let bandWidth = plot.width / 9
        for index in 0..<9 {
            let rect = CGRect(x: plot.minX + CGFloat(index) * bandWidth, y: plot.minY, width: bandWidth, height: plot.height)
            let color: Color
            if index == 2 {
                color = Color(red: 1, green: 0.90, blue: 0.91)
            } else {
                color = index.isMultiple(of: 2)
                    ? Color(red: 0.941, green: 0.933, blue: 0.937)
                    : Color(red: 0.976, green: 0.969, blue: 0.961)
            }
            context.fill(Path(rect), with: .color(color))
        }
    }

    private func drawGrid(context: inout GraphicsContext, plot: CGRect) {
        for index in 0...4 {
            let y = plot.minY + CGFloat(index) * plot.height / 4
            var line = Path()
            line.move(to: CGPoint(x: plot.minX, y: y))
            line.addLine(to: CGPoint(x: plot.maxX, y: y))
            context.stroke(line, with: .color(Color.white.opacity(0.85)), lineWidth: 0.7)
        }
    }

    private func drawAxisLabels(context: inout GraphicsContext, plot: CGRect) {
        let yLabels = ["40", "30", "20", "10", "0"]
        drawText("OZ", at: CGPoint(x: 3, y: 8), anchor: .topLeading, context: &context)
        for (index, label) in yLabels.enumerated() {
            let y = plot.minY + CGFloat(index) * plot.height / 4
            drawText(label, at: CGPoint(x: 2, y: y), anchor: .leading, context: &context)
        }

        for index in 0..<9 {
            let x = plot.minX + (CGFloat(index) + 0.5) * plot.width / 9
            drawText("St \(index + 1)", at: CGPoint(x: x, y: plot.maxY + 14), anchor: .center, context: &context)
        }

        drawText("90th", at: CGPoint(x: plot.maxX, y: plot.minY + 7), anchor: .trailing, context: &context)
        drawText("50th", at: CGPoint(x: plot.maxX, y: plot.midY), anchor: .trailing, context: &context)
        drawText("10th", at: CGPoint(x: plot.maxX, y: plot.maxY - 6), anchor: .trailing, context: &context)
    }

    private func drawText(
        _ value: String,
        at point: CGPoint,
        anchor: UnitPoint,
        context: inout GraphicsContext
    ) {
        let text = Text(value)
            .font(.brandBody(8))
            .foregroundStyle(tertiary)
        context.draw(context.resolve(text), at: point, anchor: anchor)
    }

    private func smoothPath(_ values: [Double], in plot: CGRect) -> Path {
        let points = values.enumerated().map { index, value in
            CGPoint(
                x: plot.minX + CGFloat(index) * plot.width / CGFloat(max(1, values.count - 1)),
                y: plot.maxY - CGFloat(value / 40) * plot.height
            )
        }

        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = (previous.x + current.x) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: midpoint, y: previous.y),
                control2: CGPoint(x: midpoint, y: current.y)
            )
        }
        return path
    }
}

private enum TimelineStage: Hashable {
    case home
    case entryTip
    case insights
    case privacy
    case goal
    case leave
    case ready
    case result
    case knowledge
    case share
    case communityShare
    case notification

    var assetName: String {
        switch self {
        case .home: "timeline-home"
        case .entryTip: "timeline-entry"
        case .insights: "timeline-insights"
        case .privacy: "timeline-privacy-1"
        case .goal: "timeline-q1-scroll"
        case .leave: "timeline-q2-scroll"
        case .ready: "timeline-privacy-2"
        case .result: "timeline-personalized-long"
        case .knowledge: "timeline-knowledge"
        case .share: "timeline-share"
        case .communityShare: "timeline-community-share"
        case .notification: "timeline-notification"
        }
    }
}

private enum TimelinePickerMode {
    case goal
    case leave
}

private enum TimelineDurationUnit: Int, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: Int { rawValue }

    var pickerLabel: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        }
    }

    func resultLabel(for value: Int) -> String {
        value == 1 ? pickerLabel.lowercased() : "\(pickerLabel.lowercased())s"
    }
}

/// A two-component UIKit wheel is used instead of two independent SwiftUI
/// pickers so the number and unit share one selection band, matching Figma.
private struct TimelineDurationWheel: UIViewRepresentable {
    @Binding var value: Int
    @Binding var unit: TimelineDurationUnit

    let values: [Int]
    let units: [TimelineDurationUnit]
    let scale: CGFloat
    let onInteraction: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.backgroundColor = .clear
        picker.isOpaque = false
        selectCurrentRows(in: picker, animated: false)
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.parent = self
        selectCurrentRows(in: picker, animated: false)
        picker.reloadAllComponents()

        // UIPickerView occasionally supplies thin separator subviews on older
        // iOS versions. Figma uses a single rounded selection surface instead.
        for subview in picker.subviews where subview.bounds.height <= 1.5 {
            subview.backgroundColor = .clear
        }
    }

    private func selectCurrentRows(in picker: UIPickerView, animated: Bool) {
        if let valueIndex = values.firstIndex(of: value) {
            picker.selectRow(valueIndex, inComponent: 0, animated: animated)
        }
        if let unitIndex = units.firstIndex(of: unit) {
            picker.selectRow(unitIndex, inComponent: 1, animated: animated)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: TimelineDurationWheel

        init(parent: TimelineDurationWheel) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            component == 0 ? parent.values.count : parent.units.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            62 * parent.scale
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            161 * parent.scale
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            let isSelected = row == pickerView.selectedRow(inComponent: component)
            label.textAlignment = .center
            label.font = .systemFont(
                ofSize: 20 * parent.scale,
                weight: isSelected ? .semibold : .regular
            )
            label.textColor = isSelected
                ? UIColor(red: 62 / 255, green: 0, blue: 16 / 255, alpha: 1)
                : UIColor(red: 62 / 255, green: 0, blue: 16 / 255, alpha: 0.22)
            label.text = component == 0
                ? String(parent.values[row])
                : parent.units[row].pickerLabel
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            if component == 0 {
                parent.value = parent.values[row]
            } else {
                parent.unit = parent.units[row]
            }
            parent.onInteraction()
            pickerView.reloadAllComponents()
        }
    }
}
