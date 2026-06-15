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
    let onToggle: () -> Void
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : Color(.systemGray3))
            }
            .buttonStyle(.borderless)

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        TodoPriorityBadge(priority: task.priority)

                        Text(timestampText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
        .longPressDelete(
            DeleteConfirmationContent(
                title: "删除待办？",
                message: "「\(task.title)」会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete
        )
    }

    var timestampText: String {
        if task.isCompleted {
            return "完成于 \(dateText(task.completedAt ?? task.createdAt))"
        }
        if let updatedAt = task.updatedAt {
            return "编辑于 \(dateText(updatedAt))"
        }
        return "创建于 \(dateText(task.createdAt))"
    }

    func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

struct TodoPriorityBadge: View {
    let priority: TodoPriority

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: priority.icon)
                .font(.system(size: 9, weight: .bold))
            Text(priority.title)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(priority.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(priority.color.opacity(0.12), in: Capsule())
    }
}

struct WishlistRow: View {
    let item: WishlistItem
    let category: WishlistCategory
    let onToggle: () -> Void
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil

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

                    Text(item.isCompleted ? "实现于 \(dateText(item.completedAt ?? item.createdAt))" : "记录于 \(dateText(item.createdAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .longPressDelete(
            DeleteConfirmationContent(
                title: "删除愿望？",
                message: "「\(item.title)」会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete
        )
    }

    func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
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

    private var isToday: Bool { (daysUntil ?? -1) == 0 }

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

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
        .longPressDelete(
            DeleteConfirmationContent(
                title: "删除纪念日？",
                message: "「\(item.title)」会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete
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
        .longPressDelete(
            DeleteConfirmationContent(
                title: "删除股票？",
                message: "「\(item.name)」及其研究笔记会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete
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
            .safeAreaInset(edge: .bottom) {
                Button(action: onAdd) {
                    Text("添加")
                }
                .buttonStyle(AppPrimaryButtonStyle(tint: .blue))
                .disabled(!canAdd)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .navigationTitle("新增股票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
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
    let updatedText: String
    let onRename: (String) -> Void
    let onSaveRatings: (StockRating?, StockRating?, StockRating?) -> Void
    let onTogglePin: () -> Void

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
        updatedText: String,
        onRename: @escaping (String) -> Void,
        onSaveRatings: @escaping (StockRating?, StockRating?, StockRating?) -> Void,
        onTogglePin: @escaping () -> Void
    ) {
        self.item = item
        _thesis = thesis
        self.updatedText = updatedText
        self.onRename = onRename
        self.onSaveRatings = onSaveRatings
        self.onTogglePin = onTogglePin
        _nameInput = State(initialValue: item.name)
        _certainty = State(initialValue: item.certainty)
        _growth = State(initialValue: item.growth)
        _attention = State(initialValue: item.attention)
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

                            Text("更新于 \(updatedText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        TextEditor(text: $thesis)
                            .focused($isThesisFocused)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 260)
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

                        VStack(spacing: 10) {
                            SheetPinButton(isPinned: item.isPinned) {
                                onTogglePin()
                                dismiss()
                            }
                        }
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

struct FinanceAssetEditorSheet: View {
    let asset: FinanceAsset
    let amountText: String
    let onSave: (Double, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountInput: String
    @State private var noteInput: String

    init(asset: FinanceAsset, amountText: String, onSave: @escaping (Double, String) -> Void) {
        self.asset = asset
        self.amountText = amountText
        self.onSave = onSave
        _amountInput = State(initialValue: String(format: "%.0f", asset.amount))
        _noteInput = State(initialValue: asset.note)
    }

    var canSaveAmount: Bool {
        !amountInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(asset.name)
                        .font(.title2.bold())

                    Text("\(asset.kind.title) · 当前 \(amountText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ModernInputField(
                    placeholder: "输入新的金额",
                    text: $amountInput,
                    icon: "yensign.circle",
                    tint: .blue,
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

                Spacer()

                Button {
                    saveAmount()
                } label: {
                    Text("保存金额")
                }
                .buttonStyle(AppPrimaryButtonStyle(tint: .blue))
                .disabled(!canSaveAmount)
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
            }
        }
        .presentationDetents([.medium, .large])
    }

    func saveAmount() {
        let normalizedAmount = amountInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Double(normalizedAmount) else { return }
        onSave(amount, noteInput.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}

struct FinanceAssetRow: View {
    let asset: FinanceAsset
    let amountText: String
    let updatedText: String
    let tint: Color
    let onEdit: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: asset.kind.icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(asset.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(asset.kind.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.12))
                            .foregroundStyle(tint)
                            .clipShape(Capsule())
                    }

                    Text("更新于 \(updatedText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !asset.note.isEmpty {
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

struct WeightLogRow: View {
    let log: FastingLog
    let weightText: String
    let dateText: String
    let onOpen: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                Image(systemName: "scalemass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(dateText)
                        .font(.subheadline.weight(.medium))
                    if !log.note.isEmpty {
                        Text(log.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

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
    let weightText: String
    let dateText: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noteInput: String
    @FocusState private var isFocused: Bool

    init(
        log: FastingLog,
        weightText: String,
        dateText: String,
        onSave: @escaping (String) -> Void
    ) {
        self.log = log
        self.weightText = weightText
        self.dateText = dateText
        self.onSave = onSave
        _noteInput = State(initialValue: log.note)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(weightText)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        Text("kg")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                    Text(dateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ModernInputField(
                        placeholder: "记一下当时的情况",
                        text: $noteInput,
                        icon: "text.alignleft",
                        tint: .blue,
                        axis: .vertical
                    )
                    .focused($isFocused)
                }

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
                        onSave(noteInput)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                }
            }
        }
        .presentationDetents([.medium, .large])
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
    let onSave: (String, TodoPriority) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleInput: String
    @State private var priority: TodoPriority
    @FocusState private var isFocused: Bool

    init(task: TodoTask, onSave: @escaping (String, TodoPriority) -> Void) {
        self.task = task
        self.onSave = onSave
        _titleInput = State(initialValue: task.title)
        _priority = State(initialValue: task.priority)
    }

    private var canSave: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ModernInputField(
                    placeholder: "记录些什么",
                    text: $titleInput,
                    icon: "checklist",
                    tint: .blue,
                    axis: .vertical
                )
                .focused($isFocused)

                VStack(alignment: .leading, spacing: 10) {
                    Text("优先级")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TodoPrioritySelector(selection: $priority)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
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
                        onSave(titleInput, priority)
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
                    HStack(spacing: 6) {
                        Image(systemName: priority.icon)
                            .font(.caption.weight(.bold))
                        Text(priority.title)
                            .font(.subheadline.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(isSelected ? .white : priority.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ? AnyShapeStyle(priority.color) : AnyShapeStyle(priority.color.opacity(0.12)),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct WishlistEditorSheet: View {
    let item: WishlistItem
    let categories: [WishlistCategory]
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var titleInput: String
    @State private var categoryID: String
    @FocusState private var isFocused: Bool

    init(item: WishlistItem, categories: [WishlistCategory], onSave: @escaping (String, String) -> Void) {
        self.item = item
        self.categories = categories
        self.onSave = onSave
        _titleInput = State(initialValue: item.title)
        _categoryID = State(initialValue: item.categoryID)
    }

    private var canSave: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                            ForEach(categories) { category in
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
                        onSave(titleInput, categoryID)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canSave)
                }
            }
        }
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
