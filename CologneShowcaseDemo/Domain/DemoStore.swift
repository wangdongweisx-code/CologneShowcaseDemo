import Combine
import Foundation

@MainActor
final class DemoStore: ObservableObject {
    static let demoUnavailableMessage = "This feature is not available in the demo version. Download the Momcozy app to experience the full feature."

    @Published var route: DemoRoute = .standby
    @Published var selectedFeature: ShowcaseFeature = .deviceAssistant
    @Published var isDisclaimerPresented = false
    @Published var toastMessage: String?

    let inactivityInterval: TimeInterval

    private(set) var lastInteraction: Date
    private var toastTask: Task<Void, Never>?

    init(inactivityInterval: TimeInterval = 120, now: Date = Date()) {
        self.inactivityInterval = inactivityInterval
        self.lastInteraction = now
    }

    func userDidInteract(at date: Date = Date()) {
        lastInteraction = date
    }

    func checkInactivity(at date: Date = Date()) {
        guard route != .standby else { return }
        guard date.timeIntervalSince(lastInteraction) >= inactivityInterval else { return }
        resetToStandby(at: date)
    }

    func resetToStandby(at date: Date = Date()) {
        route = .standby
        selectedFeature = .deviceAssistant
        isDisclaimerPresented = false
        toastMessage = nil
        lastInteraction = date
    }

    func showHighlights() {
        route = .highlights
        userDidInteract()
    }

    func showCover(_ feature: ShowcaseFeature) {
        selectedFeature = feature
        route = .cover(feature)
        userDidInteract()
    }

    func selectCoverFeature(_ feature: ShowcaseFeature) {
        selectedFeature = feature
        route = .cover(feature)
        userDidInteract()
    }

    func startDemo(_ feature: ShowcaseFeature) {
        selectedFeature = feature
        route = .demo(feature)
        userDidInteract()
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            self?.toastMessage = nil
        }
    }

    func showDemoUnavailableToast() {
        userDidInteract()
        showToast(Self.demoUnavailableMessage)
    }
}
