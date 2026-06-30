import PhotosUI
import SwiftUI

extension TodoPriority {
    var color: Color {
        switch self {
        case .importantUrgent: return .red
        case .importantNotUrgent: return .orange
        case .urgentNotImportant: return .blue
        case .notImportantNotUrgent: return .gray
        }
    }
}

struct TodoTaskRow: View {
    let task: TodoTask
    let onMarkPending: () -> Void
    let onMarkInProgress: () -> Void
    let onMarkCompleted: () -> Void
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil
    var onTogglePin: (() -> Void)? = nil

    @State private var isShowingStatusPopover = false
    @State private var isShowingRestoreConfirm = false
    @State private var isCelebratingCompletion = false

    private var completedDateText: String? {
        guard let completedAt = task.completedAt,
              task.isCompleted,
              !isCelebratingCompletion else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: completedAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: handleToggleTap) {
                Image(systemName: statusSymbolName)
                    .font(.title2)
                    .foregroundStyle(statusTint)
                    .scaleEffect(isCelebratingCompletion ? 1.18 : 1)
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $isShowingStatusPopover) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(statusDialogTitle)
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(statusDialogMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        primaryStatusActionButton
                        secondaryStatusActionButton
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(width: 332)
                .presentationCompactAdaptation(.popover)
            }

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .strikethrough(task.isCompleted || isCelebratingCompletion)
                        .foregroundStyle(task.isCompleted || isCelebratingCompletion ? .secondary : .primary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        if task.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .rotationEffect(.degrees(45))
                        }

                        if task.isInProgress && !isCelebratingCompletion {
                            TodoTaskStatusBadge(status: .inProgress)
                        }

                        TodoPriorityBadge(priority: task.priority)

                        if let dueDate = task.dueDate, !task.isCompleted, !isCelebratingCompletion {
                            TodoDueBadge(dueDate: dueDate)
                        }

                        if let completedDateText {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(completedDateText)
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green.opacity(0.82))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.10), in: Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(rowBackgroundColor)
        )
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .trailing) {
            if isCelebratingCompletion {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("完成")
                }
                .font(.caption.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.14), in: Capsule())
                .padding(.trailing, 42)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isCelebratingCompletion ? 1.015 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isCelebratingCompletion)
        .alert("恢复到待处理？", isPresented: $isShowingRestoreConfirm) {
            Button("恢复到待处理", role: .cancel) {
                onMarkPending()
            }
            Button("取消") {}
        } message: {
            Text("「\(condensedTaskTitle)」会回到上方待处理列表。")
        }
        .id("\(task.id)-\(task.isPinned)-\(task.status.rawValue)")
        .longPressActions(
            DeleteConfirmationContent(
                title: "删除待办？",
                message: "「\(task.title)」会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete,
            isPinned: task.isPinned,
            onTogglePin: onTogglePin,
            presentation: .contextMenu
        )
    }

    private var statusSymbolName: String {
        if isCelebratingCompletion {
            return "checkmark.circle.fill"
        }

        switch task.status {
        case .pending:
            return "circle"
        case .inProgress:
            return "circle.inset.filled"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    private var statusTint: Color {
        if isCelebratingCompletion {
            return .green
        }

        switch task.status {
        case .pending:
            return Color(.systemGray3)
        case .inProgress:
            return .blue.opacity(0.90)
        case .completed:
            return .green
        }
    }

    private var rowBackgroundColor: Color {
        if isCelebratingCompletion {
            return Color.green.opacity(0.12)
        }

        return Color(.tertiarySystemGroupedBackground)
    }

    private var statusDialogTitle: String {
        switch task.status {
        case .pending:
            return "更新这个 TODO 的状态？"
        case .inProgress:
            return "进行中的 TODO 要怎么处理？"
        case .completed:
            return "已完成"
        }
    }

    private var condensedTaskTitle: String {
        let normalized = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count > 20 else { return normalized }
        return String(normalized.prefix(20)) + "..."
    }

    private var statusDialogMessage: String {
        switch task.status {
        case .pending:
            return "你可以先标成进行中，或者直接确认完成。"
        case .inProgress:
            return "「\(condensedTaskTitle)」可以继续流转到已完成，或者恢复为待处理。"
        case .completed:
            return "「\(condensedTaskTitle)」已经完成。"
        }
    }

    private var secondaryStatusActionTitle: String {
        task.isInProgress ? "待处理" : "进行中"
    }

    private var secondaryStatusActionTint: Color {
        task.isInProgress ? .secondary : .blue
    }

    private var primaryStatusActionButton: some View {
        Button {
            celebrateAndComplete()
        } label: {
            Text("确认完成")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(Color.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.green.opacity(0.16), radius: 8, y: 4)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    private var secondaryStatusActionButton: some View {
        Button {
            handleSecondaryStatusAction()
        } label: {
            Text(secondaryStatusActionTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryStatusActionTint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(
            secondaryStatusActionTint.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(secondaryStatusActionTint.opacity(0.08), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    private func handleToggleTap() {
        guard !isCelebratingCompletion else { return }

        if task.isCompleted {
            isShowingRestoreConfirm = true
        } else {
            isShowingStatusPopover = true
        }
    }

    private func handleSecondaryStatusAction() {
        isShowingStatusPopover = false
        if task.isInProgress {
            onMarkPending()
        } else {
            onMarkInProgress()
        }
    }

    private func celebrateAndComplete() {
        isShowingStatusPopover = false
        withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
            isCelebratingCompletion = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            onMarkCompleted()
            isCelebratingCompletion = false
        }
    }
}

struct TodoTaskStatusBadge: View {
    let status: TodoTaskStatus

    private var tint: Color {
        switch status {
        case .pending:
            return .secondary.opacity(0.82)
        case .inProgress:
            return .blue.opacity(0.82)
        case .completed:
            return .green.opacity(0.82)
        }
    }

    var body: some View {
        Text(status.title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

struct TodoPriorityBadge: View {
    let priority: TodoPriority

    private var tint: Color {
        switch priority {
        case .importantUrgent:
            return .red.opacity(0.72)
        case .importantNotUrgent:
            return .orange.opacity(0.72)
        case .urgentNotImportant:
            return .blue.opacity(0.72)
        case .notImportantNotUrgent:
            return .secondary.opacity(0.82)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(priority.title)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(tint.opacity(0.10), in: Capsule())
    }
}

struct TodoDueBadge: View {
    let dueDate: Date

    private var isOverdue: Bool { dueDate < Date() }
    private var tint: Color { isOverdue ? .red.opacity(0.70) : .orange.opacity(0.72) }

    private var dueText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: dueDate)
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "calendar.badge.clock")
                .font(.system(size: 9, weight: .bold))
            Text(dueText)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(tint.opacity(0.10), in: Capsule())
    }
}

struct WishlistRow: View {
    let item: WishlistItem
    let category: WishlistCategory
    let onToggle: () -> Void
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil
    var onTogglePin: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : category.icon)
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? .green : .blue)
                    .frame(width: 26)
            }
            .buttonStyle(.borderless)

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .rotationEffect(.degrees(45))
                        }

                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)
                            .multilineTextAlignment(.leading)

                        Text(category.title)
                            .font(.caption2.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.14))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }

                    if !item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(item.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
        .id("\(item.id)-\(item.isPinned)")
        .longPressActions(
            DeleteConfirmationContent(
                title: "删除愿望？",
                message: "「\(item.title)」会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete,
            isPinned: item.isPinned,
            onTogglePin: onTogglePin
        )
    }
}

struct MemoNoteCard: View {
    let note: MemoNote
    let dateText: String
    let imageDatas: [Data]
    let onTagTap: (String) -> Void
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil
    var onTogglePin: (() -> Void)? = nil
    @State private var isShowingImagePreview = false
    @State private var selectedPreviewIndex = 0
    @State private var isExpanded = false

    private var previewText: String {
        note.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var previewImages: [UIImage] {
        imageDatas.compactMap(UIImage.init(data:))
    }

    private var shouldShowExpandToggle: Bool {
        previewText.count > 90 || previewText.filter { $0 == "\n" }.count >= 4
    }

    private var previewImageColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(86), spacing: 8), count: min(max(previewImages.count, 1), 3))
    }

    private var combinedPreviewText: Text {
        var result = Text("")
        
        if !note.tags.isEmpty {
            for tag in note.tags {
                if let encoded = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                    result = result + Text(.init("[#\(tag)](memotag:\(encoded)) ")).font(.subheadline.bold())
                } else {
                    result = result + Text("#\(tag) ").font(.subheadline.bold()).foregroundColor(.blue)
                }
            }
        }
        
        if !previewText.isEmpty {
            result = result + Text(previewText).font(.subheadline).foregroundColor(.primary)
        }
        
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .rotationEffect(.degrees(45))
                }
            }

            if !previewText.isEmpty || !note.tags.isEmpty {
                combinedPreviewText
                    .tint(.blue)
                    .environment(\.openURL, OpenURLAction { url in
                        if url.scheme == "memotag" {
                            // url.path 会自动进行一定的 decode，但是这里为了保险起见，直接用 absoluteString 截取
                            let prefix = "memotag:"
                            if let encodedTag = url.absoluteString.components(separatedBy: prefix).last,
                               let tag = encodedTag.removingPercentEncoding {
                                onTagTap(tag)
                                return .handled
                            }
                        }
                        return .systemAction
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isExpanded ? nil : 5)
            }

            if shouldShowExpandToggle {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "收起" : "展开")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            if !imageDatas.isEmpty {
                LazyVGrid(columns: previewImageColumns, alignment: .leading, spacing: 8) {
                    ForEach(Array(previewImages.enumerated()), id: \.offset) { index, uiImage in
                        Button {
                            selectedPreviewIndex = index
                            isShowingImagePreview = true
                        } label: {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 86, height: 86)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .id("\(note.id)-\(note.isPinned)")
        .longPressActions(
            DeleteConfirmationContent(
                title: "删除笔记？",
                message: "这条笔记会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete,
            isPinned: note.isPinned,
            onTogglePin: onTogglePin
        )
        .fullScreenCover(isPresented: $isShowingImagePreview) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                TabView(selection: $selectedPreviewIndex) {
                    ForEach(Array(previewImages.enumerated()), id: \.offset) { index, uiImage in
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(20)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isShowingImagePreview = false
                            }
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: previewImages.count > 1 ? .automatic : .never))

                Button {
                    isShowingImagePreview = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(20)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AnniversaryRow: View {
    let item: AnniversaryItem
    let dateText: String
    let solarText: String?
    let daysUntil: Int?
    let elapsedText: String?
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil
    var onTogglePin: (() -> Void)? = nil

    private var isToday: Bool { (daysUntil ?? -1) == 0 }

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .rotationEffect(.degrees(45))
                        }
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }

                    Text(dateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let solarText {
                        Text(solarText)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if let elapsedText {
                        Text(elapsedText)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.14))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 8)

                countdownView
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .id("\(item.id)-\(item.isPinned)")
        .longPressActions(
            DeleteConfirmationContent(
                title: "删除纪念日？",
                message: "「\(item.title)」会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete,
            isPinned: item.isPinned,
            onTogglePin: onTogglePin
        )
    }

    @ViewBuilder
    private var countdownView: some View {
        if isToday {
            VStack(spacing: 2) {
                Image(systemName: "party.popper.fill")
                    .font(.title3)
                Text("就是今天")
                    .font(.caption.bold())
            }
            .foregroundStyle(.blue)
            .frame(minWidth: 64)
        } else if let days = daysUntil, days > 0 {
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                Text("天后")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 64)
        }
    }
}

struct StockResearchRow: View {
    let item: StockResearchItem
    let updatedText: String
    let onOpen: () -> Void
    var onDelete: (() -> Void)? = nil
    var onTogglePin: (() -> Void)? = nil

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "chart.line.text.clipboard")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }

                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    if let preview = stockResearchPreview {
                        Text(preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text("更新于 \(updatedText)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("还没有研究笔记 · 更新于 \(updatedText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if hasRatings {
                        HStack(spacing: 6) {
                            ratingBadge("确定", item.certainty, tint: .green)
                            ratingBadge("成长", item.growth, tint: .orange)
                            ratingBadge("关注", item.attention, tint: .blue)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()

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
        }
        .buttonStyle(.plain)
        .longPressActions(
            DeleteConfirmationContent(
                title: "删除股票？",
                message: "「\(item.name)」及其研究笔记会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete,
            isPinned: item.isPinned,
            onTogglePin: onTogglePin
        )
    }

    var stockResearchPreview: String? {
        let trimmed = item.thesis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return trimmed
            .split(whereSeparator: \.isNewline)
            .prefix(2)
            .joined(separator: " ")
    }

    var hasRatings: Bool {
        item.certainty != nil || item.growth != nil || item.attention != nil
    }

    @ViewBuilder
    func ratingBadge(_ label: String, _ rating: StockRating?, tint: Color) -> some View {
        if let rating {
            HStack(spacing: 3) {
                Text(label)
                    .foregroundStyle(.secondary)
                Text(rating.title)
                    .fontWeight(.bold)
                    .foregroundStyle(tint)
            }
            .font(.caption2)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
        }
    }
}

struct StockResearchAddSheet: View {
    @Binding var name: String
    var showsSuggestions: Bool = true
    let onAdd: () -> Void
    let onCancel: () -> Void

    @FocusState private var isNameFocused: Bool

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("名称")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ModernInputField(
                            placeholder: "股票名称",
                            text: $name,
                            icon: "magnifyingglass",
                            tint: .blue
                        )
                        .focused($isNameFocused)
                    }

                    if showsSuggestions {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("快速添加")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            let suggestions = ["贵州茅台", "腾讯控股", "苹果", "英伟达", "宁德时代"]
                            FlexibleChips(items: suggestions) { suggestion in
                                name = suggestion
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("新增股票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加", action: onAdd)
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .disabled(!canAdd)
                }
            }
        }
        .presentationDetents([.height(showsSuggestions ? 380 : 280)])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isNameFocused = true
            }
        }
    }
}

struct FlexibleChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunkedItems, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            onTap(item)
                        } label: {
                            Text(item)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.10), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedItems: [[String]] {
        var rows: [[String]] = []
        var current: [String] = []
        for item in items {
            current.append(item)
            if current.count == 3 {
                rows.append(current)
                current = []
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}

struct StockResearchEditorSheet: View {
    let item: StockResearchItem
    @Binding var thesis: String
    let onRename: (String) -> Void
    let onSaveRatings: (StockRating?, StockRating?, StockRating?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nameInput: String
    @State private var certainty: StockRating?
    @State private var growth: StockRating?
    @State private var attention: StockRating?
    @FocusState private var isThesisFocused: Bool

    private let thesisAnchor = "thesisEditor"

    init(
        item: StockResearchItem,
        thesis: Binding<String>,
        onRename: @escaping (String) -> Void,
        onSaveRatings: @escaping (StockRating?, StockRating?, StockRating?) -> Void
    ) {
        self.item = item
        _thesis = thesis
        self.onRename = onRename
        self.onSaveRatings = onSaveRatings
        _nameInput = State(initialValue: item.name)
        _certainty = State(initialValue: item.certainty)
        _growth = State(initialValue: item.growth)
        _attention = State(initialValue: item.attention)
    }

    private var createdTimeText: String {
        "创建于 \(metaDateText(item.createdAt))"
    }

    private var editedTimeText: String? {
        guard item.updatedAt != item.createdAt else { return nil }
        return "编辑于 \(metaDateText(item.updatedAt))"
    }

    private var thesisEditorFont: UIFont {
        .preferredFont(forTextStyle: .subheadline)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("股票名称")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            TextField("股票名称", text: $nameInput)
                                .font(.title3.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                            Text("股票分析")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        GeometryReader { proxy in
                            TextEditor(text: $thesis)
                                .font(.subheadline)
                                .focused($isThesisFocused)
                                .scrollContentBackground(.hidden)
                                .frame(height: thesisEditorHeight(width: proxy.size.width))
                                .padding(8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(alignment: .topLeading) {
                                    if thesis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text("写下你对这只股票的理解：商业模式、护城河、估值、风险、跟踪点……")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }
                        .frame(height: thesisEditorHeight(width: UIScreen.main.bounds.width - 32))
                        .padding(.horizontal)
                        .padding(.bottom)
                        .id(thesisAnchor)

                        VStack(spacing: 10) {
                            StockRatingPicker(title: "确定性", hint: "未来大概率不会亏", tint: .green, selection: $certainty)
                            StockRatingPicker(title: "成长性", hint: "营收利润大涨的可能", tint: .orange, selection: $growth)
                            StockRatingPicker(title: "关注度", hint: "要不要多花精力跟踪", tint: .blue, selection: $attention)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(createdTimeText)
                            if let editedTimeText {
                                Text(editedTimeText)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isThesisFocused) { _, focused in
                    if focused {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(thesisAnchor, anchor: .top)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("股票研究")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.subheadline)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty, trimmedName != item.name {
                            onRename(trimmedName)
                        }
                        onSaveRatings(certainty, growth, attention)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("收起键盘") {
                        isThesisFocused = false
                    }
                    .font(.subheadline.bold())
                }
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

    private func thesisEditorHeight(width: CGFloat) -> CGFloat {
        let horizontalPadding: CGFloat = 28
        let verticalPadding: CGFloat = 28
        let lineHeight = ceil(thesisEditorFont.lineHeight)
        let textWidth = max(1, width - horizontalPadding)
        let rows = max(5, thesisVisualLineCount(width: textWidth) + 2)
        return CGFloat(rows) * lineHeight + verticalPadding
    }

    private func thesisVisualLineCount(width: CGFloat) -> Int {
        let text = thesis.isEmpty ? " " : thesis
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: thesisEditorFont],
            context: nil
        )
        return max(1, Int(ceil(boundingRect.height / max(1, thesisEditorFont.lineHeight))))
    }
}

struct StockRatingPicker: View {
    let title: String
    let hint: String
    let tint: Color
    @Binding var selection: StockRating?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(StockRating.allCases) { rating in
                    let isSelected = selection == rating
                    Button {
                        selection = isSelected ? nil : rating
                    } label: {
                        Text(rating.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : Color.secondary.opacity(0.6))
                            .frame(width: 38, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(Color(.tertiarySystemFill)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct TodoPriorityOptionalSelector: View {
    @Binding var selection: TodoPriority?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(TodoPriority.allCases) { priority in
                let isSelected = selection == priority
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        selection = priority
                    }
                } label: {
                    HStack(spacing: 0) {
                        Text(priority.title)
                            .font(.subheadline.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(isSelected ? priority.color.opacity(0.95) : Color.primary.opacity(0.72))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected
                        ? AnyShapeStyle(priority.color.opacity(0.14))
                        : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected ? priority.color.opacity(0.28) : Color(.separator).opacity(0.10),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FinanceAssetEditorSheet: View {
    let asset: FinanceAsset
    let onSave: (String, FinanceAssetKind, Double, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nameInput: String
    @State private var kind: FinanceAssetKind
    @State private var amountInput: String
    @State private var noteInput: String

    init(asset: FinanceAsset, onSave: @escaping (String, FinanceAssetKind, Double, String) -> Void) {
        self.asset = asset
        self.onSave = onSave
        _nameInput = State(initialValue: asset.name)
        _kind = State(initialValue: asset.kind)
        _amountInput = State(initialValue: String(format: "%.0f", asset.amount))
        _noteInput = State(initialValue: asset.note)
    }

    var canSaveAmount: Bool {
        !nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amountInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var createdTimeText: String {
        "创建时间 \(metaDateText(asset.createdAt))"
    }

    var updatedTimeText: String {
        "更新时间 \(metaDateText(asset.updatedAt))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("资产类型")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FinanceAssetKind.allCases) { item in
                                    financeKindChip(item)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    ModernInputField(
                        placeholder: kind == .custom ? "自定义类目名称" : "资产名称",
                        text: $nameInput,
                        icon: kind.icon,
                        tint: financeKindTint(kind)
                    )

                    ModernInputField(
                        placeholder: "输入新的金额",
                        text: $amountInput,
                        icon: "yensign.circle",
                        tint: financeKindTint(kind),
                        keyboardType: .numberPad
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ZStack(alignment: .topLeading) {
                            if noteInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("可选，记一下这笔资产的详细信息")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 14)
                            }

                            TextEditor(text: $noteInput)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 88)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(createdTimeText)
                        Text(updatedTimeText)
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("修改资产")
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
                    Button("保存") {
                        saveAmount()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canSaveAmount)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    func metaDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    func financeKindChip(_ item: FinanceAssetKind) -> some View {
        let isSelected = kind == item
        let tint = financeKindTint(item)

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                kind = item
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.subheadline)

                Text(item.title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.12)),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    func financeKindTint(_ item: FinanceAssetKind) -> Color {
        switch item {
        case .bankCard:
            return .blue
        case .providentFund:
            return .indigo
        case .stock:
            return .green
        case .option:
            return .orange
        case .alipay:
            return .cyan
        case .wechat:
            return .mint
        case .custom:
            return .purple
        }
    }

    func saveAmount() {
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = amountInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !trimmedName.isEmpty, let amount = Double(normalizedAmount) else { return }
        onSave(trimmedName, kind, amount, noteInput.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}

struct FinanceAssetRow: View {
    let asset: FinanceAsset
    let amountText: String
    let updatedText: String
    let tint: Color
    var isPrivacyLocked = false
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(asset.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(asset.kind.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.12))
                            .foregroundStyle(tint)
                            .clipShape(Capsule())
                            .fixedSize()
                    }

                    Text(isPrivacyLocked ? "更新于 ***" : "更新于 \(updatedText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !isPrivacyLocked && !asset.note.isEmpty {
                        Text(asset.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(amountText)
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .longPressDelete(
            DeleteConfirmationContent(
                title: "删除资产？",
                message: "「\(asset.name)」会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete
        )
    }
}

struct FinancePrivacyUnlockSheet: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    let biometricActionTitle: String?
    @Binding var passwordInput: String
    let errorText: String?
    let onCancel: () -> Void
    let onBiometricUnlock: () -> Void
    let onUnlock: () -> Void

    @FocusState private var isFocused: Bool

    private var canUnlock: Bool {
        !passwordInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                SecureField("输入密码", text: $passwordInput)
                    .textContentType(.password)
                    .keyboardType(.numberPad)
                    .font(.headline)
                    .focused($isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let biometricActionTitle {
                    Button {
                        onBiometricUnlock()
                    } label: {
                        Label(biometricActionTitle, systemImage: "faceid")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppSecondaryButtonStyle(tint: .blue))
                }

                if let errorText {
                    Text(errorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle) { onUnlock() }
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .disabled(!canUnlock)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }
}

struct FinancePasswordChangeSheet: View {
    let currentPassword: String
    let biometricActionTitle: String?
    let onCancel: () -> Void
    let onBiometricVerify: (@escaping () -> Void, @escaping () -> Void) -> Void
    let onSave: (String) -> Void

    @State private var currentPasswordInput = ""
    @State private var newPasswordInput = ""
    @State private var confirmPasswordInput = ""
    @State private var didVerifyCurrentPassword = false
    @State private var errorText: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case current
        case new
        case confirm
    }

    private var canContinue: Bool {
        !currentPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSave: Bool {
        !newPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !confirmPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(didVerifyCurrentPassword ? "设置新密码" : "验证当前密码")
                        .font(.title3.bold())
                    Text(didVerifyCurrentPassword ? "输入并确认新的资产查看密码。" : "先确认当前密码，验证通过后才能修改。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if didVerifyCurrentPassword {
                    VStack(spacing: 10) {
                        SecureField("新密码", text: $newPasswordInput)
                            .textContentType(.newPassword)
                            .keyboardType(.numberPad)
                            .font(.subheadline)
                            .focused($focusedField, equals: .new)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        SecureField("再次输入新密码", text: $confirmPasswordInput)
                            .textContentType(.newPassword)
                            .keyboardType(.numberPad)
                            .font(.subheadline)
                            .focused($focusedField, equals: .confirm)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                } else {
                    VStack(spacing: 12) {
                        SecureField("当前密码", text: $currentPasswordInput)
                            .textContentType(.password)
                            .keyboardType(.numberPad)
                            .font(.subheadline)
                            .focused($focusedField, equals: .current)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        if let biometricActionTitle {
                            Button {
                                verifyWithBiometrics()
                            } label: {
                                Label(biometricActionTitle, systemImage: "faceid")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(AppSecondaryButtonStyle(tint: .blue))

                            Text("忘记密码时，也可以通过本机生物识别验证后重置。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                if let errorText {
                    Text(errorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(didVerifyCurrentPassword ? "保存" : "下一步") {
                        didVerifyCurrentPassword ? saveNewPassword() : verifyCurrentPassword()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(didVerifyCurrentPassword ? !canSave : !canContinue)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = .current
            }
        }
    }

    private func verifyCurrentPassword() {
        guard currentPasswordInput == currentPassword else {
            errorText = "当前密码不正确"
            currentPasswordInput = ""
            return
        }

        errorText = nil
        didVerifyCurrentPassword = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            focusedField = .new
        }
    }

    private func verifyWithBiometrics() {
        onBiometricVerify({
            errorText = nil
            didVerifyCurrentPassword = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                focusedField = .new
            }
        }, {
            errorText = "生物识别验证未通过"
        })
    }

    private func saveNewPassword() {
        let password = newPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmation = confirmPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !password.isEmpty else {
            errorText = "请输入新密码"
            return
        }

        guard password == confirmation else {
            errorText = "两次输入的密码不一致"
            return
        }

        onSave(password)
    }
}

struct WeightLogRow: View {
    let log: FastingLog
    let weightText: String
    let dateText: String
    let weekdayText: String
    let onOpen: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(dateText)
                            .font(.subheadline.weight(.medium))
                        Text("（\(weekdayText)）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !log.note.isEmpty {
                        Text(log.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(weightText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("kg")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

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
        }
        .buttonStyle(.plain)
        .longPressDelete(
            DeleteConfirmationContent(
                title: "删除体重记录？",
                message: "\(dateText) 的 \(weightText) kg 记录会被移除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete
        )
    }
}

struct WeightLogEditorSheet: View {
    let log: FastingLog
    let shouldFocusNote: Bool
    let onSave: (Double, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightInput: String
    @State private var noteInput: String
    @FocusState private var focusedField: Field?

    private enum Field { case weight, note }

    init(
        log: FastingLog,
        shouldFocusNote: Bool = false,
        onSave: @escaping (Double, String) -> Void
    ) {
        self.log = log
        self.shouldFocusNote = shouldFocusNote
        self.onSave = onSave
        _weightInput = State(initialValue: String(format: "%.1f", log.weight))
        _noteInput = State(initialValue: log.note)
    }

    private var parsedWeight: Double? {
        Double(weightInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }

    private var dayTagText: String? {
        let calendar = Calendar.current
        if calendar.isDateInToday(log.date) {
            return "今天"
        }
        if calendar.isDateInYesterday(log.date) {
            return "昨天"
        }
        return nil
    }

    private var fullDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: log.date)
    }

    private var createdTimeText: String {
        "创建于 \(metaDateText(log.date))"
    }

    private var editedTimeText: String? {
        guard let updatedAt = log.updatedAt else { return nil }
        return "更新于 \(metaDateText(updatedAt))"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 8) {
                    Text(fullDateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let dayTagText {
                        Text(dayTagText)
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("体重")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        TextField("0.0", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .focused($focusedField, equals: .weight)
                        Text("kg")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if noteInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("今天吃了什么喝了什么，这里记录下吧")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 14)
                                .padding(.horizontal, 14)
                        }

                        TextEditor(text: $noteInput)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 88)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .focused($focusedField, equals: .note)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(createdTimeText)
                    if let editedTimeText {
                        Text(editedTimeText)
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("体重记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        if let weight = parsedWeight {
                            onSave(weight, noteInput)
                        }
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(parsedWeight == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            guard shouldFocusNote else { return }
            try? await Task.sleep(nanoseconds: 350_000_000)
            focusedField = .note
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

struct FastingSessionRow: View {
    let session: FastingSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: session.completed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(session.completed ? .green : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(session.targetHours)+\(session.breakHours)")
                        .font(.headline)

                    Text(session.completed ? "已达标" : "提前结束")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(session.completed ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundStyle(session.completed ? .green : .orange)
                        .clipShape(Capsule())
                }

                Text("\(relativeTimeText(for: session.startDate)) - \(relativeTimeText(for: session.endDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("坚持了 \(durationText(from: session.startDate, to: session.endDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    func relativeTimeText(for date: Date) -> String {
        let calendar = Calendar.current
        let dayText: String

        if calendar.isDateInToday(date) {
            dayText = "今天"
        } else if calendar.isDateInYesterday(date) {
            dayText = "昨天"
        } else if calendar.isDateInTomorrow(date) {
            dayText = "明天"
        } else {
            dayText = date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
        }

        return "\(dayText) \(date.formatted(date: .omitted, time: .shortened))"
    }

    func durationText(from startDate: Date, to endDate: Date) -> String {
        let totalMinutes = max(0, Int(endDate.timeIntervalSince(startDate) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours) 小时"
        }

        return "\(hours) 小时 \(minutes) 分钟"
    }
}

struct MeasurementField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let unit: String
    var icon: String = "ruler"
    var tint: Color = .blue

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    ZStack(alignment: .leading) {
                        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(placeholder)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }

                        TextField("", text: $value)
                            .keyboardType(.decimalPad)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                            .focused($isFocused)
                    }

                    Text(unit)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isFocused ? tint.opacity(0.55) : Color(.separator).opacity(0.14),
                    lineWidth: isFocused ? 1.5 : 1
                )
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isFocused)
    }
}

struct TodoEditorSheet: View {
    let task: TodoTask
    let onSave: (String, String, TodoPriority, Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleInput: String
    @State private var detailInput: String
    @State private var priority: TodoPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @FocusState private var isFocused: Bool

    init(task: TodoTask, onSave: @escaping (String, String, TodoPriority, Date?) -> Void) {
        self.task = task
        self.onSave = onSave
        _titleInput = State(initialValue: task.title)
        _detailInput = State(initialValue: task.detail)
        _priority = State(initialValue: task.priority)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? TodoDueDateField.defaultDueDate())
    }

    private var canSave: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TODO")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ModernInputField(
                            placeholder: "记录些什么",
                            text: $titleInput,
                            icon: "checklist",
                            tint: .blue,
                            axis: .vertical
                        )
                        .focused($isFocused)
                    }

                    TodoDetailField(text: $detailInput)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("优先级")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        TodoPrioritySelector(selection: $priority)
                    }

                    TodoDueDateField(hasDueDate: $hasDueDate, dueDate: $dueDate)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("创建于 \(metaDateText(task.createdAt))")
                        if let updatedAt = task.updatedAt {
                            Text("更新于 \(metaDateText(updatedAt))")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("编辑TODO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onSave(
                            titleInput,
                            detailInput.trimmingCharacters(in: .whitespacesAndNewlines),
                            priority,
                            hasDueDate ? dueDate : nil
                        )
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
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

struct TodoAddSheet: View {
    let initialPriority: TodoPriority?
    let onAdd: (String, String, TodoPriority, Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleInput: String = ""
    @State private var detailInput: String = ""
    @State private var priority: TodoPriority?
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = TodoDueDateField.defaultDueDate()
    @FocusState private var isFocused: Bool

    init(initialPriority: TodoPriority?, onAdd: @escaping (String, String, TodoPriority, Date?) -> Void) {
        self.initialPriority = initialPriority
        self.onAdd = onAdd
        _priority = State(initialValue: initialPriority)
    }

    private var canSave: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TODO")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ModernInputField(
                            placeholder: "记录些什么",
                            text: $titleInput,
                            icon: "checklist",
                            tint: .blue,
                            axis: .vertical
                        )
                        .focused($isFocused)
                    }

                    TodoDetailField(text: $detailInput)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("优先级")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        TodoPriorityOptionalSelector(selection: $priority)
                    }

                    TodoDueDateField(hasDueDate: $hasDueDate, dueDate: $dueDate)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("新增 TODO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        onAdd(
                            titleInput.trimmingCharacters(in: .whitespacesAndNewlines),
                            detailInput.trimmingCharacters(in: .whitespacesAndNewlines),
                            priority ?? .notImportantNotUrgent,
                            hasDueDate ? dueDate : nil
                        )
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            priority = initialPriority
            detailInput = ""
            hasDueDate = false
            dueDate = TodoDueDateField.defaultDueDate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
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

struct TodoDetailField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("备注")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            TextField(
                "",
                text: $text,
                prompt: Text("可选，必要时可补充TODO详细信息")
                    .foregroundStyle(.tertiary),
                axis: .vertical
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
            .lineLimit(1...6)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct WishlistAddSheet: View {
    @Binding var title: String
    @Binding var note: String
    @Binding var categoryID: String
    let categories: [WishlistCategory]
    let onAdd: () -> Void
    let onCancel: () -> Void

    @FocusState private var isTitleFocused: Bool

    private var selectedCategory: WishlistCategory {
        categories.first { $0.id == categoryID } ?? categories.first ?? WishlistCategory.fallback
    }

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("愿望")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ModernInputField(
                            placeholder: "想要点什么",
                            text: $title,
                            icon: selectedCategory.icon,
                            tint: .blue
                        )
                        .focused($isTitleFocused)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("备注")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ZStack(alignment: .topLeading) {
                            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("可选，记一下想要它的原因或补充信息")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 14)
                            }

                            TextEditor(text: $note)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 92)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("分类")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories) { category in
                                    let isSelected = categoryID == category.id
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                            categoryID = category.id
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: category.icon)
                                                .font(.caption.bold())
                                            Text(category.title)
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(isSelected ? .white : .blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.blue : Color.blue.opacity(0.10), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("新增愿望")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加", action: onAdd)
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .disabled(!canAdd)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isTitleFocused = true
            }
        }
    }
}

struct MemoNoteEditorSheet: View {
    let note: MemoNote?
    let existingTags: [String]
    let initialImageDatas: [Data]
    let onSave: (String, [String], [Data]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var contentInput: String
    @State private var selectedTags: [String]
    @State private var selectedImageDatas: [Data]
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var isShowingTagPopover = false
    @State private var tagDraft = ""
    @State private var editingTagIndex: Int?
    @State private var isShowingImagePreview = false
    @State private var selectedPreviewIndex = 0
    @FocusState private var isFocused: Bool

    init(
        note: MemoNote? = nil,
        existingTags: [String],
        initialImageDatas: [Data],
        onSave: @escaping (String, [String], [Data]) -> Void
    ) {
        self.note = note
        self.existingTags = existingTags
        self.initialImageDatas = initialImageDatas
        self.onSave = onSave
        _contentInput = State(initialValue: note?.content ?? "")
        _selectedTags = State(initialValue: note?.tags ?? [])
        _selectedImageDatas = State(initialValue: initialImageDatas)
    }

    private var canSave: Bool {
        !contentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImageDatas.isEmpty || !selectedTags.isEmpty
    }

    private var suggestedTags: [String] {
        existingTags.filter {
            !selectedTags.contains($0) && !MemoNote.reservedTags.contains($0)
        }
    }

    private var showsCurrentTags: Bool {
        !selectedTags.isEmpty
    }

    private var normalizedTagDraft: String {
        normalizedTag(tagDraft)
    }

    private var tagDraftValidationMessage: String? {
        guard !normalizedTagDraft.isEmpty else { return nil }
        if MemoNote.reservedTags.contains(normalizedTagDraft) {
            return "“\(normalizedTagDraft)”是系统保留标签，不能作为自定义标签。"
        }
        return nil
    }

    private var createdTimeText: String? {
        guard let note else { return nil }
        return "创建于 \(metaDateText(note.createdAt))"
    }

    private var editedTimeText: String? {
        guard let updatedAt = note?.updatedAt else { return nil }
        return "更新于 \(metaDateText(updatedAt))"
    }

    private var previewImages: [UIImage] {
        selectedImageDatas.compactMap(UIImage.init(data:))
    }

    private var contentEditorFont: UIFont {
        .preferredFont(forTextStyle: .subheadline)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("内容")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 10) {
                            if showsCurrentTags {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(selectedTags.enumerated()), id: \.offset) { index, tag in
                                            Button {
                                                presentTagPopover(editingIndex: index)
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text("#\(tag)")
                                                    Image(systemName: "pencil")
                                                        .font(.system(size: 10, weight: .bold))
                                                }
                                                .font(.caption.bold())
                                                .foregroundStyle(.blue)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.12), in: Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .topLeading) {
                                    if contentInput.isEmpty {
                                        Text("随便写点什么吧")
                                            .font(.subheadline)
                                            .foregroundStyle(.tertiary)
                                            .padding(.horizontal, 4)
                                            .padding(.top, 8)
                                    }

                                    TextEditor(text: $contentInput)
                                        .font(.subheadline)
                                        .scrollContentBackground(.hidden)
                                        .frame(height: contentEditorHeight(width: proxy.size.width))
                                        .padding(.horizontal, -4)
                                        .focused($isFocused)
                                }
                            }
                            .frame(height: contentEditorHeight(width: UIScreen.main.bounds.width - 64))

                            if !selectedImageDatas.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(previewImages.enumerated()), id: \.offset) { index, uiImage in
                                            ZStack(alignment: .topTrailing) {
                                                Button {
                                                    selectedPreviewIndex = index
                                                    isShowingImagePreview = true
                                                } label: {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 92, height: 92)
                                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                                }
                                                .buttonStyle(.plain)

                                                Button {
                                                    selectedImageDatas.remove(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.title3)
                                                        .foregroundStyle(.white, .black.opacity(0.45))
                                                        .padding(6)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }

                            HStack(spacing: 12) {
                                Button {
                                    presentTagPopover()
                                } label: {
                                    Text("#")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.blue)
                                        .frame(width: 28, height: 28)
                                        .background(Color.blue.opacity(0.10), in: Circle())
                                }
                                .buttonStyle(.plain)

                                PhotosPicker(selection: $photoItems, maxSelectionCount: 9, matching: .images) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.blue)
                                        .frame(width: 28, height: 28)
                                        .background(Color.blue.opacity(0.10), in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if !suggestedTags.isEmpty && selectedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("常用标签")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestedTags, id: \.self) { tag in
                                        Button {
                                            addTag(tag)
                                        } label: {
                                            Text("#\(tag)")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.blue)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.10), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

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
            .navigationTitle(note == nil ? "新增笔记" : "编辑笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(note == nil ? "添加" : "完成") {
                        onSave(contentInput, selectedTags, selectedImageDatas)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canSave)
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingImagePreview) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                TabView(selection: $selectedPreviewIndex) {
                    ForEach(Array(previewImages.enumerated()), id: \.offset) { index, uiImage in
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(20)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isShowingImagePreview = false
                            }
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: previewImages.count > 1 ? .automatic : .never))

                Button {
                    isShowingImagePreview = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(20)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
        .sheet(isPresented: $isShowingTagPopover) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(editingTagIndex == nil ? "添加标签" : "编辑标签")
                        .font(.headline)
                    
                    Spacer()
                    
                    if editingTagIndex != nil {
                        Button {
                            removeEditingTag()
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                                .padding(6)
                                .background(Color.red.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    Text("#")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                    
                    TextField("输入标签名称", text: $tagDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            if !normalizedTagDraft.isEmpty {
                                commitTagEdit()
                            }
                        }
                    
                    if !tagDraft.isEmpty {
                        Button {
                            tagDraft = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if let tagDraftValidationMessage {
                    Text(tagDraftValidationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if !suggestedTags.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("常用标签")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestedTags, id: \.self) { tag in
                                    Button {
                                        tagDraft = tag
                                        commitTagEdit()
                                    } label: {
                                        Text("#\(tag)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.10), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        dismissTagPopover()
                    } label: {
                        Text("取消")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        commitTagEdit()
                    } label: {
                        Text("确定")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background((normalizedTagDraft.isEmpty || tagDraftValidationMessage != nil) ? Color.blue.opacity(0.5) : Color.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(normalizedTagDraft.isEmpty || tagDraftValidationMessage != nil)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: contentInput) { oldValue, newValue in
            handlePotentialTagTrigger(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: photoItems) {
            Task {
                var loadedDatas: [Data] = []

                for item in photoItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loadedDatas.append(data)
                    }
                }

                await MainActor.run {
                    selectedImageDatas.append(contentsOf: loadedDatas)
                    photoItems = []
                }
            }
        }
    }

    private func normalizedTag(_ tag: String) -> String {
        tag
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addTag(_ tag: String) {
        let normalized = normalizedTag(tag)
        guard !normalized.isEmpty,
              !MemoNote.reservedTags.contains(normalized),
              !selectedTags.contains(normalized) else { return }
        selectedTags.append(normalized)
    }

    private func presentTagPopover(editingIndex: Int? = nil) {
        self.editingTagIndex = editingIndex
        tagDraft = editingIndex.flatMap { selectedTags.indices.contains($0) ? selectedTags[$0] : nil } ?? ""
        isShowingTagPopover = true
        isFocused = false
    }

    private func dismissTagPopover() {
        tagDraft = ""
        editingTagIndex = nil
        isShowingTagPopover = false
    }

    private func commitTagEdit() {
        let normalized = normalizedTagDraft
        guard !normalized.isEmpty,
              !MemoNote.reservedTags.contains(normalized) else { return }

        if let editingTagIndex, selectedTags.indices.contains(editingTagIndex) {
            selectedTags.remove(at: editingTagIndex)
            if !selectedTags.contains(normalized) {
                selectedTags.insert(normalized, at: editingTagIndex)
            }
        } else if !selectedTags.contains(normalized) {
            selectedTags.append(normalized)
        }

        dismissTagPopover()
    }

    private func removeEditingTag() {
        if let editingTagIndex, selectedTags.indices.contains(editingTagIndex) {
            selectedTags.remove(at: editingTagIndex)
        }
        dismissTagPopover()
    }

    private func handlePotentialTagTrigger(oldValue: String, newValue: String) {
        let oldHashCount = oldValue.filter { $0 == "#" }.count
        let newHashCount = newValue.filter { $0 == "#" }.count
        guard newHashCount > oldHashCount,
              let hashIndex = newValue.lastIndex(of: "#") else { return }

        var sanitized = newValue
        sanitized.remove(at: hashIndex)
        if sanitized != contentInput {
            contentInput = sanitized
        }
        presentTagPopover()
    }

    private func contentEditorHeight(width: CGFloat) -> CGFloat {
        let horizontalPadding: CGFloat = 12
        let verticalPadding: CGFloat = 18
        let lineHeight = ceil(contentEditorFont.lineHeight)
        let textWidth = max(1, width - horizontalPadding)
        let rows = max(3, contentVisualLineCount(width: textWidth))
        return CGFloat(rows) * lineHeight + verticalPadding
    }

    private func contentVisualLineCount(width: CGFloat) -> Int {
        let text = contentInput.isEmpty ? " " : contentInput
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: contentEditorFont],
            context: nil
        )
        return max(1, Int(ceil(boundingRect.height / max(1, contentEditorFont.lineHeight))))
    }

    private func metaDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

struct TodoDueDateField: View {
    @Binding var hasDueDate: Bool
    @Binding var dueDate: Date
    @State private var isShowingDatePicker = false
    @State private var isShowingTimePicker = false

    static func defaultDueDate() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private var dueDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .year)
            ? "M月d日"
            : "yyyy年M月d日"
        return formatter.string(from: dueDate)
    }

    private var dueTimeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: dueDate)
    }

    private var quickDateOptions: [(title: String, date: Date)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [
            ("今天", today),
            ("明天", calendar.date(byAdding: .day, value: 1, to: today) ?? today),
            ("下周", calendar.date(byAdding: .day, value: 7, to: today) ?? today)
        ]
    }

    private var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    private func setDueDateKeepingTime(_ date: Date) {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: dueDate)

        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second

        dueDate = calendar.date(from: components) ?? date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $hasDueDate.animation(.spring(response: 0.25, dampingFraction: 0.88))) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.blue)
                    Text("截止时间")
                        .font(.subheadline.bold())
                }
            }
            .tint(.blue)

            if hasDueDate {
                HStack(spacing: 6) {
                    ForEach(quickDateOptions, id: \.title) { option in
                        let isSelected = Calendar.current.isDate(dueDate, inSameDayAs: option.date)

                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                setDueDateKeepingTime(option.date)
                            }
                        } label: {
                            Text(option.title)
                                .font(.footnote.weight(.medium))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(isSelected ? .white : .secondary)
                                .frame(minWidth: 24)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    isSelected ? AnyShapeStyle(Color.blue) : AnyShapeStyle(Color(.tertiarySystemGroupedBackground)),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 4)

                    Button {
                        isShowingDatePicker = true
                        isShowingTimePicker = false
                    } label: {
                        HStack(spacing: 4) {
                            Text(dueDateText)
                                .font(.footnote.weight(.medium))
                                .lineLimit(1)

                            Image(systemName: "chevron.down")
                                .font(.caption2.bold())
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isShowingDatePicker, arrowEdge: .bottom) {
                        DatePicker(
                            "",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .environment(\.calendar, mondayFirstCalendar)
                        .padding(10)
                        .frame(minWidth: 320)
                        .presentationCompactAdaptation(.popover)
                    }

                    Button {
                        isShowingTimePicker = true
                        isShowingDatePicker = false
                    } label: {
                        Text(dueTimeText)
                            .font(.footnote.weight(.medium))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isShowingTimePicker, arrowEdge: .bottom) {
                        DatePicker(
                            "",
                            selection: $dueDate,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .frame(width: 320, height: 180)
                        .clipped()
                        .presentationCompactAdaptation(.popover)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onChange(of: hasDueDate) {
            if !hasDueDate {
                isShowingDatePicker = false
                isShowingTimePicker = false
            }
        }
    }
}

struct TodoPrioritySelector: View {
    @Binding var selection: TodoPriority

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(TodoPriority.allCases) { priority in
                let isSelected = selection == priority
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        selection = priority
                    }
                } label: {
                    HStack(spacing: 0) {
                        Text(priority.title)
                            .font(.subheadline.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(isSelected ? priority.color.opacity(0.95) : Color.primary.opacity(0.72))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected
                        ? AnyShapeStyle(priority.color.opacity(0.14))
                        : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected ? priority.color.opacity(0.28) : Color(.separator).opacity(0.10),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct WishlistEditorSheet: View {
    let item: WishlistItem
    let categories: [WishlistCategory]
    let onSave: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleInput: String
    @State private var noteInput: String
    @State private var categoryID: String
    @FocusState private var isFocused: Bool

    init(item: WishlistItem, categories: [WishlistCategory], onSave: @escaping (String, String, String) -> Void) {
        self.item = item
        self.categories = categories
        self.onSave = onSave
        _titleInput = State(initialValue: item.title)
        _noteInput = State(initialValue: item.note)
        _categoryID = State(initialValue: item.categoryID)
    }

    private var canSave: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var createdTimeText: String {
        "创建于 \(metaDateText(item.createdAt))"
    }

    private var editedTimeText: String? {
        guard let updatedAt = item.updatedAt else { return nil }
        return "更新于 \(metaDateText(updatedAt))"
    }

    private var sortedCategories: [WishlistCategory] {
        var sorted = categories
        let isCurrentOther = sorted.first(where: { $0.id == item.categoryID })?.title == "其他"
        
        if let currentIndex = sorted.firstIndex(where: { $0.id == item.categoryID }) {
            let currentCategory = sorted.remove(at: currentIndex)
            sorted.insert(currentCategory, at: 0)
        }
        
        if !isCurrentOther {
            if let otherIndex = sorted.firstIndex(where: { $0.title == "其他" }) {
                let otherCategory = sorted.remove(at: otherIndex)
                sorted.append(otherCategory)
            }
        }
        
        return sorted
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("分类")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sortedCategories) { category in
                                Button {
                                    categoryID = category.id
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.icon)
                                        Text(category.title)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(categoryID == category.id ? .white : .blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background {
                                        Capsule()
                                            .fill(categoryID == category.id ? Color.blue : Color.blue.opacity(0.10))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                ModernInputField(
                    placeholder: "想要点什么",
                    text: $titleInput,
                    icon: categories.first(where: { $0.id == categoryID })?.icon ?? "sparkles",
                    tint: .blue
                )
                .focused($isFocused)

                VStack(alignment: .leading, spacing: 10) {
                    Text("备注")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if noteInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("可选，记一下想要它的原因或补充信息")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 14)
                                .padding(.horizontal, 14)
                        }

                        TextEditor(text: $noteInput)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 92)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(createdTimeText)
                    if let editedTimeText {
                        Text(editedTimeText)
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("编辑愿望")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onSave(titleInput, noteInput, categoryID)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canSave)
                }
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

struct WishlistCategoryManagerSheet: View {
    let categories: [WishlistCategory]
    let onAdd: (String, String) -> Void
    let onUpdate: (WishlistCategory, String, String) -> Void
    let onDelete: (WishlistCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editingTarget: CategoryEditTarget?

    enum CategoryEditTarget: Identifiable {
        case new
        case existing(WishlistCategory)

        var id: String {
            switch self {
            case .new: return "new"
            case .existing(let category): return category.id
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categories) { category in
                        Button {
                            editingTarget = .existing(category)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                    .frame(width: 34, height: 34)
                                    .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                Text(category.title)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("点按可编辑或删除分类。")
                }
            }
            .navigationTitle("管理分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingTarget = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundStyle(.blue)
                }
            }
            .sheet(item: $editingTarget) { target in
                switch target {
                case .new:
                    WishlistCategoryEditorSheet(category: nil) { title, icon in
                        onAdd(title, icon)
                    }
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
                case .existing(let category):
                    WishlistCategoryEditorSheet(category: category) { title, icon in
                        onUpdate(category, title, icon)
                    } onDelete: {
                        onDelete(category)
                    }
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

struct WishlistCategoryEditorSheet: View {
    let category: WishlistCategory?
    let onSave: (String, String) -> Void
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var titleInput: String
    @State private var icon: String
    @FocusState private var isFocused: Bool

    private let iconOptions = ["airplane", "fork.knife", "book.closed", "film", "sparkles", "music.note", "bag", "heart"]

    init(category: WishlistCategory?, onSave: @escaping (String, String) -> Void, onDelete: (() -> Void)? = nil) {
        self.category = category
        self.onSave = onSave
        self.onDelete = onDelete
        _titleInput = State(initialValue: category?.title ?? "")
        _icon = State(initialValue: category?.icon ?? "sparkles")
    }

    private var canSave: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                SheetHeader(
                    icon: "tag.fill",
                    title: category == nil ? "新增分类" : "编辑分类",
                    subtitle: "分类会用于筛选和新增愿望",
                    gradient: [.blue, .indigo]
                )

                ModernInputField(
                    placeholder: "分类名称",
                    text: $titleInput,
                    icon: "textformat",
                    tint: .blue
                )
                .focused($isFocused)

                VStack(alignment: .leading, spacing: 10) {
                    Text("图标")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(iconOptions, id: \.self) { option in
                            Button {
                                icon = option
                            } label: {
                                Image(systemName: option)
                                    .font(.headline)
                                    .foregroundStyle(icon == option ? .white : .blue)
                                    .frame(height: 42)
                                    .frame(maxWidth: .infinity)
                                    .background(icon == option ? Color.blue : Color.blue.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if category != nil, let onDelete {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("删除分类", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppSecondaryButtonStyle(tint: .red))
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onSave(titleInput, icon)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }

}

struct AnniversaryEditorSheet: View {
    let item: AnniversaryItem
    let solarPreview: (Date, AnniversaryCalendarKind) -> String?
    let onSave: (String, AnniversaryCalendarKind, Date, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleInput: String
    @State private var calendarKind: AnniversaryCalendarKind
    @State private var date: Date
    @State private var showsElapsedDays: Bool

    init(
        item: AnniversaryItem,
        solarPreview: @escaping (Date, AnniversaryCalendarKind) -> String?,
        onSave: @escaping (String, AnniversaryCalendarKind, Date, Bool) -> Void
    ) {
        self.item = item
        self.solarPreview = solarPreview
        self.onSave = onSave
        _titleInput = State(initialValue: item.title)
        _calendarKind = State(initialValue: item.calendarKind)
        _date = State(initialValue: item.date)
        _showsElapsedDays = State(initialValue: item.showsElapsedDays)
    }

    private var canSave: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("日期类型")
                        AppSegmentedControl(
                            options: AnniversaryCalendarKind.allCases,
                            selection: $calendarKind,
                            title: \.title
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("名称")
                        ModernInputField(
                            placeholder: "记录个重要的日子",
                            text: $titleInput,
                            icon: "calendar.badge.heart",
                            tint: .blue
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel(calendarKind == .lunar ? "日期（按农历选择）" : "日期")
                        WheelDatePicker(
                            date: $date,
                            calendarKind: calendarKind,
                            tint: .blue
                        )
                        .id(calendarKind)

                        if calendarKind == .lunar,
                           let preview = solarPreview(date, .lunar) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("今年对应阳历")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(preview)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.blue)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    Toggle(isOn: $showsElapsedDays) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("显示累计天数")
                                .font(.subheadline.bold())
                            Text("从这一天到今天一共多少天，会显示在卡片上。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                Button {
                    onSave(titleInput, calendarKind, date, showsElapsedDays)
                    dismiss()
                } label: {
                    Text("保存修改")
                }
                .buttonStyle(AppPrimaryButtonStyle(tint: .blue))
                .disabled(!canSave)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .navigationTitle("编辑纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }
}

struct WheelDatePicker: View {
    @Binding var date: Date
    var calendarKind: AnniversaryCalendarKind = .solar
    var tint: Color = .orange

    @State private var yearIndex = 0
    @State private var monthIndex = 0
    @State private var dayIndex = 0
    @State private var didInit = false

    private var cal: Calendar {
        var c = Calendar(identifier: calendarKind == .lunar ? .chinese : .gregorian)
        c.locale = Locale(identifier: "zh_CN")
        return c
    }

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let yearWidth = calendarKind == .lunar ? totalWidth * 0.46 : totalWidth * 0.4
            let restWidth = (totalWidth - yearWidth) / 2

            HStack(spacing: 0) {
                Picker("", selection: $yearIndex) {
                    ForEach(Array(yearStarts.enumerated()), id: \.offset) { index, start in
                        Text(yearLabel(start)).tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: yearWidth)
                .clipped()

                Picker("", selection: $monthIndex) {
                    ForEach(Array(monthStartsForSelection.enumerated()), id: \.offset) { index, start in
                        Text(monthLabel(start)).tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: restWidth)
                .clipped()

                Picker("", selection: $dayIndex) {
                    ForEach(Array(0..<dayCountForSelection), id: \.self) { index in
                        Text("\(index + 1)日").tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: restWidth)
                .clipped()
            }
        }
        .frame(height: 180)
        .tint(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear(perform: initIndicesIfNeeded)
        .onChange(of: yearIndex) { commit() }
        .onChange(of: monthIndex) { commit() }
        .onChange(of: dayIndex) { commit() }
    }

    private var yearStarts: [Date] {
        if calendarKind == .lunar {
            guard let currentStart = cal.dateInterval(of: .year, for: Date())?.start else { return [] }
            return stride(from: 100, through: 0, by: -1).compactMap {
                cal.date(byAdding: .year, value: -$0, to: currentStart)
            }
        } else {
            let base = Calendar(identifier: .gregorian).component(.year, from: Date())
            return ((base - 100)...base).compactMap {
                cal.date(from: DateComponents(year: $0, month: 1, day: 1))
            }
        }
    }

    private func monthStarts(_ yearStart: Date) -> [Date] {
        let count = cal.range(of: .month, in: .year, for: yearStart)?.count ?? 12
        return (0..<count).compactMap { cal.date(byAdding: .month, value: $0, to: yearStart) }
    }

    private var monthStartsForSelection: [Date] {
        let starts = yearStarts
        guard starts.indices.contains(yearIndex) else {
            return starts.last.map(monthStarts) ?? []
        }
        return monthStarts(starts[yearIndex])
    }

    private var dayCountForSelection: Int {
        let months = monthStartsForSelection
        let target = months.indices.contains(monthIndex) ? months[monthIndex] : months.last
        guard let target else { return 30 }
        return cal.range(of: .day, in: .month, for: target)?.count ?? 30
    }

    private func yearLabel(_ start: Date) -> String {
        if calendarKind == .lunar {
            let gregYear = Calendar(identifier: .gregorian).component(.year, from: start)
            return "\(String(gregYear))年 \(ganzhi(start))"
        } else {
            return "\(String(cal.component(.year, from: start)))年"
        }
    }

    private func monthLabel(_ start: Date) -> String {
        if calendarKind == .lunar {
            let comps = cal.dateComponents([.year, .month, .day], from: start)
            let prefix = (comps.isLeapMonth ?? false) ? "闰" : ""
            return prefix + lunarMonthName(comps.month ?? 1)
        } else {
            return "\(cal.component(.month, from: start))月"
        }
    }

    private func lunarMonthName(_ month: Int) -> String {
        let names = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
        guard month >= 1, month <= 12 else { return "\(month)月" }
        return names[month - 1] + "月"
    }

    private func ganzhi(_ start: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .chinese)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "U"
        return formatter.string(from: start)
    }

    private func initIndicesIfNeeded() {
        guard !didInit else { return }
        let starts = yearStarts
        let yearStartOfDate = cal.dateInterval(of: .year, for: date)?.start ?? date
        yearIndex = starts.firstIndex(where: { cal.isDate($0, inSameDayAs: yearStartOfDate) }) ?? max(0, starts.count - 1)

        let months = starts.indices.contains(yearIndex) ? monthStarts(starts[yearIndex]) : []
        let monthStartOfDate = cal.dateInterval(of: .month, for: date)?.start ?? date
        monthIndex = months.firstIndex(where: { cal.isDate($0, inSameDayAs: monthStartOfDate) }) ?? 0

        dayIndex = max(0, cal.component(.day, from: date) - 1)
        didInit = true
    }

    private func commit() {
        guard didInit else { return }
        let starts = yearStarts
        guard !starts.isEmpty else { return }

        let yi = min(max(0, yearIndex), starts.count - 1)
        let months = monthStarts(starts[yi])
        guard !months.isEmpty else { return }

        let mi = min(max(0, monthIndex), months.count - 1)
        if mi != monthIndex { monthIndex = mi }

        let monthStart = months[mi]
        let dayCount = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let di = min(max(0, dayIndex), dayCount - 1)
        if di != dayIndex { dayIndex = di }

        if let newDate = cal.date(byAdding: .day, value: di, to: monthStart) {
            date = newDate
        }
    }
}

struct WeatherForecastPage: View {
    @ObservedObject var weatherStore: WeatherStore
    @State private var isShowingCitySearch = false
    @State private var cityQuery = ""
    @State private var cityResults: [WeatherCity] = []
    @State private var isSearchingCities = false
    @State private var citySearchTask: Task<Void, Never>?

    private var info: WeatherInfo? {
        if case .loaded(let info) = weatherStore.state {
            return info
        }
        return nil
    }

    private var navigationTitle: String {
        guard let info else { return "未来天气" }
        return "\(info.cityName)未来天气"
    }

    private func globalMaxTemp(for info: WeatherInfo) -> Int {
        info.dailyForecast.map { Int($0.maxTemperature.rounded()) }.max() ?? Int.min
    }

    private func globalMinTemp(for info: WeatherInfo) -> Int {
        info.dailyForecast.map { Int($0.minTemperature.rounded()) }.min() ?? Int.max
    }

    var body: some View {
        forecastContent
        .background(Color(.systemGroupedBackground))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        isShowingCitySearch.toggle()
                    }
                } label: {
                    Label(isShowingCitySearch ? "收起" : "城市", systemImage: isShowingCitySearch ? "xmark" : "mappin.and.ellipse")
                }
                .font(.subheadline.bold())
            }
        }
        .onAppear {
            if case .idle = weatherStore.state {
                weatherStore.refresh()
            }
        }
        .onChange(of: cityQuery) { _, newValue in
            searchCities(newValue)
        }
        .onDisappear {
            citySearchTask?.cancel()
        }
    }

    @ViewBuilder
    private var forecastContent: some View {
        switch weatherStore.state {
        case .loaded(let info):
            ScrollView {
                VStack(spacing: 16) {
                    if isShowingCitySearch {
                        citySearchPanel
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let sunCardInfo = info.todayForecast,
                       sunCardInfo.sunrise != nil || sunCardInfo.sunset != nil {
                        sunriseSunsetCard(for: sunCardInfo)
                    }

                    ForEach(info.dailyForecast) { daily in
                        forecastRow(for: daily, info: info)
                    }
                }
                .padding()
            }
            .refreshable {
                weatherStore.refresh()
            }

        case .loading, .idle:
            ScrollView {
                VStack(spacing: 16) {
                    if isShowingCitySearch {
                        citySearchPanel
                    }

                    VStack(spacing: 12) {
                        ProgressView()
                        Text("正在更新天气…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                }
                .padding()
            }

        case .denied:
            ScrollView {
                VStack(spacing: 16) {
                    if isShowingCitySearch {
                        citySearchPanel
                    }

                    VStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("未开启定位")
                            .font(.headline)
                        Text("可以开启定位，或点左上角“城市”查看其他城市。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                }
                .padding()
            }

        case .failed:
            ScrollView {
                VStack(spacing: 16) {
                    if isShowingCitySearch {
                        citySearchPanel
                    }

                    VStack(spacing: 12) {
                        Image(systemName: "cloud.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("天气获取失败")
                            .font(.headline)
                        Button("重新获取") {
                            weatherStore.refresh()
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                }
                .padding()
            }
        }
    }

    private var citySearchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                weatherStore.useCurrentLocation()
                collapseCitySearch()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("当前位置")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(weatherStore.isUsingCurrentLocation ? "正在使用定位天气" : "切回当前定位后的位置")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if weatherStore.isUsingCurrentLocation {
                        Image(systemName: "checkmark")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.plain)

            if !weatherStore.recentCities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近选择")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(weatherStore.recentCities) { city in
                                Button {
                                    weatherStore.selectCity(city)
                                    collapseCitySearch()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(city.presentedName)

                                        if weatherStore.selectedCity?.id == city.id {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                        }
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(weatherStore.selectedCity?.id == city.id ? .white : .blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(weatherStore.selectedCity?.id == city.id ? Color.blue : Color.blue.opacity(0.10), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索城市，比如北京、上海、杭州", text: $cityQuery)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if isSearchingCities {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("正在搜索…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(cityResults.prefix(6)) { city in
                Button {
                    weatherStore.selectCity(city)
                    collapseCitySearch()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.presentedName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            if !city.detailName.isEmpty {
                                Text(city.detailName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if weatherStore.selectedCity?.id == city.id {
                            Image(systemName: "checkmark")
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            if !cityQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !isSearchingCities,
               cityResults.isEmpty {
                Text("没有找到匹配城市")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func searchCities(_ query: String) {
        citySearchTask?.cancel()
        citySearchTask = Task {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                await MainActor.run {
                    cityResults = []
                    isSearchingCities = false
                }
                return
            }

            await MainActor.run {
                isSearchingCities = true
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            let cities = await weatherStore.searchCities(matching: trimmed)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                cityResults = cities
                isSearchingCities = false
            }
        }
    }

    private func collapseCitySearch() {
        citySearchTask?.cancel()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            isShowingCitySearch = false
        }
    }

    private func forecastRow(for daily: DailyWeatherInfo, info: WeatherInfo) -> some View {
        let isGlobalMax = Int(daily.maxTemperature.rounded()) == globalMaxTemp(for: info)
        let isGlobalMin = Int(daily.minTemperature.rounded()) == globalMinTemp(for: info)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateText(for: daily.date))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isToday(daily.date) ? .blue : .primary)

                let weekday = weekdayText(for: daily.date)
                if !weekday.isEmpty {
                    Text(weekday)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 60, alignment: .leading)

            weatherIcon(for: daily)
                .frame(width: 32)
                .foregroundStyle(isToday(daily.date) ? .blue : .primary)

            Text(daily.conditionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                Text(daily.minTemperatureText)
                    .font(.subheadline.monospacedDigit().weight(isGlobalMin ? .medium : .regular))
                    .foregroundStyle(isGlobalMin ? .blue : .secondary)
                    .frame(width: 36, alignment: .trailing)

                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 4)

                Text(daily.maxTemperatureText)
                    .font(.subheadline.monospacedDigit().weight(isGlobalMax ? .bold : .medium))
                    .foregroundStyle(isGlobalMax ? .red : .primary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sunriseSunsetCard(for daily: DailyWeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                    .frame(width: 28, height: 28)
                    .background(Color.orange.opacity(0.12), in: Circle())

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("日出日落")
                        .font(.subheadline.bold())

                    Text(isToday(daily.date) ? "今天" : dateText(for: daily.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                weatherSunPhaseItem(
                    title: "日出",
                    time: daily.sunrise,
                    icon: "sunrise.fill",
                    tint: .orange
                )

                weatherSunPhaseItem(
                    title: "日落",
                    time: daily.sunset,
                    icon: "sunset.fill",
                    tint: .indigo
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func weatherSunPhaseItem(title: String, time: Date?, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundStyle(tint)

            Text(weatherSunTimeText(time))
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func weatherIcon(for daily: DailyWeatherInfo) -> some View {
        let img = Image(systemName: daily.symbolName).font(.title3)
        switch daily.symbolName {
        case "sun.max.fill":
            img.symbolRenderingMode(.palette).foregroundStyle(.orange)
        case "cloud.sun.fill":
            img.symbolRenderingMode(.palette).foregroundStyle(.gray, .orange)
        case "cloud.sun.rain.fill":
            img.symbolRenderingMode(.palette).foregroundStyle(.gray, .orange, .blue)
        case "cloud.fill", "cloud.fog.fill":
            img.symbolRenderingMode(.palette).foregroundStyle(.gray)
        case "cloud.drizzle.fill", "cloud.rain.fill", "cloud.heavyrain.fill":
            img.symbolRenderingMode(.palette).foregroundStyle(.gray, .blue)
        case "cloud.snow.fill":
            img.symbolRenderingMode(.palette).foregroundStyle(.gray, .cyan)
        case "cloud.bolt.rain.fill":
            img.symbolRenderingMode(.palette).foregroundStyle(.gray, .yellow, .blue)
        default:
            img.symbolRenderingMode(.palette).foregroundStyle(.gray)
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func dateText(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "今天"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func weekdayText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func weatherSunTimeText(_ date: Date?) -> String {
        guard let date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
