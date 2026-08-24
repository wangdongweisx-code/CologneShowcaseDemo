import SwiftUI

/// Native, high-resolution implementation of the approved Timeline share frame.
/// Only the photographic avatar and exact Figma channel artwork remain assets.
struct TimelineShareNativeView: View {
    let date: String
    let onClose: () -> Void
    let onCommunity: () -> Void
    let onFacebook: () -> Void
    let onSave: () -> Void
    let onExitDemo: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let frame = fittedDesignFrame(in: proxy.size)
            let scale = frame.width / 402

            design
                .frame(width: 402, height: 874)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: frame.width, height: frame.height, alignment: .topLeading)
                .position(x: frame.midX, y: frame.midY)
        }
        .background(Color.white)
        .ignoresSafeArea()
    }

    private var design: some View {
        ZStack(alignment: .topLeading) {
            shareBackdrop

            Color(red: 0.141, green: 0.059, blue: 0.106)
                .opacity(0.44)

            accomplishmentCard
                .frame(width: 326, height: 435)
                .position(x: 201, y: 379.5)

            shareSheet
                .frame(width: 402, height: 238)
                .position(x: 201, y: 756)

            Button(action: onExitDemo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.82), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
            }
            .buttonStyle(.plain)
            .position(x: 358, y: 726)
            .accessibilityLabel("Back to selling points")
        }
        .frame(width: 402, height: 874)
        .clipped()
    }

    private var shareBackdrop: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 62)

            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.brandInk)
                        .frame(width: 44, height: 44)
                        .background(Color.white, in: Circle())
                        .overlay(Circle().stroke(Color(red: 0.945, green: 0.945, blue: 0.945), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                Spacer()
                Text("Breast Pump Record")
                    .font(.brandMedium(16))
                    .foregroundStyle(Color.brandInk)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)

            HStack(spacing: 24) {
                circleArrow("chevron.left")

                HStack(spacing: 0) {
                    Text("D")
                        .font(.brandMedium(14))
                        .foregroundStyle(Color.brandPlum)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().stroke(Color(red: 0.914, green: 0.906, blue: 0.910), lineWidth: 1))
                    Text("W")
                        .font(.brandBody(14))
                        .foregroundStyle(Color.brandInk.opacity(0.55))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text("M")
                        .font(.brandBody(14))
                        .foregroundStyle(Color.brandInk.opacity(0.55))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(4)
                .frame(height: 40)
                .background(Color(red: 0.976, green: 0.969, blue: 0.961), in: Capsule())

                circleArrow("chevron.right")
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 6) {
                Text("Milk Output")
                    .font(.brandBody(12))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("16")
                        .font(.system(size: 40, weight: .light))
                    Text("oz")
                        .font(.brandBody(16))
                }
            }
            .foregroundStyle(Color.brandInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 22)

            TimelineShareBackdropChart()
                .frame(height: 222)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("Today’s Accomplishment")
                    .font(.brandMedium(15))
                    .foregroundStyle(Color.brandInk)
                Text("650 ml · 5 sessions")
                    .font(.brandBody(13))
                    .foregroundStyle(Color.brandInk.opacity(0.52))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(red: 1.0, green: 0.925, blue: 0.936), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .frame(width: 402, height: 874)
        .background(Color.white)
    }

    private func circleArrow(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.brandInk)
            .frame(width: 40, height: 40)
            .background(Color.white, in: Circle())
            .overlay(Circle().stroke(Color(red: 0.945, green: 0.945, blue: 0.945), lineWidth: 1))
    }

    private var accomplishmentCard: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.945, blue: 0.953),
                    Color(red: 1.0, green: 0.867, blue: 0.882)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.white.opacity(0.92), Color.white.opacity(0)],
                center: .center,
                startRadius: 8,
                endRadius: 180
            )
            .frame(width: 328, height: 328)
            .offset(x: -1, y: -200)

            TimelineShareAsset(name: "timeline-share-logo")
                .frame(width: 71.3, height: 9)
                .position(x: 51.7, y: 22.5)

            VStack(alignment: .trailing, spacing: 3) {
                Text("AI Lactation Plan")
                    .font(.brandBody(12))
                Text(date)
                    .font(.brandBody(12))
                    .foregroundStyle(Color.brandInk.opacity(0.5))
            }
            .foregroundStyle(Color.brandInk)
            .frame(width: 138, alignment: .trailing)
            .position(x: 241, y: 28)

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                TimelineShareAsset(name: "timeline-share-badge")
                    .frame(width: 20, height: 20)
                    .padding(.bottom, 8)

                Text("Today's Accomplishment")
                    .font(.custom(Font.exposureMinus10Name, size: 24, relativeTo: .title2))
                    .tracking(0.48)
                    .foregroundStyle(Color.brandInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)

                Text("One day, one pump at a time — a small moment from my breastfeeding journey, shared with love.")
                    .font(.brandBody(12, relativeTo: .caption))
                    .tracking(0.24)
                    .lineSpacing(2)
                    .foregroundStyle(Color(red: 0.271, green: 0.271, blue: 0.271).opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)

                HStack(spacing: 40) {
                    metric(title: "Output", value: "650", unit: "ml")
                    metric(title: "Sessions", value: "5", unit: nil)
                }
                .padding(.bottom, 24)

                HStack(spacing: 8) {
                    TimelineShareAsset(name: "timeline-share-avatar", contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Jane Doe")
                            .font(.brandMedium(14))
                        Text("Millions of moms, one journey.")
                            .font(.brandBody(12))
                            .foregroundStyle(Color.brandInk.opacity(0.5))
                    }
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func metric(title: String, value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.brandBody(12))
                .foregroundStyle(Color.brandInk.opacity(0.5))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.custom(Font.aeonikRegularName, size: 28, relativeTo: .title))
                    .fontWeight(.light)
                if let unit {
                    Text(unit)
                        .font(.brandBody(12, relativeTo: .caption))
                }
            }
            .foregroundStyle(Color.brandInk)
        }
    }

    private var shareSheet: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.973, green: 0.969, blue: 0.976)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.62), in: Circle())
            }
            .buttonStyle(.plain)
            .position(x: 38, y: 38)
            .accessibilityLabel("Close sharing")

            Text("Share to")
                .font(.brandMedium(16))
                .foregroundStyle(Color(red: 0.106, green: 0.094, blue: 0.129))
                .frame(width: 160)
                .position(x: 201, y: 39)

            HStack(spacing: 22) {
                shareChannel(name: "timeline-share-community", title: "Community", action: onCommunity)
                shareChannel(name: "timeline-share-facebook", title: "Facebook", action: onFacebook)
                shareChannel(name: "timeline-share-save", title: "Save as Image", action: onSave)
            }
            .padding(.leading, 20)
            .padding(.top, 96)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38))
    }

    private func shareChannel(name: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                TimelineShareAsset(name: name)
                    .frame(width: 55, height: 55)
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(red: 0.016, green: 0.043, blue: 0.161))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .frame(width: title == "Save as Image" ? 84 : 61)
        .accessibilityLabel(title)
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

private struct TimelineShareAsset: View {
    let name: String
    var contentMode: ContentMode = .fit

    var body: some View {
        if let image = FigmaScreenImageLoader.image(named: name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: contentMode)
        } else {
            Color.clear
        }
    }
}

private struct TimelineShareBackdropChart: View {
    private let plum = Color(red: 0.467, green: 0.020, blue: 0.137)
    private let rose = Color(red: 0.933, green: 0.612, blue: 0.655)

    var body: some View {
        Canvas { context, size in
            let plot = CGRect(x: 24, y: 14, width: size.width - 28, height: size.height - 40)

            for index in 0...4 {
                let y = plot.minY + plot.height * CGFloat(index) / 4
                var grid = Path()
                grid.move(to: CGPoint(x: plot.minX, y: y))
                grid.addLine(to: CGPoint(x: plot.maxX, y: y))
                context.stroke(grid, with: .color(Color.brandInk.opacity(0.08)), lineWidth: 0.7)
            }

            let values: [CGFloat] = [0.18, 0.28, 0.42, 0.38, 0.57, 0.61, 0.54, 0.49, 0.46]
            var line = Path()
            for (index, value) in values.enumerated() {
                let x = plot.minX + plot.width * CGFloat(index) / CGFloat(values.count - 1)
                let y = plot.maxY - plot.height * value
                if index == 0 { line.move(to: CGPoint(x: x, y: y)) }
                else { line.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(line, with: .color(plum), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

            let bandValues: [CGFloat] = [0.08, 0.16, 0.29, 0.34, 0.48, 0.52, 0.46, 0.40, 0.36]
            var band = Path()
            for (index, value) in bandValues.enumerated() {
                let x = plot.minX + plot.width * CGFloat(index) / CGFloat(bandValues.count - 1)
                let y = plot.maxY - plot.height * value
                if index == 0 { band.move(to: CGPoint(x: x, y: y)) }
                else { band.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(band, with: .color(rose), lineWidth: 1.2)
        }
        .overlay(alignment: .topLeading) {
            Text("OZ")
                .font(.brandBody(10))
                .foregroundStyle(Color.brandInk.opacity(0.5))
        }
    }
}
