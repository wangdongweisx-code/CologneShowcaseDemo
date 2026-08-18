import Foundation

enum ShowcaseFeature: String, CaseIterable, Identifiable, Hashable {
    case deviceAssistant
    case voiceLog
    case lactationPlan
    case lactationTimeline
    case community

    var id: String { rawValue }

    var ordinal: Int {
        Self.allCases.firstIndex(of: self).map { $0 + 1 } ?? 1
    }

    var tabTitle: String {
        switch self {
        case .deviceAssistant: "AI Device Assistant"
        case .voiceLog: "AI Voice Log"
        case .lactationPlan: "AI Lactation Plan"
        case .lactationTimeline: "Tailored Breastfeeding Timeline"
        case .community: "Mom Groups"
        }
    }

    var coverTitle: String {
        switch self {
        case .deviceAssistant: "Connect Your Pump. Get Instant AI Support."
        case .voiceLog: "Just Say It. It’s Logged."
        case .lactationPlan: "Your Pumping Plan. Made for You."
        case .lactationTimeline: "Map Your Feeding. See What’s Next."
        case .community: "Find Your Mom Group. Share the Journey."
        }
    }

    var summary: String {
        switch self {
        case .deviceAssistant:
            "Pair in seconds and get contextual support for every step."
        case .voiceLog:
            "Capture pumping, feeding and daily care with a natural voice command."
        case .lactationPlan:
            "Turn your goals and routine into a personalized pumping plan."
        case .lactationTimeline:
            "See progress, milestones and AI-generated insights in one timeline."
        case .community:
            "Meet moms in the same moment and share support through lightweight reactions."
        }
    }

    var assetName: String {
        switch self {
        case .deviceAssistant: "device-assistant"
        case .voiceLog: "voice-log"
        case .lactationPlan: "lactation-plan"
        case .lactationTimeline: "lactation-timeline"
        case .community: "community"
        }
    }

    var systemImage: String {
        switch self {
        case .deviceAssistant: "sensor.tag.radiowaves.forward"
        case .voiceLog: "waveform"
        case .lactationPlan: "calendar.badge.clock"
        case .lactationTimeline: "chart.xyaxis.line"
        case .community: "person.3.fill"
        }
    }

    var motionResourceName: String {
        switch self {
        case .deviceAssistant: "MotionDeviceAssistant"
        case .voiceLog: "MotionVoiceLog"
        case .lactationPlan: "MotionLactationPlan"
        case .lactationTimeline: "MotionLactationTimeline"
        case .community: "MotionCommunity"
        }
    }

    var next: ShowcaseFeature {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return all[0] }
        return all[(index + 1) % all.count]
    }
}

enum DemoRoute: Equatable {
    case standby
    case highlights
    case cover(ShowcaseFeature)
    case demo(ShowcaseFeature)
}
