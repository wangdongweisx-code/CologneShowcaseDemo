import SwiftUI

struct DeviceAssistantDemoView: View {
    @ObservedObject var store: DemoStore
    @State private var stage = DeviceStage.pairing

    private enum DeviceStage: Int, CaseIterable {
        case pairing
        case welcome
        case guidance
        case assistant

        var title: String {
            switch self {
            case .pairing: "V3 found nearby"
            case .welcome: "Welcome to Beginner’s Guide"
            case .guidance: "Unbox & Inspect"
            case .assistant: "CozyAI Device Assistant"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                DemoProgress(current: stage.rawValue, total: DeviceStage.allCases.count)
                    .padding(.top)

                Text(stage.title)
                    .font(.brandDisplaySmall)
                    .foregroundStyle(Color.brandInk)
                    .frame(maxWidth: .infinity, alignment: .leading)

                stageContent

                if stage != .assistant {
                    Button(nextButtonTitle) {
                        withAnimation(.snappy) {
                            stage = DeviceStage(rawValue: stage.rawValue + 1) ?? .assistant
                        }
                    }
                    .buttonStyle(PrimaryCapsuleButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch stage {
        case .pairing:
            VStack(spacing: 16) {
                DemoTip(title: "Demo Tips: Device Pairing", message: "Tap Connect to complete device pairing.")
                VStack(spacing: 6) {
                    Text("V3")
                        .font(.brandDisplaySmall)
                        .foregroundStyle(Color.brandPlum)
                    Text("New Device Connectable")
                        .foregroundStyle(.secondary)
                    Image("v3-device")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 190)
                }
                .frame(maxWidth: .infinity)
                .demoCard()
            }

        case .welcome:
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color.brandPlum)
                Text("Let’s take a quick look to help you get started easily!")
                    .font(.title3)
                GuideRow(icon: "shippingbox.fill", title: "Unboxing", subtitle: "Open the box and get to know your parts")
                GuideRow(icon: "play.rectangle.fill", title: "Quick guide", subtitle: "Watch the setup video at your own pace")
                GuideRow(icon: "checkmark.circle.fill", title: "First Use", subtitle: "Wear it and start your first session")
            }
            .demoCard()

        case .guidance:
            VStack(spacing: 16) {
                DemoTip(title: "Demo Tips: Watch the Setup Video", message: "Watch a quick walkthrough to complete this step with confidence.")
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.brandBlush.gradient)
                        .frame(height: 230)
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundStyle(Color.white)
                        .frame(width: 64, height: 64)
                        .background(Color.brandPlum, in: .circle)
                }
                Text("Parts overview, main unit, collection cups, flanges, membranes, valves and power cable.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .demoCard()

        case .assistant:
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.brandPlum)
                Text("How can I help with your Momcozy Air 1?")
                    .font(.brandDisplaySmall)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.brandInk)
                ForEach(["How do I know the flange fits?", "What if the suction feels weak?", "Help with connection issues."], id: \.self) { prompt in
                    Button(prompt) {
                        store.showToast("CozyAI response simulated locally")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                TextField("Ask about your Momcozy Air 1", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
            }
            .demoCard()
        }
    }

    private var nextButtonTitle: String {
        stage == .pairing ? "Connect" : "Continue"
    }
}

private struct GuideRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.brandPlum)
                .frame(width: 30)
        }
    }
}
