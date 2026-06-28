import SwiftUI
import UIKit

extension ContentView {
    var moodSection: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    MoodCardView()
                    featuredMoodCard
                    myMoodEntriesCard
                }
                .padding(.bottom, 120)
            }
            .zIndex(1)

            RunningCompanionView()
                .zIndex(2)
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical)
    }

    var featuredMoodCard: some View {
        Button {
            if let featuredMoodEntryForToday {
                editingMoodEntry = featuredMoodEntryForToday
            } else {
                isShowingMoodEntryAddSheet = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                if let entry = featuredMoodEntryForToday {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("“\(entry.content)”")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("创建于 \(featuredMoodCreatedDateText(entry.createdAt))")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.78))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("还没有自定义心情")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("写下几条属于你自己的心情，这里每天都会随机展示一条。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.14), Color.purple.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .pink.opacity(0.08), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    func featuredMoodCreatedDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    var myMoodEntriesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("我的心情")
                .font(.title3.bold())

            if sortedMoodEntries.isEmpty {
                AppEmptyState(
                    title: "还没有心情",
                    systemImage: "heart.text.square",
                    description: "把这一刻的感受写下来，之后每天都会随机展示一条给你。"
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedMoodEntries) { entry in
                        MoodEntryRow(
                            entry: entry,
                            onEdit: {
                                editingMoodEntry = entry
                            },
                            onDelete: {
                                deleteMoodEntry(entry)
                            }
                        )
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

struct RunningCompanionView: View {
    @AppStorage("companionAnimal") private var companionRaw = CompanionAnimal.default.rawValue
    @AppStorage("isCompanionAnimalEnabled") private var isEnabled = true

    @State private var position: CGPoint = CGPoint(x: 100, y: 100)
    @State private var isFacingRight: Bool = false
    @State private var containerSize: CGSize = .zero
    @State private var isHopping = false

    private let moveDuration: TimeInterval = 2.6
    private let moveTimer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()

    private var animal: CompanionAnimal {
        CompanionAnimal(rawValue: companionRaw) ?? .default
    }

    var body: some View {
        Group {
            if isEnabled {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            containerSize = geometry.size
                            position = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            startHopping()
                            moveToNextPoint()
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            containerSize = newSize
                            if position == .zero {
                                position = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
                            }
                        }
                        .allowsHitTesting(false)

                    CompanionAnimalView(animal: animal)
                        .frame(width: 96, height: 108)
                        .scaleEffect(x: isFacingRight ? 1 : -1, y: 1)
                        .rotationEffect(.degrees(isHopping ? 3 : -3))
                        .offset(y: isHopping ? -10 : 6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            moveToNextPoint()
                        }
                        .position(position)
                        .opacity(containerSize == .zero ? 0 : 1)
                        .animation(.linear(duration: moveDuration), value: position)
                }
                .onReceive(moveTimer) { _ in
                    moveToNextPoint()
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: isEnabled) { _, newValue in
            guard newValue else {
                containerSize = .zero
                position = CGPoint(x: 100, y: 100)
                isFacingRight = false
                isHopping = false
                return
            }

            startHopping()
            if position == .zero, containerSize != .zero {
                position = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
            } else if containerSize != .zero {
                moveToNextPoint()
            }
        }
    }

    private func startHopping() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            isHopping = true
        }
    }

    private func moveToNextPoint() {
        guard containerSize.width > 0, containerSize.height > 0 else { return }

        let horizontalMargin: CGFloat = 48
        let verticalMargin: CGFloat = 44
        let minX = min(horizontalMargin, containerSize.width / 2)
        let maxX = max(minX, containerSize.width - horizontalMargin)
        let minY = min(verticalMargin, containerSize.height / 2)
        let maxY = max(minY, containerSize.height - verticalMargin)

        var nextPoint = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )

        for _ in 0..<8 {
            let candidate = CGPoint(
                x: CGFloat.random(in: minX...maxX),
                y: CGFloat.random(in: minY...maxY)
            )
            let distance = sqrt(pow(candidate.x - position.x, 2) + pow(candidate.y - position.y, 2))
            if distance > 90 {
                nextPoint = candidate
                break
            }
        }

        isFacingRight = nextPoint.x > position.x
        position = nextPoint
    }
}

struct MoodCardView: View {
    @Environment(\.displayScale) private var displayScale

    @StateObject private var jokeService = JokeService.shared
    @State private var cardScale: CGFloat = 1.0
    @State private var sharePreviewPayload: MoodCardSharePayload?

    private var shareableJoke: String {
        jokeService.currentJoke.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                refreshJoke()
            } label: {
                VStack(spacing: 24) {
                    HStack {
                        Label("开心一刻", systemImage: "face.smiling")
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                        Spacer(minLength: 86)
                    }

                    Text(jokeService.currentJoke)
                        .font(.title3.weight(.medium))
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary.opacity(0.85))
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding(.horizontal, 10)
                        .animation(.easeInOut, value: jokeService.currentJoke)
                }
            }
            .buttonStyle(.plain)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .orange.opacity(0.08), radius: 15, x: 0, y: 6)
            .scaleEffect(cardScale)

            HStack(spacing: 10) {
                if jokeService.isLoading {
                    ProgressView()
                        .tint(.orange)
                }

                Button {
                    shareCurrentJoke()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.orange.opacity(0.92))
                        .padding(6)
                }
                .buttonStyle(.plain)
                .disabled(shareableJoke.isEmpty)
                .opacity(shareableJoke.isEmpty ? 0.45 : 1)
                .accessibilityLabel("分享开心一刻")
                .accessibilityHint("查看分享预览")
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
        .sheet(item: $sharePreviewPayload) { payload in
            MoodSharePreviewSheet(payload: payload)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func refreshJoke() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cardScale = 0.96
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                cardScale = 1.0
            }
        }
        Task {
            await jokeService.fetchJoke()
        }
    }

    private func shareCurrentJoke() {
        guard !shareableJoke.isEmpty else { return }
        guard let image = makeShareImage() else { return }
        sharePreviewPayload = MoodCardSharePayload(image: image)
    }

    private func makeShareImage() -> UIImage? {
        let renderer = ImageRenderer(
            content: MoodShareImageCard(joke: shareableJoke)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = max(displayScale, 2.0)
        return renderer.uiImage
    }
}

private struct MoodCardSharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct MoodShareSaveFeedback {
    let title: String
    let message: String
}

private struct MoodSharePreviewSheet: View {
    let payload: MoodCardSharePayload

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingActivitySheet = false
    @State private var saveFeedback: MoodShareSaveFeedback?
    @State private var imageSaver = MoodShareImageSaver()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(uiImage: payload.image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
                    }
                    .padding(20)
                }

                HStack(spacing: 12) {
                    Button("保存到相册") {
                        imageSaver.save(payload.image) { result in
                            switch result {
                            case .success:
                                saveFeedback = MoodShareSaveFeedback(
                                    title: "已保存",
                                    message: "图片已经保存到系统相册。"
                                )
                            case .failure:
                                saveFeedback = MoodShareSaveFeedback(
                                    title: "保存失败",
                                    message: "这次没有成功保存到相册，请稍后再试。"
                                )
                            }
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.orange.opacity(0.10), lineWidth: 1)
                    }

                    Button("继续分享") {
                        isShowingActivitySheet = true
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.orange.opacity(0.22), radius: 10, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("分享预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $isShowingActivitySheet) {
            ActivityShareSheet(
                activityItems: [payload.image],
                applicationActivities: nil
            )
        }
        .alert(
            saveFeedback?.title ?? "",
            isPresented: Binding(
                get: { saveFeedback != nil },
                set: { isPresented in
                    if !isPresented {
                        saveFeedback = nil
                    }
                }
            ),
            presenting: saveFeedback
        ) { _ in
            Button("知道了", role: .cancel) {}
        } message: { feedback in
            Text(feedback.message)
        }
    }
}

private struct MoodShareImageCard: View {
    let joke: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.18),
                            Color.yellow.opacity(0.10),
                            Color.pink.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 28) {
                Label("开心一刻", systemImage: "face.smiling.fill")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.orange)

                VStack(alignment: .leading, spacing: 12) {
                    Text(joke)
                        .font(.system(size: 34, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.88))
                        .lineSpacing(10)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(34)
            .background(Color.white.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.2)
            }
            .padding(26)
        }
        .frame(width: 430)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private final class MoodShareImageSaver: NSObject {
    private var completion: ((Result<Void, Error>) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc
    private func saveCompleted(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        if let error {
            completion?(.failure(error))
        } else {
            completion?(.success(()))
        }
        completion = nil
    }
}

struct MoodEntryRow: View {
    let entry: MoodEntry
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil

    private var condensedContent: String {
        entry.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(entry.lastActivityAt, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        let prefix = entry.updatedAt == nil ? "创建于 " : "更新于 "
        return prefix + formatter.string(from: entry.lastActivityAt)
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title3)
                    .foregroundStyle(.pink)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 5) {
                    Text(condensedContent)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(dateText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16, style: .continuous))
        .longPressActions(
            DeleteConfirmationContent(
                title: "删除心情？",
                message: "这条心情会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete,
            isPinned: false,
            onTogglePin: nil,
            presentation: .contextMenu
        )
    }
}

struct MoodEntryEditorSheet: View {
    let entry: MoodEntry?
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var contentInput: String
    @FocusState private var isContentFocused: Bool

    init(entry: MoodEntry?, onSave: @escaping (String) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _contentInput = State(initialValue: entry?.content ?? "")
    }

    private var canSave: Bool {
        !contentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var createdTimeText: String? {
        guard let entry else { return nil }
        return "创建于 \(metaDateText(entry.createdAt))"
    }

    private var editedTimeText: String? {
        guard let updatedAt = entry?.updatedAt else { return nil }
        return "更新于 \(metaDateText(updatedAt))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ZStack(alignment: .topLeading) {
                        if contentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("随便写点什么吧，写的内容后续可能会随机展示在上方")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 14)
                                .padding(.horizontal, 14)
                        }

                        TextEditor(text: $contentInput)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 220)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .focused($isContentFocused)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if createdTimeText != nil || editedTimeText != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            if let createdTimeText {
                                Text(createdTimeText)
                            }
                            if let editedTimeText {
                                Text(editedTimeText)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(entry == nil ? "新增心情" : "编辑心情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(entry == nil ? "添加" : "完成") {
                        onSave(contentInput.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isContentFocused = true
            }
        }
    }

    func metaDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}
