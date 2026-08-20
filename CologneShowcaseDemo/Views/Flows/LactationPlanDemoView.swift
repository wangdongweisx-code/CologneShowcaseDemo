import Charts
import SwiftUI

/// Raster-backed implementation of the approved Cologne-show flow.
/// The V1.5 7.28 file is used only for interaction rules; every screen remains
/// an approved `plan-*` Figma export from the Cologne demo file.
struct LactationPlanDemoView: View {
    @ObservedObject var store: DemoStore
    let onFinalPageChange: (Bool) -> Void

    @State private var stage: PlanStage = .home
    @State private var homeCardHighlighted = false
    @State private var hasAcceptedPrivacy = false
    @State private var babyAgeMonths = 6
    @State private var pumpingGoal: PumpingGoal = .powerPumping
    @State private var feedsExclusively = true
    @State private var pumpsPerDay = 4
    @State private var nightChoice: Bool? = true
    @State private var prefersSpecificTimes = false
    @State private var preferredTimes: [Date] = []
    @State private var pickerTime = Self.time(hour: 9)
    @State private var editingTimeIndex: Int?
    @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4, 5]
    @State private var generationProgress: CGFloat = 0.1
    @State private var isEditingEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var sessionDuration = 20
    @State private var insightPeriod: InsightPeriod = .day
    @State private var showsInsightTip = true
    @State private var isInsightSummaryVisible = true
    @State private var isOverallExpanded = true
    @State private var expandedRecordIDs: Set<Int> = [0]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if stage == .home, homeCardHighlighted {
                    FigmaScreenView(assetName: "plan-home-2")

                    tapArea(
                        CGRect(x: 16, y: 245, width: 370, height: 370),
                        label: "Highlighted Lactation Plan card",
                        in: proxy.size
                    ) {
                        move(to: .start)
                    }

                    tapArea(
                        CGRect(x: 18, y: 676, width: 366, height: 122),
                        label: "Lactation Training tip",
                        in: proxy.size
                    ) {
                        move(to: .start)
                    }
                } else if stage == .start {
                    nativePlanStartPage
                } else if stage.isQuestionnaire {
                    questionnairePage(in: proxy.size)
                } else if stage == .data {
                    insightPage(in: proxy.size)
                } else if stage.isLongPage {
                    longPage(in: proxy.size)
                } else {
                    FigmaScreenView(assetName: stage.assetName)
                        .id(stage.assetName)

                    regularInteractions(in: proxy.size)

                    if stage.hasBackButton {
                        tapArea(
                            CGRect(x: 8, y: 52, width: 84, height: 90),
                            label: "Previous screen",
                            in: proxy.size,
                            action: goBack
                        )
                    }
                }

                if stage == .firstPlan, isEditingEndDate {
                    endDatePicker(in: proxy.size)
                }

                if stage == .data, showsInsightTip {
                    insightTipOverlay(in: proxy.size)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            onFinalPageChange(stage == .data)
        }
        .onChange(of: stage) { _, newStage in
            onFinalPageChange(newStage == .data)
        }
        .onDisappear {
            onFinalPageChange(false)
        }
        .task(id: stage) {
            switch stage {
            case .generating:
                generationProgress = 0.1
                for value in 2...10 {
                    try? await Task.sleep(for: .milliseconds(240))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        generationProgress = CGFloat(value) / 10
                    }
                }

            case .notification:
                // The push banner remains visible for five seconds, then
                // retracts by moving directly to the next highlighted bubble.
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled, stage == .notification else { return }
                move(to: .schedule)

            default:
                return
            }
        }
    }

    private var nativePlanStartPage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.88),
                    Color(red: 1.0, green: 0.965, blue: 0.97),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.brandInk)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .tint(Color.white.opacity(0.78))
                    .accessibilityLabel("Back to lactation plan home")

                    Spacer()

                    Label("AI Lactation Plan", systemImage: "sparkles")
                        .font(.brandMedium(17, relativeTo: .headline))
                        .foregroundStyle(Color.brandInk)

                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 54)

                ScrollView(.vertical) {
                    VStack(spacing: 16) {
                        FigmaTransparentAssetView(assetName: "plan-start-ip")
                            .frame(width: 150, height: 136)
                            .accessibilityHidden(true)

                        Text("Let’s make an\nAI Lactation plan!")
                            .font(.custom(Font.exposureMinus10Name, size: 30, relativeTo: .title))
                            .foregroundStyle(Color.brandInk)
                            .multilineTextAlignment(.center)

                        Text("Share your goals and routine, we’ll design a personal rhythm that fits your unique breastfeeding journey.")
                            .font(.brandBody(15, relativeTo: .body))
                            .foregroundStyle(Color.brandInk.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Label("30s to Unlock", systemImage: "bolt.fill")
                            .font(.brandMedium(14, relativeTo: .subheadline))
                            .foregroundStyle(Color.brandPlum)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(Color(red: 1.0, green: 0.87, blue: 0.89), in: Capsule())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        LactationBenefitsLoopView()
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 18)
                }
                .scrollIndicators(.hidden)

                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.16)) {
                        hasAcceptedPrivacy.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(hasAcceptedPrivacy ? Color.brandPlum : Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.brandPlum, lineWidth: 1.4)
                                if hasAcceptedPrivacy {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .frame(width: 22, height: 22)

                        Text("I agree to ")
                            .foregroundStyle(Color.brandInk)
                        + Text("Privacy Statement")
                            .foregroundStyle(Color.brandInk)
                            .underline()
                    }
                    .font(.brandBody(15, relativeTo: .body))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    store.userDidInteract()
                    move(to: .information)
                } label: {
                    Text("Get Started")
                        .font(.brandSemiBold(17, relativeTo: .headline))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.brandPlum, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!hasAcceptedPrivacy)
                .opacity(hasAcceptedPrivacy ? 1 : 0.42)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    @ViewBuilder
    private func regularInteractions(in size: CGSize) -> some View {
        switch stage {
        case .home, .data:
            EmptyView()

        case .start:
            privacySelection(in: size)
            tapArea(CGRect(x: 20, y: 710, width: 362, height: 58), label: "Agree to Privacy Statement", in: size) {
                withAnimation(.easeInOut(duration: 0.16)) {
                    hasAcceptedPrivacy.toggle()
                }
            }
            tapArea(
                CGRect(x: 20, y: 764, width: 362, height: 54),
                label: "Get Started",
                enabled: hasAcceptedPrivacy,
                in: size
            ) {
                move(to: .information)
            }

        case .information:
            ageValue(in: size)
            pumpingGoalRadios(in: size)
            exactNextButton(in: size)
            tapArea(CGRect(x: 18, y: 407, width: 86, height: 76), label: "Decrease baby age", enabled: babyAgeMonths > 1, in: size) {
                babyAgeMonths -= 1
            }
            tapArea(CGRect(x: 300, y: 407, width: 84, height: 76), label: "Increase baby age", enabled: babyAgeMonths < 24, in: size) {
                babyAgeMonths += 1
            }
            tapArea(CGRect(x: 16, y: 512, width: 370, height: 84), label: "Maintain Milk Supply", in: size) {
                pumpingGoal = .maintainSupply
            }
            tapArea(CGRect(x: 16, y: 605, width: 370, height: 84), label: "Power Pumping", in: size) {
                pumpingGoal = .powerPumping
            }
            tapArea(CGRect(x: 16, y: 697, width: 370, height: 84), label: "Weaning", in: size) {
                pumpingGoal = .weaning
            }
            tapArea(CGRect(x: 20, y: 758, width: 362, height: 65), label: "Next", in: size) {
                move(to: .feedingChoice)
            }

        case .feedingChoice:
            feedingChoiceRadios(in: size)
            tapArea(CGRect(x: 16, y: 414, width: 370, height: 82), label: "Exclusively Pumping", in: size) {
                feedsExclusively = true
            }
            tapArea(CGRect(x: 16, y: 504, width: 370, height: 82), label: "Nursing and Pumping", in: size) {
                feedsExclusively = false
            }
            tapArea(CGRect(x: 20, y: 754, width: 362, height: 78), label: "Next", in: size) {
                move(to: .feedingCount)
            }

        case .feedingCount:
            countValue(in: size)
            tapArea(CGRect(x: 32, y: 526, width: 82, height: 62), label: "Decrease pumps per day", enabled: pumpsPerDay > 1, in: size) {
                pumpsPerDay -= 1
            }
            tapArea(CGRect(x: 290, y: 526, width: 92, height: 62), label: "Increase pumps per day", enabled: pumpsPerDay < 24, in: size) {
                pumpsPerDay += 1
            }
            tapArea(CGRect(x: 20, y: 754, width: 362, height: 78), label: "Next", in: size) {
                move(to: .nightChoice)
            }

        case .nightChoice:
            choiceRadios(selection: nightChoice, in: size)
            tapArea(CGRect(x: 16, y: 432, width: 181, height: 78), label: "Yes, pump at night", in: size) {
                withAnimation(.easeInOut(duration: 0.16)) { nightChoice = true }
            }
            tapArea(CGRect(x: 205, y: 432, width: 181, height: 78), label: "No night pumping", in: size) {
                withAnimation(.easeInOut(duration: 0.16)) { nightChoice = false }
            }
            disabledButtonCover(isDisabled: nightChoice == nil, in: size)
            tapArea(CGRect(x: 20, y: 754, width: 362, height: 78), label: "Next", enabled: nightChoice != nil, in: size) {
                move(to: .timePreference)
            }

        case .timePreference:
            preferenceRadios(in: size)
            tapArea(CGRect(x: 16, y: 405, width: 181, height: 76), label: "Use preferred pumping times", in: size) {
                withAnimation(.easeInOut(duration: 0.16)) { prefersSpecificTimes = true }
            }
            tapArea(CGRect(x: 205, y: 405, width: 181, height: 76), label: "Do not use preferred pumping times", in: size) {
                withAnimation(.easeInOut(duration: 0.16)) { prefersSpecificTimes = false }
            }
            tapArea(CGRect(x: 16, y: 514, width: 370, height: 72), label: "Choose preferred pumping time", enabled: prefersSpecificTimes, in: size) {
                openTimePicker(editing: preferredTimes.isEmpty ? nil : 0)
            }
            tapArea(CGRect(x: 16, y: 586, width: 370, height: 72), label: "Add preferred pumping time", enabled: prefersSpecificTimes, in: size) {
                openTimePicker(editing: nil)
            }
            tapArea(CGRect(x: 20, y: 754, width: 362, height: 78), label: "Next", in: size) {
                if prefersSpecificTimes {
                    if preferredTimes.isEmpty {
                        openTimePicker(editing: nil)
                    } else {
                        move(to: .confirmation)
                    }
                } else {
                    move(to: .confirmation)
                }
            }

        case .timePicker:
            tapArea(CGRect(x: 0, y: 572, width: 120, height: 72), label: "Cancel time selection", in: size) {
                move(to: preferredTimes.isEmpty ? .timePreference : .timeList)
            }
            tapArea(CGRect(x: 48, y: 640, width: 306, height: 190), label: "Select 8:00 PM", in: size) {
                // Preserve the exact Figma wheel. The exhibition interaction
                // chooses the highlighted value shown in that approved frame.
                pickerTime = Self.time(hour: 20)
            }
            tapArea(CGRect(x: 300, y: 572, width: 102, height: 72), label: "Done", in: size) {
                savePickerTime()
            }

        case .timeList:
            timeList(in: size)
            tapArea(CGRect(x: 20, y: 754, width: 362, height: 78), label: "Next", enabled: !preferredTimes.isEmpty, in: size) {
                move(to: .confirmation)
            }

        case .confirmation:
            dayChips(in: size)
            tapArea(CGRect(x: 20, y: 754, width: 362, height: 78), label: "Generate", enabled: !selectedDays.isEmpty, in: size) {
                move(to: .generating)
            }

        case .generating:
            generationProgressView(in: size)
            generationTips(in: size)
            if generationProgress < 1 {
                disabledGenerationButton(in: size)
                    .transition(.opacity)
            }
            tapArea(
                CGRect(x: 20, y: 754, width: 362, height: 78),
                label: "Got It",
                enabled: generationProgress >= 1,
                in: size
            ) {
                guard generationProgress >= 1 else { return }
                move(to: .firstPlan)
            }

        case .firstPlan:
            tapArea(CGRect(x: 176, y: 218, width: 125, height: 56), label: "Edit plan end date", in: size) {
                store.userDidInteract()
                withAnimation(.easeInOut(duration: 0.2)) { isEditingEndDate = true }
            }
            tapArea(CGRect(x: 20, y: 760, width: 362, height: 76), label: "Confirm plan", in: size) {
                move(to: .notification)
            }

        case .notification:
            EmptyView()

        case .schedule:
            tapArea(CGRect(x: 18, y: 628, width: 366, height: 126), label: "Daily Summary tip", in: size) {
                move(to: .data)
            }
            tapArea(CGRect(x: 192, y: 660, width: 120, height: 170), label: "Open pumping summary", in: size) {
                move(to: .data)
            }

        case .share:
            tapArea(CGRect(x: 8, y: 630, width: 82, height: 92), label: "Close sharing", in: size) {
                move(to: .data)
            }
        }
    }

    // MARK: - Native questionnaire

    @ViewBuilder
    private func questionnairePage(in size: CGSize) -> some View {
        if stage == .timePicker {
            ZStack(alignment: .bottom) {
                questionnaireScaffold(for: .timePreference)
                    .allowsHitTesting(false)

                Color.black.opacity(0.30)
                    .ignoresSafeArea()

                nativeTimePickerSheet
            }
        } else {
            questionnaireScaffold(for: stage)
        }
    }

    private func questionnaireScaffold(for contentStage: PlanStage) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.86, blue: 0.89),
                    Color(red: 1.00, green: 0.97, blue: 0.97),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                nativeQuestionnaireHeader

                ScrollView(.vertical) {
                    questionnaireContent(for: contentStage)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .scrollIndicators(.visible)

                questionnairePrimaryButton(for: contentStage)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0), Color.white.opacity(0.96)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        }
    }

    private var nativeQuestionnaireHeader: some View {
        HStack {
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(Color.white.opacity(0.74))
            .accessibilityLabel("Previous questionnaire page")

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                Text("AI Lactation Plan")
                    .font(.brandMedium(16, relativeTo: .headline))
            }
            .foregroundStyle(Color.brandInk)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func questionnaireContent(for contentStage: PlanStage) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            questionnaireHero(for: contentStage)

            switch contentStage {
            case .information:
                planSectionLabel("Baby’s age")
                nativeCounterRow(value: "\(babyAgeMonths) month\(babyAgeMonths == 1 ? "" : "s")") {
                    if babyAgeMonths > 1 { babyAgeMonths -= 1 }
                } increment: {
                    if babyAgeMonths < 24 { babyAgeMonths += 1 }
                }

                planSectionLabel("Current pumping goal")
                nativeChoiceCard(
                    title: "Maintain Milk Supply",
                    subtitle: "To keep my current milk output steady",
                    selected: pumpingGoal == .maintainSupply
                ) { pumpingGoal = .maintainSupply }
                nativeChoiceCard(
                    title: "Power Pumping",
                    subtitle: "To boost my milk output",
                    selected: pumpingGoal == .powerPumping
                ) { pumpingGoal = .powerPumping }
                nativeChoiceCard(
                    title: "Weaning",
                    subtitle: "To transition away from pumping",
                    selected: pumpingGoal == .weaning
                ) { pumpingGoal = .weaning }

            case .feedingChoice:
                planSectionLabel("Choose from")
                nativeChoiceCard(
                    title: "Exclusively Pumping (EP)",
                    subtitle: "Pump and bottle-feed without direct breastfeeding.",
                    selected: feedsExclusively
                ) { feedsExclusively = true }
                nativeChoiceCard(
                    title: "Nursing & Pumping",
                    subtitle: "Breastfeed directly and pump milk throughout the day.",
                    selected: !feedsExclusively
                ) { feedsExclusively = false }

            case .feedingCount:
                planSectionLabel("Choose from")
                VStack(alignment: .leading, spacing: 14) {
                    nativeChoiceCard(
                        title: "Exclusively Pumping (EP)",
                        subtitle: "Pump and bottle-feed without direct breastfeeding.",
                        selected: feedsExclusively
                    ) { feedsExclusively = true }

                    if feedsExclusively {
                        planSectionLabel("Enter pumps per day")
                        nativeCounterRow(value: "\(pumpsPerDay)") {
                            if pumpsPerDay > 1 { pumpsPerDay -= 1 }
                        } increment: {
                            if pumpsPerDay < 24 { pumpsPerDay += 1 }
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.38), in: RoundedRectangle(cornerRadius: 24))

                nativeChoiceCard(
                    title: "Nursing & Pumping",
                    subtitle: "Breastfeed directly and pump milk throughout the day.",
                    selected: !feedsExclusively
                ) { feedsExclusively = false }

            case .nightChoice:
                planSectionLabel("Choose from")
                nativeYesNoSelection(
                    yesSelected: nightChoice == true,
                    noSelected: nightChoice == false,
                    yesAction: { nightChoice = true },
                    noAction: { nightChoice = false }
                )

            case .timePreference:
                planSectionLabel("Choose from")
                nativeYesNoSelection(
                    yesSelected: prefersSpecificTimes,
                    noSelected: !prefersSpecificTimes,
                    yesAction: { prefersSpecificTimes = true },
                    noAction: { prefersSpecificTimes = false }
                )

                if prefersSpecificTimes {
                    preferredTimeRows
                }

            case .timeList:
                planSectionLabel("Choose from")
                nativeYesNoSelection(
                    yesSelected: true,
                    noSelected: false,
                    yesAction: { prefersSpecificTimes = true },
                    noAction: {
                        prefersSpecificTimes = false
                        preferredTimes.removeAll()
                        move(to: .confirmation)
                    }
                )
                preferredTimeRows

            case .confirmation:
                confirmationSettings

            default:
                EmptyView()
            }
        }
    }

    private func questionnaireHero(for contentStage: PlanStage) -> some View {
        let step = questionnaireStep(for: contentStage)
        let title = questionnaireTitle(for: contentStage)

        return VStack(spacing: 6) {
            FigmaTransparentAssetView(
                assetName: contentStage == .confirmation ? "plan-confirm-ip" : "plan-info-ip"
            )
            .frame(width: contentStage == .confirmation ? 126 : 92,
                   height: contentStage == .confirmation ? 126 : 108)

            if contentStage != .confirmation {
                HStack(spacing: 1) {
                    Text("\(step)")
                        .foregroundStyle(Color.brandInk)
                    Text("/4")
                        .foregroundStyle(Color.brandInk.opacity(0.26))
                }
                .font(.custom(Font.exposureMinus10Name, size: 24, relativeTo: .title2))
            }

            Text(title)
                .font(.custom(Font.exposureMinus10Name, size: 25, relativeTo: .title2))
                .foregroundStyle(Color.brandInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if contentStage == .nightChoice {
                Text("0:00–6:00")
                    .font(.brandBody(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.brandInk.opacity(0.72))
            } else if contentStage == .confirmation {
                Text("You can adjust it before generating the schedules.")
                    .font(.brandBody(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.brandInk.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    private func questionnaireStep(for contentStage: PlanStage) -> Int {
        switch contentStage {
        case .information: 1
        case .feedingChoice, .feedingCount: 2
        case .nightChoice: 3
        case .timePreference, .timeList, .timePicker: 4
        default: 4
        }
    }

    private func questionnaireTitle(for contentStage: PlanStage) -> String {
        switch contentStage {
        case .information: "Basic Information"
        case .feedingChoice, .feedingCount: "How do you feed your baby?"
        case .nightChoice: "Do you pump at night?"
        case .timePreference, .timeList, .timePicker: "Preferred time for pumping"
        case .confirmation: "Great! Here’s the setting\nfor your plan."
        default: "AI Lactation Plan"
        }
    }

    private func planSectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.brandMedium(14, relativeTo: .subheadline))
            .foregroundStyle(Color.brandInk)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nativeChoiceCard(
        title: String,
        subtitle: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.userDidInteract()
            withAnimation(.easeInOut(duration: 0.16)) { action() }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.brandMedium(16, relativeTo: .body))
                        .foregroundStyle(selected ? Color.brandPlum : Color.brandInk)
                    Text(subtitle)
                        .font(.brandBody(13, relativeTo: .footnote))
                        .foregroundStyle(Color.brandInk.opacity(0.42))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                nativeRadio(selected: selected)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
            .background(
                selected ? Color(red: 1.0, green: 0.94, blue: 0.95) : Color.white,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func nativeRadio(selected: Bool) -> some View {
        Circle()
            .fill(selected ? Color.brandPlum : Color.white)
            .overlay {
                Circle().stroke(selected ? Color.brandPlum : Color.black.opacity(0.12), lineWidth: 1)
                if selected {
                    Circle().fill(Color.white).padding(7)
                }
            }
            .frame(width: 24, height: 24)
    }

    private func nativeCounterRow(
        value: String,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Button {
                store.userDidInteract()
                decrement()
            } label: {
                Image(systemName: "minus")
                    .frame(width: 88, height: 58)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text(value)
                .font(.brandSemiBold(16, relativeTo: .body))
                .foregroundStyle(Color.brandInk)
            Spacer()

            Button {
                store.userDidInteract()
                increment()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 88, height: 58)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.brandInk)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color.white, in: Capsule())
    }

    private func nativeYesNoSelection(
        yesSelected: Bool,
        noSelected: Bool,
        yesAction: @escaping () -> Void,
        noAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            nativeYesNoButton("Yes", selected: yesSelected, action: yesAction)
            nativeYesNoButton("No", selected: noSelected, action: noAction)
        }
    }

    private func nativeYesNoButton(
        _ label: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.userDidInteract()
            withAnimation(.easeInOut(duration: 0.16)) { action() }
        } label: {
            HStack {
                Text(label)
                    .font(.brandMedium(14, relativeTo: .subheadline))
                Spacer()
                nativeRadio(selected: selected)
            }
            .foregroundStyle(selected ? Color.brandPlum : Color.brandInk)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                selected ? Color(red: 1.0, green: 0.94, blue: 0.95) : Color.white,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    private var preferredTimeRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            planSectionLabel("Your preferred time")

            if preferredTimes.isEmpty {
                Button {
                    openTimePicker(editing: nil)
                } label: {
                    HStack {
                        Image(systemName: "clock")
                        Text("Choose a pumping time")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.brandMedium(15, relativeTo: .body))
                    .foregroundStyle(Color.brandInk)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                ForEach(Array(preferredTimes.enumerated()), id: \.offset) { index, time in
                    HStack {
                        Button {
                            openTimePicker(editing: index)
                        } label: {
                            Text(timeRange(start: time))
                                .font(.brandSemiBold(15, relativeTo: .body))
                                .foregroundStyle(Color.brandInk)
                                .frame(maxWidth: .infinity, minHeight: 58)
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.userDidInteract()
                            preferredTimes.remove(at: index)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 6)
                    .background(Color.white, in: Capsule())
                }
            }

            Button {
                if preferredTimes.count < 2 {
                    openTimePicker(editing: nil)
                }
            } label: {
                Label("Add more", systemImage: "plus")
                    .font(.brandMedium(15, relativeTo: .body))
                    .foregroundStyle(Color.brandPlum)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Capsule().stroke(Color.brandInk.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(preferredTimes.count >= 2)
        }
    }

    private var confirmationSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            planSectionLabel("Frequency")
            nativeCounterRow(value: "\(pumpsPerDay) times per day") {
                if pumpsPerDay > 1 { pumpsPerDay -= 1 }
            } increment: {
                if pumpsPerDay < 12 { pumpsPerDay += 1 }
            }

            planSectionLabel("Duration")
            nativeCounterRow(value: "\(sessionDuration) min per time") {
                sessionDuration = max(10, sessionDuration - 5)
            } increment: {
                sessionDuration = min(60, sessionDuration + 5)
            }

            planSectionLabel("Apply to")
            let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
                ForEach(dayLabels.indices, id: \.self) { index in
                    Button {
                        store.userDidInteract()
                        if selectedDays.contains(index) {
                            selectedDays.remove(index)
                        } else {
                            selectedDays.insert(index)
                        }
                    } label: {
                        Text(dayLabels[index])
                            .font(.brandMedium(13, relativeTo: .footnote))
                            .foregroundStyle(selectedDays.contains(index) ? Color.brandPlum : Color.brandInk)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                selectedDays.contains(index)
                                    ? Color(red: 1.0, green: 0.86, blue: 0.89)
                                    : Color.white,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func questionnairePrimaryButton(for contentStage: PlanStage) -> some View {
        Button {
            store.userDidInteract()
            switch contentStage {
            case .information:
                move(to: .feedingChoice)
            case .feedingChoice:
                move(to: .feedingCount)
            case .feedingCount:
                move(to: .nightChoice)
            case .nightChoice:
                move(to: .timePreference)
            case .timePreference:
                if prefersSpecificTimes {
                    if preferredTimes.isEmpty {
                        openTimePicker(editing: nil)
                    } else {
                        move(to: .timeList)
                    }
                } else {
                    move(to: .confirmation)
                }
            case .timeList:
                move(to: .confirmation)
            case .confirmation:
                move(to: .generating)
            default:
                break
            }
        } label: {
            Text(contentStage == .confirmation ? "Generate" : "Next")
                .font(.brandSemiBold(16, relativeTo: .headline))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.brandPlum, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(contentStage == .confirmation && selectedDays.isEmpty)
        .opacity(contentStage == .confirmation && selectedDays.isEmpty ? 0.45 : 1)
    }

    private var nativeTimePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    move(to: preferredTimes.isEmpty ? .timePreference : .timeList)
                }
                .foregroundStyle(Color.brandInk)

                Spacer()

                Button("Done") {
                    savePickerTime()
                }
                .foregroundStyle(Color.brandPlum)
            }
            .font(.brandMedium(17, relativeTo: .body))
            .padding(.horizontal, 24)
            .padding(.top, 18)

            DatePicker("", selection: $pickerTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.wheel)
                .colorScheme(.light)
                .frame(maxWidth: .infinity, minHeight: 220)
                .clipped()
                .padding(.bottom, 24)
        }
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Select preferred pumping time")
    }

    // MARK: - Native insights

    private func insightPage(in size: CGSize) -> some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 16) {
                insightHeader
                insightPeriodSelector
                insightChartCard

                if isInsightSummaryVisible {
                    insightSummaryCard
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                insightOverallSection
                insightRecordsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 54)
            .padding(.bottom, 96)
        }
        .scrollIndicators(.visible)
        .background(Color.white)
    }

    private func insightTipOverlay(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402

        return ZStack {
            Color.black.opacity(0.28)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)

            Button {
                store.userDidInteract()
                withAnimation(.easeInOut(duration: 0.18)) {
                    showsInsightTip = false
                }
            } label: {
                VStack(alignment: .leading, spacing: 12 * scale) {
                    Label("Demo Tips: AI Insights", systemImage: "lightbulb.min.fill")
                        .font(.brandSemiBold(17 * scale, relativeTo: .headline))
                        .foregroundStyle(Color.brandPlum)

                    Text("Review your pumping progress and personalized AI insights here.")
                        .font(.brandBody(15 * scale, relativeTo: .body))
                        .foregroundStyle(Color.brandInk)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20 * scale)
                .frame(width: 354 * scale, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
                .overlay(alignment: .bottom) {
                    InsightTipTriangle()
                        .fill(Color.white)
                        .frame(width: 42 * scale, height: 24 * scale)
                        .offset(y: 22 * scale)
                }
                .shadow(color: .black.opacity(0.10), radius: 18 * scale, y: 6 * scale)
            }
            .buttonStyle(.plain)
            .position(
                x: frame.midX,
                y: frame.minY + frame.height * 430 / 874
            )
            .accessibilityLabel("AI Insights tip. Tap to continue")
        }
    }

    private var insightHeader: some View {
        HStack {
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(Color.white)

            Spacer()
            Text("Breast Pump Record")
                .font(.brandMedium(17, relativeTo: .headline))
                .foregroundStyle(Color.brandInk)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var insightPeriodSelector: some View {
        HStack(spacing: 0) {
            ForEach(InsightPeriod.allCases) { period in
                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.18)) { insightPeriod = period }
                } label: {
                    Text(period.shortLabel)
                        .font(.brandMedium(15, relativeTo: .body))
                        .foregroundStyle(insightPeriod == period ? Color.brandPlum : Color.brandInk.opacity(0.52))
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(insightPeriod == period ? Color.white : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(red: 0.97, green: 0.96, blue: 0.96), in: Capsule())
    }

    private var insightChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Milk Output")
                .font(.brandBody(14, relativeTo: .subheadline))
                .foregroundStyle(Color.brandInk)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(insightPeriod.output)")
                    .font(.custom(Font.exposureMinus10Name, size: 42, relativeTo: .largeTitle))
                Text(insightPeriod.unit)
                    .font(.brandMedium(14, relativeTo: .subheadline))
            }
            .foregroundStyle(Color.brandInk)

            Chart(insightPeriod.points) { point in
                LineMark(
                    x: .value("Hour", point.hour),
                    y: .value("Output", point.output)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.brandInk)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Hour", point.hour),
                    y: .value("Output", point.output)
                )
                .foregroundStyle(Color.brandInk)
                .symbolSize(26)
            }
            .chartXScale(domain: 0...12)
            .chartYScale(domain: 0...40)
            .chartXAxis {
                AxisMarks(values: [0, 2, 4, 6, 8, 10, 12]) { value in
                    AxisGridLine().foregroundStyle(Color.brandInk.opacity(0.10))
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(String(format: "%02d:00", hour))
                                .font(.brandBody(10, relativeTo: .caption2))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 10, 20, 30, 40])
            }
            .frame(height: 220)
        }
        .padding(4)
    }

    private var insightSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.brandPlum)
                Spacer()
                Button {
                    move(to: .share)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.brandMedium(13, relativeTo: .footnote))
                        .foregroundStyle(Color.brandInk)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 38)
                        .background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isInsightSummaryVisible = false }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.brandInk)
                        .frame(width: 38, height: 38)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Text("Today’s Accomplishment")
                .font(.brandSemiBold(16, relativeTo: .headline))
                .foregroundStyle(Color.brandInk)

            Text("You’ve completed 5 of 5 pumping sessions today and expressed 800 ml so far. You’re doing an amazing job. Take a moment to rest, recharge, and celebrate today’s progress.")
                .font(.brandBody(14, relativeTo: .body))
                .foregroundStyle(Color.brandInk.opacity(0.52))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 52) {
                insightMetric("Output", value: "650", unit: "ml")
                insightMetric("Sessions", value: "5", unit: "")
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.86, blue: 0.89), Color(red: 1.0, green: 0.96, blue: 0.97)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(Color.brandPlum.opacity(0.10), lineWidth: 1)
        }
    }

    private func insightMetric(_ label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.brandBody(13, relativeTo: .footnote))
                .foregroundStyle(Color.brandInk.opacity(0.48))
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.custom(Font.exposureMinus10Name, size: 32, relativeTo: .title))
                Text(unit)
                    .font(.brandMedium(13, relativeTo: .footnote))
            }
            .foregroundStyle(Color.brandInk)
        }
    }

    private var insightOverallSection: some View {
        DisclosureGroup(isExpanded: $isOverallExpanded) {
            VStack(spacing: 12) {
                insightOverallRow("Average per session", value: "6.1 oz")
                insightOverallRow("Best day", value: "Jun 23")
                insightOverallRow("Plan completion", value: "100%")
            }
            .padding(.top, 14)
        } label: {
            HStack {
                Text("Overall")
                    .font(.brandSemiBold(15, relativeTo: .headline))
                Spacer()
                Text("Total 305 oz")
                    .font(.brandBody(15, relativeTo: .body))
            }
            .foregroundStyle(Color.brandInk)
        }
        .tint(Color.brandInk)
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.brandInk.opacity(0.08)) }
    }

    private func insightOverallRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.brandInk.opacity(0.50))
            Spacer()
            Text(value)
                .foregroundStyle(Color.brandInk)
        }
        .font(.brandBody(14, relativeTo: .body))
    }

    private var insightRecordsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Records")
                .font(.brandSemiBold(16, relativeTo: .headline))
                .foregroundStyle(Color.brandInk)
                .padding(.bottom, 8)

            ForEach(InsightRecord.samples) { record in
                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        if expandedRecordIDs.contains(record.id) {
                            expandedRecordIDs.remove(record.id)
                        } else {
                            expandedRecordIDs.insert(record.id)
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(record.date)
                                .font(.brandSemiBold(14, relativeTo: .body))
                            Spacer()
                            Image(systemName: expandedRecordIDs.contains(record.id) ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }

                        if expandedRecordIDs.contains(record.id) {
                            HStack {
                                Text("Duration")
                                    .foregroundStyle(Color.brandInk.opacity(0.42))
                                Spacer()
                                Text(record.duration)
                            }
                            HStack {
                                Text("Left: \(record.left)  |  Right: \(record.right)")
                                    .foregroundStyle(Color.brandInk.opacity(0.42))
                                Spacer()
                                Text("Total \(record.total)")
                            }
                            .font(.brandBody(13, relativeTo: .footnote))
                        }
                    }
                    .foregroundStyle(Color.brandInk)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if record.id != InsightRecord.samples.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.brandInk.opacity(0.08)) }
    }

    @ViewBuilder
    private func longPage(in size: CGSize) -> some View {
        let contentWidth = min(size.width, size.height * 402 / 874)
        let contentHeight = contentWidth * stage.designHeight / 402
        let designFrame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)

        ScrollViewReader { reader in
            ScrollView(.vertical) {
                ZStack {
                    FigmaScreenView(assetName: stage.assetName)
                        .id(stage.assetName)

                    if stage == .home {
                        Color.clear
                            .frame(width: 1, height: 1)
                            .position(
                                x: designFrame.midX,
                                y: designFrame.height * 970 / stage.designHeight
                            )
                            .id("lactation-plan-card")

                        longTapArea(
                            CGRect(x: 14, y: 785, width: 374, height: 440),
                            label: "Add Lactation Plan",
                            designFrame: designFrame
                        ) {
                            move(to: .start)
                        }
                    } else {
                        longTapArea(
                            CGRect(x: 232, y: 516, width: 116, height: 104),
                            label: "Share accomplishment",
                            designFrame: designFrame
                        ) {
                            move(to: .share)
                        }
                        longTapArea(
                            CGRect(x: 8, y: 48, width: 84, height: 104),
                            label: "Previous screen",
                            designFrame: designFrame,
                            action: goBack
                        )
                    }
                }
                .frame(width: contentWidth, height: contentHeight)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.visible)
            .background(Color.brandCanvas)
            .task(id: stage) {
                guard stage == .home else { return }
                homeCardHighlighted = false
                try? await Task.sleep(for: .milliseconds(450))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 1.05)) {
                    reader.scrollTo("lactation-plan-card", anchor: .center)
                }
                try? await Task.sleep(for: .milliseconds(1150))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    homeCardHighlighted = true
                }
            }
        }
    }

    private func privacySelection(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let rect = CGRect(x: 20, y: 730, width: 362, height: 18)
        return Group {
            if
                hasAcceptedPrivacy,
                let image = FigmaScreenImageLoader.image(named: "privacy-selection-checked")
            {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(
                        width: frame.width * 362 / 402,
                        height: frame.height * 58 / 874
                    )
                    .frame(
                        width: frame.width * rect.width / 402,
                        height: frame.height * rect.height / 874
                    )
                    .clipped()
                    .position(
                        x: frame.minX + frame.width * rect.midX / 402,
                        y: frame.minY + frame.height * rect.midY / 874
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private func pumpingGoalRadios(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return ZStack {
            radio(selected: pumpingGoal == .maintainSupply, center: CGPoint(x: 358, y: 552), frame: frame)
            radio(selected: pumpingGoal == .powerPumping, center: CGPoint(x: 358, y: 645), frame: frame)
            radio(selected: pumpingGoal == .weaning, center: CGPoint(x: 358, y: 739), frame: frame)
        }
        .allowsHitTesting(false)
    }

    private func feedingChoiceRadios(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return ZStack {
            radio(selected: feedsExclusively, center: CGPoint(x: 358, y: 442), frame: frame)
            radio(selected: !feedsExclusively, center: CGPoint(x: 358, y: 533), frame: frame)
        }
        .allowsHitTesting(false)
    }

    /// The Cologne export for Basic Information omitted the pinned CTA. Reuse
    /// the exact approved CTA pixels from the adjacent questionnaire frame.
    private func exactNextButton(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let rect = CGRect(x: 20, y: 764, width: 362, height: 53)
        return FigmaAssetCropView(assetName: "plan-feed-choice", cropRect: rect)
            .frame(
                width: frame.width * rect.width / 402,
                height: frame.height * rect.height / 874
            )
            .position(
                x: frame.minX + frame.width * rect.midX / 402,
                y: frame.minY + frame.height * rect.midY / 874
            )
            .allowsHitTesting(false)
    }

    private func ageValue(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return Text("\(babyAgeMonths) month\(babyAgeMonths == 1 ? "" : "s")")
            .font(.system(size: max(13, frame.width * 16 / 402), weight: .semibold))
            .foregroundStyle(Color(red: 0.14, green: 0.05, blue: 0.10))
            .padding(.horizontal, 8)
            .background(Color.white)
            .position(
                x: frame.minX + frame.width * 201 / 402,
                y: frame.minY + frame.height * 442 / 874
            )
            .allowsHitTesting(false)
    }

    private func countValue(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return Text("\(pumpsPerDay)")
            .font(.system(size: max(13, frame.width * 16 / 402), weight: .semibold))
            .foregroundStyle(Color(red: 0.14, green: 0.05, blue: 0.10))
            .frame(width: frame.width * 48 / 402, height: frame.height * 34 / 874)
            .background(Color.white)
            .position(
                x: frame.minX + frame.width * 205 / 402,
                y: frame.minY + frame.height * 556 / 874
            )
            .allowsHitTesting(false)
    }

    private func choiceRadios(selection: Bool?, in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return ZStack {
            radio(selected: selection == true, center: CGPoint(x: 169, y: 471), frame: frame)
            radio(selected: selection == false, center: CGPoint(x: 358, y: 471), frame: frame)
        }
        .allowsHitTesting(false)
    }

    private func preferenceRadios(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return ZStack {
            radio(selected: prefersSpecificTimes, center: CGPoint(x: 169, y: 443), frame: frame)
            radio(selected: !prefersSpecificTimes, center: CGPoint(x: 358, y: 443), frame: frame)
        }
        .allowsHitTesting(false)
    }

    private func radio(selected: Bool, center: CGPoint, frame: CGRect) -> some View {
        Circle()
            .fill(selected ? Color.brandPlum : Color.white)
            .overlay {
                Circle().stroke(selected ? Color.brandPlum : Color.black.opacity(0.13), lineWidth: 1)
                if selected {
                    Circle()
                        .fill(Color.white)
                        .padding(frame.width * 7 / 402)
                }
            }
            .frame(width: frame.width * 24 / 402, height: frame.width * 24 / 402)
            .position(
                x: frame.minX + frame.width * center.x / 402,
                y: frame.minY + frame.height * center.y / 874
            )
    }

    private func disabledButtonCover(isDisabled: Bool, in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return Group {
            if isDisabled {
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: frame.width * 362 / 402, height: frame.height * 58 / 874)
                    .position(
                        x: frame.minX + frame.width * 201 / 402,
                        y: frame.minY + frame.height * 793 / 874
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private func timeList(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402
        let backgroundRect = CGRect(x: 0, y: 488, width: 402, height: 246)

        return ZStack {
            Rectangle()
                .fill(Color(red: 249 / 255, green: 247 / 255, blue: 245 / 255))
                .frame(width: frame.width, height: frame.height * backgroundRect.height / 874)
                .position(
                    x: frame.midX,
                    y: frame.minY + frame.height * backgroundRect.midY / 874
                )

            Text("Your preferred time")
                .font(.system(size: 14 * scale, weight: .medium))
                .foregroundStyle(Color(red: 0.14, green: 0.05, blue: 0.10))
                .position(
                    x: frame.minX + 77 * scale,
                    y: frame.minY + frame.height * 505 / 874
                )

            ForEach(Array(preferredTimes.enumerated()), id: \.offset) { index, time in
                let rowRect = CGRect(x: 16, y: 524 + CGFloat(index) * 66, width: 370, height: 56)

                Capsule()
                    .fill(Color.white)
                    .frame(width: rowRect.width * scale, height: rowRect.height * frame.height / 874)
                    .position(
                        x: frame.minX + rowRect.midX * scale,
                        y: frame.minY + frame.height * rowRect.midY / 874
                    )

                Text(timeRange(start: time))
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .foregroundStyle(Color(red: 0.14, green: 0.05, blue: 0.10))
                    .position(
                        x: frame.minX + frame.width * 201 / 402,
                        y: frame.minY + frame.height * rowRect.midY / 874
                    )

                Button {
                    openTimePicker(editing: index)
                } label: {
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: (rowRect.width - 52) * scale, height: rowRect.height * frame.height / 874)
                .position(
                    x: frame.minX + (rowRect.minX + (rowRect.width - 52) / 2) * scale,
                    y: frame.minY + frame.height * rowRect.midY / 874
                )

                Button {
                    store.userDidInteract()
                    _ = withAnimation(.easeInOut(duration: 0.18)) {
                        preferredTimes.remove(at: index)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13 * scale, weight: .regular))
                        .foregroundStyle(Color(red: 0.14, green: 0.05, blue: 0.10))
                        .frame(width: 52 * scale, height: rowRect.height * frame.height / 874)
                }
                .buttonStyle(.plain)
                .position(
                    x: frame.minX + (rowRect.maxX - 26) * scale,
                    y: frame.minY + frame.height * rowRect.midY / 874
                )
            }

            let addY = 524 + CGFloat(preferredTimes.count) * 66
            Button {
                if preferredTimes.count < 2 {
                    openTimePicker(editing: nil)
                } else {
                    store.userDidInteract()
                }
            } label: {
                Label("Add more", systemImage: "plus")
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundStyle(Color.brandPlum)
                    .frame(width: 370 * scale, height: frame.height * 56 / 874)
                    .background {
                        Capsule().stroke(Color.black.opacity(0.12), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .position(
                x: frame.minX + 201 * scale,
                y: frame.minY + frame.height * (addY + 28) / 874
            )
        }
    }

    private func dayChips(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402
        let labels = ["Sun", "Mon", "Tue", "Wed", "Tue", "Fri", "Sun"]
        let rects = [
            CGRect(x: 16, y: 654, width: 85, height: 44),
            CGRect(x: 110, y: 654, width: 86, height: 44),
            CGRect(x: 205, y: 654, width: 86, height: 44),
            CGRect(x: 300, y: 654, width: 86, height: 44),
            CGRect(x: 16, y: 708, width: 85, height: 44),
            CGRect(x: 110, y: 708, width: 86, height: 44),
            CGRect(x: 205, y: 708, width: 86, height: 44)
        ]

        return ZStack {
            ForEach(rects.indices, id: \.self) { index in
                let rect = rects[index]
                Button {
                    store.userDidInteract()
                    if selectedDays.contains(index) {
                        selectedDays.remove(index)
                    } else {
                        selectedDays.insert(index)
                    }
                } label: {
                    Text(labels[index])
                        .font(.system(size: 14 * scale, weight: .medium))
                        .foregroundStyle(Color.brandPlum)
                        .frame(width: rect.width * scale, height: frame.height * rect.height / 874)
                        .background(
                            selectedDays.contains(index)
                                ? Color(red: 1.0, green: 0.86, blue: 0.89)
                                : Color.white,
                            in: .capsule
                        )
                }
                .buttonStyle(.plain)
                .position(
                    x: frame.minX + rect.midX * scale,
                    y: frame.minY + frame.height * rect.midY / 874
                )
            }
        }
    }

    private func generationProgressView(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402
        return ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 0.975, blue: 0.97))
            Circle()
                .stroke(Color.brandPlum.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [1.2, 2.4]))
            Circle()
                .trim(from: 0, to: generationProgress)
                .stroke(Color.brandPlum, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(generationProgress * 100))%")
                .font(.system(size: 16 * scale, weight: .semibold))
                .foregroundStyle(Color.brandPlum)
        }
        .frame(width: 66 * scale, height: 66 * scale)
        .position(
            x: frame.minX + 201 * scale,
            y: frame.minY + frame.height * 183 / 874
        )
        .allowsHitTesting(false)
    }

    private func disabledGenerationButton(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402
        let buttonWidth = 362 * scale
        let buttonHeight = frame.height * 52 / 874
        let buttonX = frame.minX + 201 * scale
        let buttonY = frame.minY + frame.height * 790 / 874

        return ZStack {
            Capsule()
                .fill(Color(red: 0.68, green: 0.68, blue: 0.70))

            Text("Got It")
                .font(.system(size: 17 * scale, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
        }
            .frame(width: buttonWidth, height: buttonHeight)
            .position(x: buttonX, y: buttonY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func generationTips(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        let scale = frame.width / 402
        let tips = [
            "Target \(max(pumpsPerDay, 5)) sessions/day. Use heat therapy and soothing music to encourage your let-down.",
            "Hydration is key: drink 2000 ml+ of water daily and monitor breast fullness closely.",
            "Monitor your baby’s wet/soiled diapers and weight gain to assess milk supply.",
            "If your baby follows the growth curve, your supply is likely sufficient.",
            "Keep every session comfortable and adjust the plan when your routine changes."
        ]

        return ScrollView(.vertical) {
            LazyVStack(spacing: 10 * scale) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .center, spacing: 12 * scale) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 25 * scale, weight: .light, design: .serif))
                            .foregroundStyle(Color.brandPlum.opacity(0.85))
                            .frame(width: 42 * scale)
                        Text(tip)
                            .font(.system(size: 14 * scale))
                            .foregroundStyle(Color(red: 0.28, green: 0.02, blue: 0.10))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14 * scale)
                    .frame(minHeight: 88 * scale)
                    .background(Color.white.opacity(0.68), in: .rect(cornerRadius: 22 * scale))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22 * scale)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
                }
            }
            .padding(.vertical, 4 * scale)
        }
        .scrollIndicators(.visible)
        .frame(width: 370 * scale, height: frame.height * 408 / 874)
        .background(Color(red: 1.0, green: 0.975, blue: 0.97))
        .position(
            x: frame.minX + 201 * scale,
            y: frame.minY + frame.height * 548 / 874
        )
    }

    private func endDatePicker(in size: CGSize) -> some View {
        let frame = fittedDesignFrame(in: size)
        return ZStack {
            Color.black.opacity(0.28)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)

            RoundedRectangle(cornerRadius: frame.width * 28 / 402, style: .continuous)
                .fill(Color.white)
                .frame(width: frame.width, height: frame.height * 305 / 874)
                .position(
                    x: frame.midX,
                    y: frame.minY + frame.height * 721.5 / 874
                )

            DatePicker("", selection: $endDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.wheel)
                .colorScheme(.light)
                .frame(width: frame.width * 0.90, height: frame.height * 215 / 874)
                .clipped()
                .position(
                    x: frame.midX,
                    y: frame.minY + frame.height * 763 / 874
                )

            Button("Cancel") {
                withAnimation(.easeInOut(duration: 0.2)) { isEditingEndDate = false }
            }
            .foregroundStyle(Color.primary)
            .position(
                x: frame.minX + frame.width * 55 / 402,
                y: frame.minY + frame.height * 600 / 874
            )

            Button("Done") {
                store.showToast("Plan end date updated locally.")
                withAnimation(.easeInOut(duration: 0.2)) { isEditingEndDate = false }
            }
            .foregroundStyle(Color.brandPlum)
            .position(
                x: frame.minX + frame.width * 352 / 402,
                y: frame.minY + frame.height * 600 / 874
            )
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
        .frame(width: frame.width * rect.width / 402, height: frame.height * rect.height / 874)
        .position(
            x: frame.minX + frame.width * rect.midX / 402,
            y: frame.minY + frame.height * rect.midY / 874
        )
        .accessibilityLabel(label)
    }

    private func longTapArea(
        _ rect: CGRect,
        label: String,
        designFrame: CGRect,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.userDidInteract()
            action()
        } label: {
            Rectangle().fill(Color.clear).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            width: designFrame.width * rect.width / 402,
            height: designFrame.height * rect.height / stage.designHeight
        )
        .position(
            x: designFrame.minX + designFrame.width * rect.midX / 402,
            y: designFrame.minY + designFrame.height * rect.midY / stage.designHeight
        )
        .accessibilityLabel(label)
    }

    private func openTimePicker(editing index: Int?) {
        store.userDidInteract()
        editingTimeIndex = index
        pickerTime = index.flatMap { preferredTimes.indices.contains($0) ? preferredTimes[$0] : nil } ?? Self.time(hour: 9)
        move(to: .timePicker)
    }

    private func savePickerTime() {
        if let index = editingTimeIndex, preferredTimes.indices.contains(index) {
            preferredTimes[index] = pickerTime
        } else if preferredTimes.count < 2 {
            preferredTimes.append(pickerTime)
        }
        editingTimeIndex = nil
        move(to: .timeList)
    }

    private func move(to nextStage: PlanStage) {
        store.userDidInteract()
        if nextStage == .generating {
            // Reset synchronously so a previously completed run cannot leave
            // Got It enabled during the transition back to this screen.
            generationProgress = 0.1
        }
        if nextStage == .data {
            showsInsightTip = true
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            stage = nextStage
        }
    }

    private func goBack() {
        store.userDidInteract()
        let previous: PlanStage
        switch stage {
        case .home:
            store.showCover(.lactationPlan)
            return
        case .start: previous = .home
        case .information: previous = .start
        case .feedingChoice: previous = .information
        case .feedingCount: previous = .feedingChoice
        case .nightChoice: previous = .feedingCount
        case .timePreference: previous = .nightChoice
        case .timePicker: previous = preferredTimes.isEmpty ? .timePreference : .timeList
        case .timeList: previous = .timePreference
        case .confirmation: previous = prefersSpecificTimes ? .timeList : .timePreference
        case .generating: previous = .confirmation
        case .firstPlan: previous = .generating
        case .notification: previous = .firstPlan
        case .schedule: previous = .notification
        case .data: previous = .schedule
        case .share: previous = .data
        }
        withAnimation(.easeInOut(duration: 0.18)) { stage = previous }
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

    private func timeRange(start: Date) -> String {
        let end = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
        return "\(Self.timeFormatter.string(from: start))   -   \(Self.timeFormatter.string(from: end))"
    }

    private static func time(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()
}

private struct LactationBenefitsLoopView: View {
    private let benefits: [LactationBenefit] = [
        LactationBenefit(
            icon: "message.fill",
            title: "Personalized",
            detail: "Your AI-powered\nlactation coach"
        ),
        LactationBenefit(
            icon: "person.3.fill",
            title: "20K+",
            detail: "Trusted by\n20,000+ moms"
        ),
        LactationBenefit(
            icon: "medal.fill",
            title: "Verified",
            detail: "Backed by\n3 verified IBCLCs"
        ),
        LactationBenefit(
            icon: "drop.fill",
            title: "0 Days",
            detail: "with clogged ducts"
        )
    ]

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(0..<(benefits.count * 2), id: \.self) { index in
                        benefitCard(benefits[index % benefits.count])
                            .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 136)
            .task {
                var position = 0
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1.8))
                    guard !Task.isCancelled else { return }
                    position += 1
                    withAnimation(.easeInOut(duration: 0.42)) {
                        reader.scrollTo(position, anchor: .leading)
                    }
                    if position == benefits.count {
                        try? await Task.sleep(for: .milliseconds(480))
                        guard !Task.isCancelled else { return }
                        position = 0
                        reader.scrollTo(0, anchor: .leading)
                    }
                }
            }
        }
    }

    private func benefitCard(_ benefit: LactationBenefit) -> some View {
        VStack(spacing: 8) {
            Image(systemName: benefit.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.brandPlum)
                .frame(width: 24, height: 24)

            Text(benefit.title)
                .font(.brandMedium(14, relativeTo: .subheadline))
                .foregroundStyle(Color.brandPlum)
                .multilineTextAlignment(.center)

            Text(benefit.detail)
                .font(.brandBody(12, relativeTo: .caption))
                .foregroundStyle(Color.brandInk.opacity(0.44))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 120, height: 128, alignment: .top)
        .background(Color(red: 1.0, green: 0.969, blue: 0.973))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct LactationBenefit {
    let icon: String
    let title: String
    let detail: String
}

private enum PumpingGoal: Hashable {
    case maintainSupply
    case powerPumping
    case weaning
}

private struct InsightPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let output: Double
}

private enum InsightPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .day: "D"
        case .week: "W"
        case .month: "M"
        }
    }

    var output: Int {
        switch self {
        case .day: 16
        case .week: 86
        case .month: 305
        }
    }

    var unit: String {
        self == .month ? "oz total" : "oz"
    }

    var points: [InsightPoint] {
        switch self {
        case .day:
            [
                InsightPoint(hour: 2, output: 0),
                InsightPoint(hour: 3, output: 3),
                InsightPoint(hour: 4, output: 6),
                InsightPoint(hour: 6, output: 8),
                InsightPoint(hour: 8, output: 15),
                InsightPoint(hour: 10, output: 13),
                InsightPoint(hour: 12, output: 12)
            ]
        case .week:
            [
                InsightPoint(hour: 0, output: 8),
                InsightPoint(hour: 2, output: 12),
                InsightPoint(hour: 4, output: 10),
                InsightPoint(hour: 6, output: 16),
                InsightPoint(hour: 8, output: 19),
                InsightPoint(hour: 10, output: 17),
                InsightPoint(hour: 12, output: 21)
            ]
        case .month:
            [
                InsightPoint(hour: 0, output: 12),
                InsightPoint(hour: 2, output: 16),
                InsightPoint(hour: 4, output: 19),
                InsightPoint(hour: 6, output: 22),
                InsightPoint(hour: 8, output: 27),
                InsightPoint(hour: 10, output: 31),
                InsightPoint(hour: 12, output: 34)
            ]
        }
    }
}

private struct InsightRecord: Identifiable {
    let id: Int
    let date: String
    let duration: String
    let left: String
    let right: String
    let total: String

    static let samples = [
        InsightRecord(id: 0, date: "Jun 23, 2026 · 14:25", duration: "10m 29s", left: "5.0 oz", right: "2.8 oz", total: "7.8 oz"),
        InsightRecord(id: 1, date: "Jun 22, 2026 · 14:25", duration: "12m 21s", left: "4.9 oz", right: "2.4 oz", total: "7.3 oz"),
        InsightRecord(id: 2, date: "Jun 22, 2026 · 09:10", duration: "11m 48s", left: "4.2 oz", right: "2.7 oz", total: "6.9 oz"),
        InsightRecord(id: 3, date: "Jun 21, 2026 · 14:25", duration: "12m 21s", left: "4.9 oz", right: "2.4 oz", total: "7.3 oz")
    ]
}

private struct InsightTipTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private enum PlanStage: Hashable {
    case home
    case start
    case information
    case feedingChoice
    case feedingCount
    case nightChoice
    case timePreference
    case timePicker
    case timeList
    case confirmation
    case generating
    case firstPlan
    case notification
    case schedule
    case data
    case share

    var assetName: String {
        switch self {
        case .home: "plan-home-scroll"
        case .start: "plan-start"
        case .information: "plan-info"
        case .feedingChoice: "plan-feed-choice"
        case .feedingCount: "plan-feed-count"
        case .nightChoice: "plan-night-choice"
        case .timePreference: "plan-time-preference"
        case .timePicker: "plan-time-picker"
        case .timeList: "plan-time-multiple"
        case .confirmation: "plan-confirm"
        case .generating: "plan-generating"
        case .firstPlan: "plan-first"
        case .notification: "plan-notification"
        case .schedule: "plan-schedule"
        case .data: "plan-data-scroll"
        case .share: "plan-share"
        }
    }

    var designHeight: CGFloat {
        switch self {
        case .home: 2441
        case .data: 1376
        default: 874
        }
    }

    var isLongPage: Bool {
        self == .home
    }

    var isQuestionnaire: Bool {
        switch self {
        case .information, .feedingChoice, .feedingCount, .nightChoice,
             .timePreference, .timePicker, .timeList, .confirmation:
            true
        default:
            false
        }
    }

    var hasBackButton: Bool {
        switch self {
        case .home, .notification, .share:
            false
        default:
            true
        }
    }
}
