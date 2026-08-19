import Combine
import SwiftUI

struct RootDemoView: View {
    @StateObject private var store = DemoStore()
    private let inactivityTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            switch store.route {
            case .standby:
                StandbyView(store: store)
                    .transition(.opacity)
            case .highlights:
                HighlightsView(store: store)
                    .transition(.opacity)
            case .cover:
                CoverCarouselView(store: store)
                    .transition(.opacity)
            case let .demo(feature):
                FeatureDemoView(feature: feature, store: store)
                    .id(feature)
                    .transition(.opacity)
            }

            if let message = store.toastMessage {
                DemoToastView(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.route)
        .animation(.easeInOut(duration: 0.2), value: store.toastMessage)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in store.userDidInteract() }
        )
        .onReceive(inactivityTimer) { date in
            store.checkInactivity(at: date)
        }
        .sheet(isPresented: $store.isDisclaimerPresented) {
            DisclaimerView()
                .presentationDetents([.fraction(0.70)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .presentationBackground(.clear)
        }
    }
}

private struct DemoToastView: View {
    let message: String

    var body: some View {
        VStack {
            HStack(spacing: 14) {
                Image("DemoUnavailableWarning")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text(message)
                    .font(.custom(Font.aeonikRegularName, size: 14, relativeTo: .body))
                    .foregroundStyle(Color(red: 36 / 255, green: 15 / 255, blue: 27 / 255))
                    .tracking(0.28)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: 346)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(red: 0, green: 26 / 255, blue: 18 / 255).opacity(0.10), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 40, y: 8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    private let disclaimerText = """
    A disclaimer must be added when displaying the first or last page: This application demonstration is for display purposes only. Some features shown are prototypes or under development and may change later; they may also be excluded from future commercial releases depending on actual conditions and official launch regions. AI-generated content, recommendations, summaries, and insights are for reference and personal management only. They do not constitute medical advice, diagnosis, or treatment and do not replace consultation with healthcare professionals. Community content reflects users’ personal experiences and does not represent professional advice. Performance and user experience may vary based on device, settings, and individual circumstances.
    """

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 249 / 255, green: 247 / 255, blue: 249 / 255)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                Text(disclaimerText)
                    .font(.custom(Font.aeonikRegularName, size: 14, relativeTo: .body))
                    .foregroundStyle(Color.brandInk)
                    .tracking(0.14)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 76)
                    .padding(.bottom, 32)
            }
            .scrollIndicators(.visible)

            Text("Disclaimer")
                .font(.custom(Font.aeonikMediumName, size: 16, relativeTo: .headline))
                .foregroundStyle(Color.brandInk)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(Color(red: 249 / 255, green: 247 / 255, blue: 249 / 255).opacity(0.96))

            GeometryReader { _ in
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.brandInk)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.regular)
                .tint(Color.white.opacity(0.78))
                .frame(width: 44, height: 44)
                .position(x: 26, y: 26)
                .accessibilityLabel("Close disclaimer")
            }
            .ignoresSafeArea()
        }
        .background(Color(red: 249 / 255, green: 247 / 255, blue: 249 / 255))
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
