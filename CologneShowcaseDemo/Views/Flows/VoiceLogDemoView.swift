import SwiftUI

/// Voice Log flow translated from Figma section 177:21681.
/// All visible copy, colors, measurements and image crops come from Figma.
struct VoiceLogDemoView: View {
    @ObservedObject var store: DemoStore
    @State private var stage: VoiceFigmaStage = .home
    @State private var agreementAccepted = false
    @State private var showMicrophonePermission = false
    @State private var records = VoiceFigmaRecord.samples
    @State private var hasSaved = false

    var body: some View {
        ZStack {
            FigmaVoiceHome(hasSaved: hasSaved) {
                transition(to: .intro)
            }
            .allowsHitTesting(stage == .home)

            if stage != .home {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
            }

            switch stage {
            case .home:
                EmptyView()
            case .intro:
                introSheet
            case .agreement:
                agreementSheet
            case .listening:
                listeningSheet
            case .thinking:
                thinkingSheet
            case .records:
                recordsSheet
            case .logged:
                loggedSheet
            }
        }
        .background(FigmaVoiceColor.background)
        .alert("“Momcozy” Would Like to Access the Microphone", isPresented: $showMicrophonePermission) {
            Button("Don’t Allow", role: .cancel) { }
            Button("Allow") { }
        } message: {
            Text("Momcozy needs microphone access for Voice Log")
        }
        .task(id: stage) {
            if stage == .thinking {
                try? await Task.sleep(for: .seconds(1.4))
                guard !Task.isCancelled else { return }
                transition(to: .records)
            } else if stage == .logged {
                try? await Task.sleep(for: .seconds(1.7))
                guard !Task.isCancelled else { return }
                transition(to: .home)
            }
        }
    }

    private var introSheet: some View {
        FigmaVoiceSheet(title: "Voice Log", height: 594, close: { store.showCover(.voiceLog) }) {
            VStack(spacing: 0) {
                FigmaExactCrop(
                    assetName: "voice-log-1",
                    designSize: CGSize(width: 402, height: 874),
                    cropRect: CGRect(x: 126, y: 379, width: 150, height: 142)
                )
                .frame(width: 132, height: 132)
                .padding(.top, 64)

                Text("Log moments hands-free, speak naturally, AI organizes")
                    .font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .body))
                    .foregroundStyle(FigmaVoiceColor.plum)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(width: 298)
                    .padding(.top, 24)

                Spacer()

                Button {
                    agreementAccepted.toggle()
                } label: {
                    HStack(spacing: 8) {
                        FigmaAgreementCheckbox(isSelected: agreementAccepted)
                        Text("I agree to the ") + Text("User Agreement").underline().bold()
                    }
                    .font(.custom("AeonikSoftPro-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(FigmaVoiceColor.plum)
                }
                .buttonStyle(.plain)

                Button("Get Started") {
                    transition(to: .agreement)
                }
                .buttonStyle(FigmaPlumButtonStyle(enabled: agreementAccepted))
                .disabled(!agreementAccepted)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var agreementSheet: some View {
        FigmaVoiceSheet(title: "User Agreement", height: 778, close: { store.showCover(.voiceLog) }) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("We value the privacy of you and your baby.")

                    Text("To provide personalized breastfeeding plans, we need to collect and process information about you and your baby, such as your breastfeeding goals, maternity leave duration, your baby's age, height and weight, breastfeeding records, and other breastfeeding-related information you choose to provide.")

                    Text("Subject to applicable laws, some of this information may be considered health-related information (such as breastfeeding records and your baby's growth and development data) and children's personal information (such as your baby's name, nickname, age, height, and weight).")

                    Text("We use this information solely to provide and improve breastfeeding plan services as described in our Privacy Policy. We do not use your personal information to train any artificial intelligence models. Where required by law, we rely on your consent to process this information. If you are a legal guardian, your consent also applies to your baby's personal information associated with your account.")

                    Text("You may withdraw your consent at any time by contacting us at Dataprivacy@momcozy.com. Withdrawal will not affect processing conducted before withdrawal. However, because this information is necessary to provide breastfeeding plan services, withdrawing consent means we can no longer provide these services.")
                }
                .font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .body))
                .foregroundStyle(Color(red: 36 / 255, green: 15 / 255, blue: 27 / 255))
                .lineSpacing(2)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 82)
            }
            .overlay(alignment: .bottom) {
                Button("Agree and Continue") {
                    transition(to: .listening)
                    showMicrophonePermission = true
                }
                .buttonStyle(FigmaPlumButtonStyle(enabled: true))
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(FigmaVoiceColor.background)
            }
        }
    }

    private var listeningSheet: some View {
        FigmaVoiceSheet(title: "Voice Log", height: 594, close: { store.showCover(.voiceLog) }) {
            VStack(spacing: 0) {
                FigmaExactCrop(
                    assetName: "voice-log-1",
                    designSize: CGSize(width: 402, height: 874),
                    cropRect: CGRect(x: 151, y: 420, width: 100, height: 100)
                )
                .frame(width: 96, height: 96)
                .blur(radius: 5)
                .padding(.top, 63)

                Text("Listening...")
                    .font(.custom("AeonikSoftPro-Regular", size: 16, relativeTo: .body))
                    .foregroundStyle(Color(red: 36 / 255, green: 15 / 255, blue: 27 / 255))
                    .padding(.top, 38)

                FigmaWaveform()
                    .frame(width: 138, height: 26)
                    .padding(.top, 72)

                Spacer()

                Button("Send") {
                    transition(to: .thinking)
                }
                .buttonStyle(FigmaPlumButtonStyle(enabled: true))
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var thinkingSheet: some View {
        FigmaVoiceSheet(title: "Voice Log", height: 594, close: { store.showCover(.voiceLog) }) {
            VStack(spacing: 18) {
                Text("Anna woke up at 7 a.m., drank 4 ounces of milk, had a wet diaper changed, and took her vitamin D. She fell back asleep at 8:30 a.m.")
                    .font(.custom("AeonikSoftPro-Regular", size: 16, relativeTo: .body))
                    .foregroundStyle(Color(red: 36 / 255, green: 15 / 255, blue: 27 / 255))
                    .lineSpacing(2)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.08)))
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                HStack(spacing: 6) {
                    Text("Thinking...")
                    ProgressView().controlSize(.small)
                }
                .font(.custom("AeonikSoftPro-Regular", size: 16, relativeTo: .body))

                Spacer()

                FigmaMicrophoneButton {
                    transition(to: .listening)
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var recordsSheet: some View {
        FigmaVoiceSheet(title: "Voice Log", height: 728, close: { store.showCover(.voiceLog) }) {
            VStack(spacing: 12) {
                Text("Anna woke up at 7 a.m., drank 4 ounces of milk, had a wet diaper changed, and took her vitamin D. She fell back asleep at 8:30 a.m.")
                    .font(.custom("AeonikSoftPro-Regular", size: 15, relativeTo: .body))
                    .foregroundStyle(Color(red: 36 / 255, green: 15 / 255, blue: 27 / 255))
                    .lineSpacing(2)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.08)))

                VStack(spacing: 0) {
                    ForEach(records) { record in
                        FigmaRecordRow(record: record) {
                            withAnimation { records.removeAll { $0.id == record.id } }
                        }
                        if record.id != records.last?.id {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20))

                Spacer(minLength: 0)

                Button("Save") {
                    hasSaved = true
                    transition(to: .logged)
                }
                .buttonStyle(FigmaPlumButtonStyle(enabled: !records.isEmpty))
                .disabled(records.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var loggedSheet: some View {
        FigmaVoiceSheet(title: "", height: 674, close: { store.showCover(.voiceLog) }) {
            VStack(spacing: 0) {
                FigmaExactCrop(
                    assetName: "voice-logged",
                    designSize: CGSize(width: 402, height: 874),
                    cropRect: CGRect(x: 130, y: 384, width: 142, height: 185)
                )
                .frame(width: 142, height: 185)
                .padding(.top, 82)

                Text("Logged")
                    .font(.custom("Exposure-10-Regular", size: 54, relativeTo: .largeTitle))
                    .foregroundStyle(Color(red: 145 / 255, green: 0, blue: 36 / 255))

                Text("Today’s data has been updated.\nEvery little change means the baby is quietly growing.")
                    .font(.custom("AeonikSoftPro-Regular", size: 16, relativeTo: .body))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 36 / 255, green: 15 / 255, blue: 27 / 255).opacity(0.36))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.top, 50)
                    .padding(.horizontal, 38)
            }
        }
    }

    private func transition(to next: VoiceFigmaStage) {
        store.userDidInteract()
        withAnimation(.easeInOut(duration: 0.22)) { stage = next }
    }
}

private enum VoiceFigmaStage: Hashable {
    case home, intro, agreement, listening, thinking, records, logged
}

private enum FigmaVoiceColor {
    static let background = Color(red: 249 / 255, green: 247 / 255, blue: 245 / 255)
    static let plum = Color(red: 62 / 255, green: 0, blue: 16 / 255)
    static let rose = Color(red: 119 / 255, green: 5 / 255, blue: 35 / 255)
}

private struct FigmaVoiceHome: View {
    let hasSaved: Bool
    let openVoiceLog: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                header
                advice
                dailyCheckIns
                reminders
                exactLowerHome
            }
            .padding(.bottom, 36)
        }
        .background(FigmaVoiceColor.background)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                FigmaExactCrop(assetName: "plan-home-1", designSize: CGSize(width: 402, height: 874), cropRect: CGRect(x: 16, y: 62, width: 44, height: 44))
                    .frame(width: 44, height: 44)
                Spacer()
                HStack(spacing: 9) {
                    FigmaExactCrop(assetName: "plan-home-1", designSize: CGSize(width: 402, height: 874), cropRect: CGRect(x: 99, y: 72, width: 24, height: 24))
                        .frame(width: 24, height: 24).clipShape(Circle())
                    Text("Hi, Clare and Bonnie")
                        .font(.custom("AeonikSoftPro-Regular", size: 16, relativeTo: .headline))
                        .fontWeight(.medium)
                    FigmaExactCrop(
                        assetName: "plan-home-1",
                        designSize: CGSize(width: 402, height: 874),
                        cropRect: CGRect(x: 287, y: 72, width: 18, height: 24)
                    )
                    .frame(width: 18, height: 24)
                }
                Spacer()
                FigmaExactCrop(assetName: "plan-home-1", designSize: CGSize(width: 402, height: 874), cropRect: CGRect(x: 342, y: 62, width: 44, height: 44))
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 62)

            HStack(spacing: 12) {
                Text("‹")
                Text("Today, May 13th")
                    .fontWeight(.medium)
                Text("›")
            }
            .font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .subheadline))
            .foregroundStyle(FigmaVoiceColor.rose)
            .padding(.top, 39)

            Text("Postpartum\n1 Week")
                .font(.custom("Exposure-10-Regular", size: 32, relativeTo: .largeTitle))
                .foregroundStyle(FigmaVoiceColor.rose)
                .multilineTextAlignment(.center)
                .lineSpacing(-1)
                .padding(.top, 12)
                .padding(.bottom, 38)
        }
        .background {
            RadialGradient(colors: [Color(red: 1, green: 158 / 255, blue: 178 / 255).opacity(0.82), .clear], center: .center, startRadius: 0, endRadius: 170)
                .frame(height: 390)
                .offset(y: 42)
        }
    }

    private var advice: some View {
        VStack(spacing: 0) {
            HStack(spacing: 29) {
                FigmaExactCrop(assetName: "plan-home-1", designSize: CGSize(width: 402, height: 874), cropRect: CGRect(x: 40, y: 306, width: 38, height: 42))
                    .frame(width: 38, height: 42)
                Text("Mom").fontWeight(.medium).foregroundStyle(FigmaVoiceColor.plum)
                Text("Baby").foregroundStyle(.secondary)
                Text("Lactation").foregroundStyle(.secondary)
            }
            .font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .subheadline))
            .frame(height: 50)

            Divider()

            Text("•  Pay attention to baby's skin jaundice, and on-demand feeding is key.\n•  Nurture your body science-backed care, for a healthy pregnancy and a happy you.")
                .font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .body))
                .foregroundStyle(Color(red: 36 / 255, green: 15 / 255, blue: 27 / 255))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16)
    }

    private var dailyCheckIns: some View {
        VStack(alignment: .leading, spacing: 14) {
            FigmaSectionTitle(title: "Daily Check-ins", trailing: "View all  ›")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FigmaCheckInCard(title: "Voice", subtitle: hasSaved ? "Just now" : "Log", tint: Color.white, crop: CGRect(x: 23, y: 531, width: 28, height: 28), action: openVoiceLog)
                    FigmaCheckInCard(title: "Pump", subtitle: "1h 30m ago", tint: Color(red: 1, green: 237 / 255, blue: 241 / 255), crop: CGRect(x: 61, y: 531, width: 30, height: 30), action: {})
                    FigmaCheckInCard(title: "Feed", subtitle: "1h 30m ago", tint: Color(red: 235 / 255, green: 249 / 255, blue: 239 / 255), crop: CGRect(x: 135, y: 531, width: 30, height: 30), action: {})
                    FigmaCheckInCard(title: "Supplement", subtitle: "1h 30m ago", tint: Color(red: 1, green: 248 / 255, blue: 221 / 255), crop: CGRect(x: 252, y: 531, width: 30, height: 30), action: {})
                }
                .padding(.horizontal, 16)
            }
            .contentMargins(.horizontal, -16, for: .scrollContent)
        }
        .padding(.horizontal, 16)
        .padding(.top, 30)
    }

    private var reminders: some View {
        VStack(alignment: .leading, spacing: 12) {
            FigmaSectionTitle(title: "Reminders", trailing: "5  ›")
            VStack(spacing: 0) {
                FigmaReminderRow(time: "All Day", title: "BirthEase Maternity Ball Program", trailing: "Start", selected: false)
                Divider().padding(.leading, 55)
                FigmaReminderRow(time: "9:00", title: "BirthEase Maternity Ball Program", trailing: "", selected: true)
                Divider().padding(.leading, 55)
                FigmaReminderRow(time: "11:00", title: "BirthEase Maternity Ball Program", trailing: "", selected: false)
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
        }
        .padding(.horizontal, 16)
        .padding(.top, 30)
    }

    private var exactLowerHome: some View {
        VStack(alignment: .leading, spacing: 12) {
            FigmaSectionTitle(title: "AI insights", trailing: "")

            FigmaExactCrop(assetName: "plan-home-scroll", designSize: CGSize(width: 402, height: 2441), cropRect: CGRect(x: 16, y: 806, width: 370, height: 310))
                .frame(height: 310)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            FigmaExactCrop(assetName: "plan-home-scroll", designSize: CGSize(width: 402, height: 2441), cropRect: CGRect(x: 16, y: 1130, width: 370, height: 154))
                .frame(height: 154)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            FigmaExactCrop(assetName: "plan-home-scroll", designSize: CGSize(width: 402, height: 2441), cropRect: CGRect(x: 16, y: 1300, width: 370, height: 154))
                .frame(height: 154)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            FigmaSectionTitle(title: "Momcozy Reads", trailing: "View all  ›")
                .padding(.top, 10)
            FigmaExactCrop(assetName: "plan-home-scroll", designSize: CGSize(width: 402, height: 2441), cropRect: CGRect(x: 16, y: 1510, width: 370, height: 190))
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            FigmaSectionTitle(title: "Featured goods", trailing: "View all  ›")
                .padding(.top, 10)
            FigmaExactCrop(assetName: "plan-home-scroll", designSize: CGSize(width: 402, height: 2441), cropRect: CGRect(x: 16, y: 1763, width: 370, height: 480))
                .frame(height: 480)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 16)
        .padding(.top, 30)
    }
}

private struct FigmaSectionTitle: View {
    let title: String
    let trailing: String
    var body: some View {
        HStack {
            Text(title).fontWeight(.medium)
            Spacer()
            Text(trailing).foregroundStyle(.secondary)
        }
        .font(.custom("AeonikSoftPro-Regular", size: 16, relativeTo: .headline))
    }
}

private struct FigmaCheckInCard: View {
    let title: String
    let subtitle: String
    let tint: Color
    let crop: CGRect
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                FigmaExactCrop(assetName: "plan-home-1", designSize: CGSize(width: 402, height: 874), cropRect: crop)
                    .frame(width: 30, height: 30)
                VStack(spacing: 2) {
                    Text(title).fontWeight(.medium)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            .font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .body))
            .foregroundStyle(FigmaVoiceColor.plum)
            .frame(width: 84, height: 120)
            .background(tint, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

private struct FigmaReminderRow: View {
    let time: String
    let title: String
    let trailing: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color(red: 247 / 255, green: 233 / 255, blue: 1)).frame(width: 32, height: 32)
                .overlay(Circle().fill(FigmaVoiceColor.rose).frame(width: 11, height: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(time).font(.caption).foregroundStyle(.secondary)
                Text(title).font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .body))
            }
            Spacer()
            if !trailing.isEmpty {
                Text(trailing).font(.caption).padding(.horizontal, 12).padding(.vertical, 8).overlay(Capsule().stroke(Color.black.opacity(0.16)))
            } else {
                ZStack {
                    Circle()
                        .fill(selected ? FigmaVoiceColor.plum : Color.clear)
                    Circle()
                        .stroke(selected ? FigmaVoiceColor.plum : Color.secondary.opacity(0.35), lineWidth: 1.2)
                    if selected {
                        FigmaCheckmark()
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                            .frame(width: 14, height: 10)
                    }
                }
                .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 62)
    }
}

private struct FigmaVoiceSheet<Content: View>: View {
    let title: String
    let height: CGFloat
    let close: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .font(.custom("Exposure-10-Regular", size: title == "User Agreement" ? 16 : 24, relativeTo: .title2))
                    .foregroundStyle(FigmaVoiceColor.plum)
                HStack {
                    Button(action: close) {
                        FigmaExactCrop(
                            assetName: "voice-log-1",
                            designSize: CGSize(width: 402, height: 874),
                            cropRect: CGRect(x: 16, y: 296, width: 44, height: 44)
                        )
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .frame(height: 89)
            .padding(.horizontal, 16)

            content()
        }
        .frame(maxWidth: 402, minHeight: height, maxHeight: height)
        .background(FigmaVoiceColor.background)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 36, topTrailingRadius: 36))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }
}

/// The checkbox geometry and color are taken from the Figma agreement state.
/// It is drawn as a control so it stays crisp and interactive at every scale.
private struct FigmaAgreementCheckbox: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(isSelected ? FigmaVoiceColor.plum : Color.clear)
            RoundedRectangle(cornerRadius: 3)
                .stroke(FigmaVoiceColor.plum.opacity(isSelected ? 1 : 0.5), lineWidth: 1.2)
            if isSelected {
                FigmaCheckmark()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 10, height: 7)
            }
        }
        .frame(width: 16, height: 16)
    }
}

private struct FigmaCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

private struct FigmaWaveform: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate * 8)
            HStack(spacing: 2) {
                ForEach(0..<37, id: \.self) { index in
                    Capsule()
                        .fill(Color(red: 205 / 255, green: 71 / 255, blue: 104 / 255))
                        .frame(width: 2, height: CGFloat(5 + ((index * 9 + tick * 5) % 16)))
                }
            }
        }
    }
}

private struct FigmaMicrophoneButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            FigmaExactCrop(
                assetName: "voice-log-1",
                designSize: CGSize(width: 402, height: 874),
                cropRect: CGRect(x: 166, y: 774, width: 70, height: 70)
            )
            .frame(width: 68, height: 68)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct FigmaRecordRow: View {
    let record: VoiceFigmaRecord
    let delete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            FigmaExactCrop(
                assetName: "voice-log-4",
                designSize: CGSize(width: 402, height: 874),
                cropRect: record.iconCrop
            )
            .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title).font(.caption).foregroundStyle(.secondary)
                Text(record.detail).font(.custom("AeonikSoftPro-Regular", size: 14, relativeTo: .body))
            }
            Spacer()
            Button(action: delete) {
                FigmaExactCrop(
                    assetName: "voice-log-4",
                    designSize: CGSize(width: 402, height: 874),
                    cropRect: record.deleteCrop
                )
                .frame(width: 24, height: 24)
            }
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
    }
}

private struct VoiceFigmaRecord: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let iconCrop: CGRect
    let deleteCrop: CGRect

    static let samples = [
        VoiceFigmaRecord(title: "Pumping", detail: "Left 12 oz    Right 30 oz", iconCrop: CGRect(x: 30, y: 382, width: 38, height: 38), deleteCrop: CGRect(x: 347, y: 389, width: 24, height: 24)),
        VoiceFigmaRecord(title: "Feeding", detail: "Bottle    176ml    Formula", iconCrop: CGRect(x: 30, y: 447, width: 38, height: 38), deleteCrop: CGRect(x: 347, y: 454, width: 24, height: 24)),
        VoiceFigmaRecord(title: "Diaper", detail: "Pee    Green", iconCrop: CGRect(x: 30, y: 512, width: 38, height: 38), deleteCrop: CGRect(x: 347, y: 519, width: 24, height: 24)),
        VoiceFigmaRecord(title: "Sleep", detail: "Mar 28, 2026  5:00 PM  -\nMar 28, 2026  7:19 PM", iconCrop: CGRect(x: 30, y: 578, width: 38, height: 38), deleteCrop: CGRect(x: 347, y: 586, width: 24, height: 24))
    ]
}

private struct FigmaPlumButtonStyle: ButtonStyle {
    let enabled: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("AeonikSoftPro-Regular", size: 16, relativeTo: .headline))
            .fontWeight(.semibold)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(FigmaVoiceColor.plum.opacity(enabled ? (configuration.isPressed ? 0.82 : 1) : 0.30), in: Capsule())
    }
}

/// Crops only a Figma visual asset from a known Figma-exported screen.
private struct FigmaExactCrop: View {
    let assetName: String
    let designSize: CGSize
    let cropRect: CGRect

    var body: some View {
        if let image = croppedImage {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
        }
    }

    private var croppedImage: UIImage? {
        guard let source = FigmaScreenImageLoader.image(named: assetName), let cg = source.cgImage else { return nil }
        let sx = CGFloat(cg.width) / designSize.width
        let sy = CGFloat(cg.height) / designSize.height
        let pixels = CGRect(x: cropRect.minX * sx, y: cropRect.minY * sy, width: cropRect.width * sx, height: cropRect.height * sy).integral
        guard let cropped = cg.cropping(to: pixels) else { return nil }
        return UIImage(cgImage: cropped, scale: source.scale, orientation: source.imageOrientation)
    }
}
