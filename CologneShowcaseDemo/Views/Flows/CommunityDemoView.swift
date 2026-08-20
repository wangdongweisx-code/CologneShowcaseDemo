import SwiftUI

struct CommunityDemoView: View {
    @ObservedObject var store: DemoStore
    let onBack: () -> Void

    @State private var isJoined = false
    @State private var selectedStatus = "need company"
    @State private var showsStatusPicker = false
    @State private var previewAsset: String?

    private let statuses = CommunityStatus.all

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.communityCanvas.ignoresSafeArea()

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header
                    groupInformation
                    currentStatusHeader
                    statusWall
                    feed
                }
                .padding(.top, 54)
            }
            .scrollIndicators(.visible)

            Button(action: {}) {
                Text(isJoined ? "Post" : "Join & Post")
                    .font(.brandMedium(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.white)
                    .frame(width: 135, height: 44)
                    .background(Color.brandPlum, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 24, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(true)
            .accessibilityLabel("Posting is unavailable in this demo")
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showsStatusPicker) {
            CommunityStatusPicker(statuses: statuses, selectedStatus: $selectedStatus)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { previewAsset != nil },
                set: { if !$0 { previewAsset = nil } }
            )
        ) {
            CommunityImagePreview(assetName: previewAsset ?? "community-post-1") {
                previewAsset = nil
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                store.userDidInteract()
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color.brandInk)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(Color.white.opacity(0.82))
            .accessibilityLabel("Previous community step")
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    private var groupInformation: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pumping moms")
                        .font(.custom(Font.exposureMinus10Name, size: 24, relativeTo: .title2))
                        .foregroundStyle(Color.brandInk)
                        .tracking(0.48)
                    HStack(spacing: 8) {
                        CommunityAvatarStack()
                        Text("128 moms active today")
                            .font(.brandBody(12, relativeTo: .caption))
                            .foregroundStyle(Color.brandInk)
                    }
                }
                Spacer()
                Button {
                    store.userDidInteract()
                    withAnimation(.easeInOut(duration: 0.18)) { isJoined.toggle() }
                } label: {
                    Text(isJoined ? "Joined" : "Join")
                        .font(.brandMedium(14, relativeTo: .subheadline))
                        .foregroundStyle(isJoined ? Color.brandPlum : Color.white)
                        .frame(width: 80, height: 40)
                        .background(isJoined ? Color.white : Color.brandPlum, in: Capsule())
                        .overlay {
                            if isJoined { Capsule().stroke(Color.brandPlum.opacity(0.16)) }
                        }
                }
                .buttonStyle(.plain)
            }

            Text("A soft place for pump timers, bottle warmers, and tiny wins while the house is asleep.")
                .font(.brandBody(14, relativeTo: .subheadline))
                .foregroundStyle(Color.brandInk.opacity(0.44))
                .tracking(0.28)
                .lineSpacing(2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var currentStatusHeader: some View {
        HStack {
            Text("I’m currently...")
                .font(.brandMedium(16, relativeTo: .headline))
                .foregroundStyle(Color.brandInk)
            Spacer()
            Button {
                store.userDidInteract()
                showsStatusPicker = true
            } label: {
                Text("Add Status")
                    .font(.brandMedium(12, relativeTo: .caption))
                    .foregroundStyle(Color(red: 62 / 255, green: 0, blue: 16 / 255))
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
    }

    private var statusWall: some View {
        GeometryReader { proxy in
            ForEach(statuses) { status in
                CommunityStatusBubble(status: status, isSelected: selectedStatus == status.title) {
                    store.userDidInteract()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selectedStatus = status.title
                    }
                }
                .frame(width: status.size, height: status.size)
                .position(x: proxy.size.width * status.x, y: proxy.size.height * status.y)
            }
        }
        .frame(height: 380)
        .padding(.bottom, 22)
    }

    private var feed: some View {
        LazyVStack(spacing: 18) {
            CommunityGroupPost(
                name: "John Alexander Smith", time: "15 m", status: "Pumping", detail: nil,
                text: "Second letdown is taking its sweet time. I put one tiny lamp on and I am pretending this corner is a tiny night café.",
                assetName: "community-post-1", likeCount: 16, shareCount: 28, commentCount: 3,
                onPreview: { previewAsset = $0 }, onInteraction: { store.userDidInteract() }
            )
            CommunityGroupPost(
                name: "Anonymous", time: "15 m", status: "tired", detail: "Looking for advice",
                text: "The baby monitor is brighter than the moon right now. She is finally asleep, so I am sitting completely still and celebrating quietly.",
                assetName: "community-post-2", likeCount: 20, shareCount: 20, commentCount: 3,
                onPreview: { previewAsset = $0 }, onInteraction: { store.userDidInteract() }
            )
            CommunityGroupPost(
                name: "John Alexander Smith", time: "15 m", status: "Baby sleep", detail: nil,
                text: "Bottle is ready, pump parts are drying, and I just found yesterday’s burp cloth in my hoodie pocket. Calling it a win.",
                assetName: "community-post-3", likeCount: 14, shareCount: 20, commentCount: 3,
                onPreview: { previewAsset = $0 }, onInteraction: { store.userDidInteract() }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 112)
    }
}

private struct CommunityStatus: Identifiable {
    let title: String
    let count: Int
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    var id: String { title }

    static let all = [
        CommunityStatus(title: "pumping", count: 19, size: 86, x: 0.19, y: 0.14),
        CommunityStatus(title: "tired", count: 14, size: 84, x: 0.76, y: 0.14),
        CommunityStatus(title: "need company", count: 18, size: 120, x: 0.45, y: 0.34),
        CommunityStatus(title: "hands full", count: 4, size: 72, x: 0.19, y: 0.38),
        CommunityStatus(title: "can’t sleep", count: 11, size: 81, x: 0.77, y: 0.39),
        CommunityStatus(title: "music on", count: 8, size: 121, x: 0.24, y: 0.72),
        CommunityStatus(title: "baby sleeping", count: 6, size: 100, x: 0.57, y: 0.65),
        CommunityStatus(title: "cluster feeding", count: 1, size: 82, x: 0.80, y: 0.77)
    ]
}

private struct CommunityStatusBubble: View {
    let status: CommunityStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(status.title)
                    .font(.brandMedium(status.size >= 110 ? 18 : 12, relativeTo: .caption))
                    .foregroundStyle(Color.brandPlum)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                HStack(spacing: -4) {
                    bubbleAvatar("S", color: .purple)
                    bubbleAvatar("M", color: .orange)
                    Text("\(status.count)")
                        .font(.brandBody(12, relativeTo: .caption))
                        .foregroundStyle(Color.brandPlum)
                        .padding(.leading, 6)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RadialGradient(
                    colors: [
                        Color(red: 1, green: 241 / 255, blue: 243 / 255),
                        Color(red: 1, green: 192 / 255, blue: 203 / 255),
                        Color(red: 1, green: 241 / 255, blue: 243 / 255)
                    ],
                    center: .top,
                    startRadius: 2,
                    endRadius: status.size * 0.72
                ),
                in: Circle()
            )
            .overlay { Circle().stroke(isSelected ? Color.brandPlum : .clear, lineWidth: 2) }
            .shadow(color: Color.white.opacity(0.8), radius: 6, y: -3)
            .scaleEffect(isSelected ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(status.title), \(status.count) moms")
        .accessibilityValue(isSelected ? "Selected" : "")
    }

    private func bubbleAvatar(_ initial: String, color: Color) -> some View {
        Text(initial)
            .font(.system(size: 5, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(width: 16, height: 16)
            .background(color.opacity(0.72), in: Circle())
    }
}

private struct CommunityAvatarStack: View {
    var body: some View {
        HStack(spacing: -4) {
            avatar("A", .pink)
            avatar("M", .orange)
            avatar("S", .purple)
        }
    }

    private func avatar(_ initial: String, _ color: Color) -> some View {
        Text(initial)
            .font(.system(size: 5, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(width: 16, height: 16)
            .background(color.opacity(0.72), in: Circle())
    }
}

private struct CommunityGroupPost: View {
    let name: String
    let time: String
    let status: String
    let detail: String?
    let text: String
    let assetName: String
    let likeCount: Int
    let shareCount: Int
    let commentCount: Int
    let onPreview: (String) -> Void
    let onInteraction: () -> Void

    @State private var isLiked = false
    @State private var isSaved = false
    @State private var isExpanded = false
    @State private var isHidden = false

    var body: some View {
        if isHidden {
            Button {
                onInteraction()
                withAnimation(.easeInOut(duration: 0.18)) { isHidden = false }
            } label: {
                Label("Post hidden · Undo", systemImage: "arrow.uturn.backward")
                    .font(.brandMedium(13, relativeTo: .footnote))
                    .foregroundStyle(Color.brandPlum)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Text(name.prefix(1))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                        .frame(width: 32, height: 32)
                        .background(Color.brandPlum.opacity(0.72), in: Circle())

                    VStack(alignment: .leading, spacing: 8) {
                        postHeader

                        Button {
                            onInteraction()
                            withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
                        } label: {
                            Text(text)
                                .font(.brandBody(14, relativeTo: .subheadline))
                                .foregroundStyle(Color.brandInk)
                                .tracking(0.28)
                                .lineSpacing(2)
                                .lineLimit(isExpanded ? nil : 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onInteraction()
                            onPreview(assetName)
                        } label: {
                            if let image = FigmaScreenImageLoader.image(named: assetName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .interpolation(.high)
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 194)
                                    .clipped()
                            } else {
                                Color.brandSoft.frame(height: 194)
                            }
                        }
                        .buttonStyle(.plain)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .accessibilityLabel("Open post image")

                        actionRow
                    }
                }
                Divider()
            }
        }
    }

    private var postHeader: some View {
        HStack(alignment: .top, spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.brandMedium(14, relativeTo: .subheadline))
                        .foregroundStyle(Color(red: 27 / 255, green: 24 / 255, blue: 33 / 255))
                    Text("· \(time)")
                        .font(.brandBody(12, relativeTo: .caption))
                        .foregroundStyle(Color(red: 123 / 255, green: 120 / 255, blue: 129 / 255))
                }
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 11))
                    Text(status).font(.brandBody(12, relativeTo: .caption))
                    if let detail {
                        Text(detail)
                            .font(.brandBody(12, relativeTo: .caption))
                            .foregroundStyle(Color.brandInk.opacity(0.44))
                    }
                }
                .foregroundStyle(Color.brandPlum)
            }
            Spacer()
            Menu {
                Button {
                    onInteraction()
                    isSaved.toggle()
                } label: {
                    Label(isSaved ? "Remove bookmark" : "Bookmark", systemImage: "bookmark")
                }
                Button(role: .destructive) {
                    onInteraction()
                    withAnimation(.easeInOut(duration: 0.18)) { isHidden = true }
                } label: {
                    Label("Hide post", systemImage: "eye.slash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.brandInk.opacity(0.44))
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                onInteraction()
                withAnimation(.easeInOut(duration: 0.16)) { isLiked.toggle() }
            } label: {
                Label("\(likeCount + (isLiked ? 1 : 0))", systemImage: isLiked ? "heart.fill" : "heart")
            }
            .foregroundStyle(isLiked ? Color.brandPlum : Color.brandInk.opacity(0.44))

            ShareLink(item: text) {
                Label("\(shareCount)", systemImage: "square.and.arrow.up")
            }
            .simultaneousGesture(TapGesture().onEnded(onInteraction))

            Button(action: {}) {
                Label("\(commentCount)", systemImage: "bubble.left")
            }
            .disabled(true)
            .accessibilityLabel("Comments are unavailable in this demo")

            Spacer()

            Button {
                onInteraction()
                withAnimation(.easeInOut(duration: 0.16)) { isSaved.toggle() }
            } label: {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
            }
            .foregroundStyle(isSaved ? Color.brandPlum : Color.brandInk.opacity(0.44))
        }
        .font(.system(size: 15))
        .foregroundStyle(Color.brandInk.opacity(0.44))
        .buttonStyle(.plain)
    }
}

private struct CommunityStatusPicker: View {
    let statuses: [CommunityStatus]
    @Binding var selectedStatus: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How are you feeling?")
                        .font(.custom(Font.exposureMinus10Name, size: 24, relativeTo: .title2))
                        .foregroundStyle(Color.brandInk)
                    Text("Choose the status that feels closest right now.")
                        .font(.brandBody(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.brandInk.opacity(0.44))

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(statuses) { status in
                            Button {
                                selectedStatus = status.title
                                dismiss()
                            } label: {
                                HStack {
                                    Text(status.title)
                                        .font(.brandMedium(14, relativeTo: .subheadline))
                                    Spacer()
                                    if selectedStatus == status.title {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .foregroundStyle(selectedStatus == status.title ? Color.white : Color.brandInk)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(
                                    selectedStatus == status.title ? Color.brandPlum : Color.brandBlush,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Peer support only. Not medical, mental health, or professional advice.")
                        .font(.brandBody(12, relativeTo: .caption))
                        .foregroundStyle(Color.brandInk.opacity(0.44))
                }
                .padding(20)
            }
            .background(Color.communityCanvas)
            .navigationTitle("Add Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
    }
}

private struct CommunityImagePreview: View {
    let assetName: String
    let dismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let image = FigmaScreenImageLoader.image(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 54)
            .padding(.leading, 16)
        }
    }
}



// These walkthrough frames are the exact 4× exports from the approved
// Group Figma file. SwiftUI adds only interaction and scrolling.
private struct CommunityIntroFigmaScreen: View {
    let assetName: String

    var body: some View {
        GeometryReader { proxy in
            if let image = FigmaScreenImageLoader.image(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .overlay {
                        // The Figma exports include light-gray pixels outside
                        // their rounded device corners. Cover only those two
                        // corner wedges so the dimmed page reaches the top edge.
                        CommunityIntroTopCornerFill()
                            .fill(
                                Color(
                                    red: 172 / 255,
                                    green: 160 / 255,
                                    blue: 163 / 255
                                )
                            )
                    }
            } else {
                Color.communityCanvas
            }
        }
        .ignoresSafeArea()
        .accessibilityLabel("Figma screen \(assetName)")
    }
}

private struct CommunityIntroTopCornerFill: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width * 0.085, rect.height * 0.045)
        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: radius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: radius),
            control: CGPoint(x: 0, y: 0)
        )
        path.closeSubpath()

        path.move(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: radius),
            control: CGPoint(x: rect.maxX, y: 0)
        )
        path.closeSubpath()

        return path
    }
}

struct CommunityIntroDemoView: View {
    @ObservedObject var store: DemoStore
    let step: Int
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var showsReactionHighlight = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch step {
                case 0:
                    CommunityIntroFigmaScreen(assetName: "community-home-hd")

                    advanceTapArea(
                        CGRect(x: 0.03, y: 0.52, width: 0.94, height: 0.13),
                        label: "Open Pumping moms",
                        in: proxy.size
                    )
                    advanceTapArea(
                        CGRect(x: 0.04, y: 0.39, width: 0.92, height: 0.14),
                        label: "Warm Community tip",
                        in: proxy.size
                    )

                case 1:
                    CommunityIntroFigmaScreen(assetName: "community-status-hd")

                    advanceTapArea(
                        CGRect(x: 0.08, y: 0.20, width: 0.84, height: 0.46),
                        label: "Choose a community status",
                        in: proxy.size
                    )
                    advanceTapArea(
                        CGRect(x: 0.04, y: 0.65, width: 0.92, height: 0.14),
                        label: "Share Your Status tip",
                        in: proxy.size
                    )

                default:
                    if showsReactionHighlight {
                        CommunityIntroFigmaScreen(assetName: "community-reaction-hd")
                            .transition(.opacity)

                        advanceTapArea(
                            CGRect(x: 0.08, y: 0.64, width: 0.84, height: 0.10),
                            label: "React to the post",
                            in: proxy.size
                        )
                        advanceTapArea(
                            CGRect(x: 0.04, y: 0.51, width: 0.92, height: 0.15),
                            label: "React to Post tip",
                            in: proxy.size
                        )
                    } else {
                        CommunityExactFigmaScrollView(
                            assetName: "community-group-long-hd",
                            designHeight: 1791
                        ) { offset in
                            guard offset > 240, !showsReactionHighlight else { return }
                            withAnimation(.easeInOut(duration: 0.22)) {
                                showsReactionHighlight = true
                            }
                        }
                    }
                }

                if step > 0 {
                    Button {
                        store.userDidInteract()
                        onBack()
                    } label: {
                        Color.clear.contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: proxy.size.width * 0.18, height: proxy.size.height * 0.11)
                    .position(x: proxy.size.width * 0.10, y: proxy.size.height * 0.10)
                    .accessibilityLabel("Previous community step")
                }
            }
        }
        .ignoresSafeArea()
    }

    private func advanceTapArea(_ rect: CGRect, label: String, in size: CGSize) -> some View {
        Button {
            store.userDidInteract()
            onNext()
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: size.width * rect.width, height: size.height * rect.height)
        .position(x: size.width * rect.midX, y: size.height * rect.midY)
        .accessibilityLabel(label)
    }
}

struct CommunityExactFinalDemoView: View {
    @ObservedObject var store: DemoStore
    let onBack: () -> Void

    @State private var isJoined = false
    @State private var selectedStatus: String?
    @State private var likedPosts: Set<Int> = []
    @State private var favoritePosts: Set<Int> = []
    @State private var savedPosts: Set<Int> = []
    @State private var showsStatusMenu = false
    @State private var previewAsset: String?

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                if let image = FigmaScreenImageLoader.image(named: "community-group-long-hd") {
                    let scale = proxy.size.width / 402

                    ZStack(alignment: .topLeading) {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: proxy.size.width)

                        // The approved long Figma export captured the sticky
                        // "Join & Post" CTA over the first article photo. The
                        // real CTA below is already pinned to the viewport, so
                        // redraw the clean source photo to avoid a duplicate
                        // button appearing as the feed scrolls.
                        if let firstPostImage = FigmaScreenImageLoader.image(
                            named: postPreviewAssets[0]
                        ) {
                            Image(uiImage: firstPostImage)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFill()
                                .frame(width: 330 * scale, height: 215 * scale)
                                .clipped()
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 24 * scale,
                                        style: .continuous
                                    )
                                )
                                .position(
                                    x: 217 * scale,
                                    y: postImageY[0] * scale
                                )
                                .allowsHitTesting(false)
                        }

                        exactButton(
                            label: "Previous community step",
                            x: 38, y: 84, width: 60, height: 60,
                            scale: scale,
                            action: onBack
                        )

                        exactButton(
                            label: isJoined ? "Leave Pumping moms" : "Join Pumping moms",
                            x: 345.5, y: 147.5, width: 96, height: 56,
                            scale: scale
                        ) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                isJoined.toggle()
                            }
                        }

                        if isJoined {
                            Text("Joined")
                                .font(.brandMedium(14 * scale, relativeTo: .subheadline))
                                .foregroundStyle(Color.brandPlum)
                                // Slightly overscan the baked-in Join capsule so
                                // none of its red antialiasing remains visible.
                                .frame(width: 84 * scale, height: 44 * scale)
                                .background(Color.white, in: Capsule())
                                .overlay { Capsule().stroke(Color.brandPlum.opacity(0.16)) }
                                .position(x: 345.5 * scale, y: 147.5 * scale)
                                .allowsHitTesting(false)
                        }

                        exactButton(
                            label: "Share your status",
                            x: 340, y: 260, width: 110, height: 50,
                            scale: scale
                        ) {
                            showsStatusMenu = true
                        }

                        ForEach(Array(statusTargets.enumerated()), id: \.offset) { _, target in
                            exactButton(
                                label: target.label,
                                x: target.x, y: target.y,
                                width: target.size, height: target.size,
                                scale: scale
                            ) {
                                withAnimation(.easeInOut(duration: 0.16)) {
                                    selectedStatus = target.label
                                }
                            }

                            if selectedStatus == target.label {
                                let ringSize = target.size - 3
                                let ringTop = target.y - ringSize / 2
                                let visibleRingHeight = min(
                                    ringSize,
                                    statusComposerTopY - ringTop
                                )

                                Circle()
                                    .strokeBorder(Color.brandPlum, lineWidth: 2 * scale)
                                    .frame(
                                        width: ringSize * scale,
                                        height: ringSize * scale
                                    )
                                    .mask(alignment: .top) {
                                        Rectangle()
                                            .frame(height: visibleRingHeight * scale)
                                    }
                                    .position(x: target.x * scale, y: target.y * scale)
                                    .allowsHitTesting(false)
                            }
                        }

                        ForEach(0..<3, id: \.self) { index in
                            let actionY = postActionY[index]

                            exactButton(
                                label: likedPosts.contains(index) ? "Unlike post" : "Like post",
                                x: 49, y: actionY, width: 56, height: 42,
                                scale: scale
                            ) {
                                toggle(index, in: &likedPosts)
                            }

                            if likedPosts.contains(index) {
                                Label("1", systemImage: "hand.thumbsup.fill")
                                    .font(.system(size: 12 * scale, weight: .regular))
                                    .foregroundStyle(Color.brandPlum)
                                    .frame(width: 52 * scale, height: 28 * scale)
                                    .background(Color.communityCanvas)
                                    .position(x: 49 * scale, y: actionY * scale)
                                    .allowsHitTesting(false)
                            }

                            exactButton(
                                label: favoritePosts.contains(index) ? "Remove reaction" : "React to post",
                                x: 93, y: actionY, width: 48, height: 42,
                                scale: scale
                            ) {
                                toggle(index, in: &favoritePosts)
                            }

                            if favoritePosts.contains(index) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 15 * scale))
                                    .foregroundStyle(Color.brandPlum)
                                    .frame(width: 42 * scale, height: 28 * scale)
                                    .background(Color.communityCanvas)
                                    .position(x: 93 * scale, y: actionY * scale)
                                    .allowsHitTesting(false)
                            }

                            ShareLink(item: postShareText[index]) {
                                Color.clear.contentShape(Rectangle())
                            }
                            .simultaneousGesture(TapGesture().onEnded { store.userDidInteract() })
                            .frame(width: 48 * scale, height: 42 * scale)
                            .position(x: 139 * scale, y: actionY * scale)
                            .accessibilityLabel("Share post")

                            exactButton(
                                label: savedPosts.contains(index) ? "Remove bookmark" : "Bookmark post",
                                x: 345, y: actionY, width: 56, height: 42,
                                scale: scale
                            ) {
                                toggle(index, in: &savedPosts)
                            }

                            if savedPosts.contains(index) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 15 * scale))
                                    .foregroundStyle(Color.brandPlum)
                                    .frame(width: 42 * scale, height: 28 * scale)
                                    .background(Color.communityCanvas)
                                    .position(x: 345 * scale, y: actionY * scale)
                                    .allowsHitTesting(false)
                            }

                            exactButton(
                                label: "Open post image",
                                x: 217, y: postImageY[index], width: 330, height: 215,
                                scale: scale
                            ) {
                                previewAsset = postPreviewAssets[index]
                            }
                        }
                    }
                    .frame(width: proxy.size.width, height: 1791 * scale, alignment: .topLeading)
                }
            }
            .scrollIndicators(.visible)
            .overlay(alignment: .bottom) {
                Button {
                    store.userDidInteract()
                    store.showDemoUnavailableToast()
                } label: {
                    Text(isJoined ? "Post" : "Join & Post")
                        .font(.brandMedium(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.white)
                        .frame(width: 135, height: 44)
                        .background(Color.brandPlum, in: Capsule())
                        .shadow(color: .black.opacity(0.14), radius: 20, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 28)
                .accessibilityLabel("Posting is unavailable in this demo")
            }
        }
        .ignoresSafeArea()
        .confirmationDialog("Share your status", isPresented: $showsStatusMenu, titleVisibility: .visible) {
            ForEach(statusTargets.map(\.label), id: \.self) { status in
                Button(status) {
                    store.userDidInteract()
                    selectedStatus = status
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { previewAsset != nil },
                set: { if !$0 { previewAsset = nil } }
            )
        ) {
            CommunityImagePreview(assetName: previewAsset ?? "community-post-1") {
                previewAsset = nil
            }
        }
    }

    private func exactButton(
        label: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            store.userDidInteract()
            action()
        } label: {
            Color.clear.contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: width * scale, height: height * scale)
        .position(x: x * scale, y: y * scale)
        .accessibilityLabel(label)
    }

    private func toggle(_ index: Int, in set: inout Set<Int>) {
        if set.contains(index) {
            set.remove(index)
        } else {
            set.insert(index)
        }
    }

    private var statusTargets: [(label: String, x: CGFloat, y: CGFloat, size: CGFloat)] {
        [
            ("pumping", 73, 351, 86),
            ("tired", 298, 350, 84),
            ("need company", 178, 417, 120),
            ("hands full", 80, 443, 72),
            ("can’t sleep", 305, 442, 81),
            ("music on", 95, 565, 121),
            ("baby sleeping", 225, 529, 100),
            ("cluster feeding", 315, 580, 82)
        ]
    }

    // The composer is baked over the bottom of the final two bubbles in the
    // Figma export. Selection rings stop at its top edge instead of drawing
    // over the composer artwork.
    private let statusComposerTopY: CGFloat = 589

    // These targets follow the image and action-row positions baked into the
    // approved 402 × 1791 Figma export. Keeping them aligned prevents invisible
    // controls from landing on the neighbouring article while the page scrolls.
    private let postActionY: [CGFloat] = [1012, 1384, 1754]
    private let postImageY: [CGFloat] = [885, 1260, 1630]

    // The first two photos appear in this order in community-group-long-hd.
    // Preview the same source photo that is visible on each article card.
    private let postPreviewAssets = [
        "community-post-2",
        "community-post-1",
        "community-post-3"
    ]

    private let postShareText = [
        "Second letdown is taking its sweet time. I put one tiny lamp on and I am pretending this corner is a tiny night café.",
        "The baby monitor is brighter than the moon right now. She is finally asleep, so I am sitting completely still and celebrating quietly.",
        "Bottle is ready, pump parts are drying, and I just found yesterday’s burp cloth in my hoodie pocket. Calling it a win."
    ]
}

private struct CommunityExactFigmaScrollView: View {
    let assetName: String
    let designHeight: CGFloat
    let onScroll: (CGFloat) -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: CommunityExactScrollOffsetKey.self,
                        value: -geometry.frame(in: .named("communityExactScroll")).minY
                    )
                }
                .frame(height: 0)

                if let image = FigmaScreenImageLoader.image(named: assetName) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: proxy.size.width)
                        .accessibilityLabel("Pumping moms group")
                }
            }
            .coordinateSpace(name: "communityExactScroll")
            .scrollIndicators(.visible)
            .onPreferenceChange(CommunityExactScrollOffsetKey.self, perform: onScroll)
        }
    }
}

private struct CommunityExactScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension Color {
    static let communityCanvas = Color(
        red: 249 / 255,
        green: 247 / 255,
        blue: 245 / 255
    )
}
