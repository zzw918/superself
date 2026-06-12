import SwiftUI

struct TodoTaskRow: View {
    let task: TodoTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(onDelete: onDelete) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(task.isCompleted ? .green : Color(.systemGray3))
                }
                .buttonStyle(.borderless)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)

                    Text(task.isCompleted ? "完成于 \(dateText(task.completedAt ?? task.createdAt))" : "创建于 \(dateText(task.createdAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
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

struct WishlistRow: View {
    let item: WishlistItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(onDelete: onDelete) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : item.category.icon)
                        .font(.title2)
                        .foregroundStyle(item.isCompleted ? .green : .purple)
                        .frame(width: 26)
                }
                .buttonStyle(.borderless)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)

                        Text(item.category.title)
                            .font(.caption2.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.14))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }

                    Text(item.isCompleted ? "实现于 \(dateText(item.completedAt ?? item.createdAt))" : "记录于 \(dateText(item.createdAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
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
    let onDelete: () -> Void

    private var isToday: Bool { (daysUntil ?? -1) == 0 }

    var body: some View {
        SwipeToDeleteRow(
            onDelete: onDelete,
            confirmation: DeleteConfirmationContent(
                title: "删除纪念日？",
                message: "删除后将无法恢复这条纪念日提醒。",
                confirmTitle: "删除纪念日"
            )
        ) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.headline)

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
                            .background(Color.orange.opacity(0.14))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 8)

                countdownView
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
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
            .foregroundStyle(.orange)
            .frame(minWidth: 64)
        } else if let days = daysUntil, days > 0 {
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
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
    let onDelete: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        SwipeToDeleteRow(
            onDelete: onDelete,
            confirmation: DeleteConfirmationContent(
                title: "删除股票研究？",
                message: "“\(item.name)” 的研究笔记会一起删除，后续无法恢复。",
                confirmTitle: "删除研究"
            ),
            pinAction: SwipePinAction(isPinned: item.isPinned, onToggle: onTogglePin)
        ) {
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
        }
    }

    var stockResearchPreview: String? {
        let trimmed = item.thesis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return trimmed
            .split(whereSeparator: \.isNewline)
            .prefix(2)
            .joined(separator: " ")
    }
}

struct StockResearchAddSheet: View {
    @Binding var name: String
    let onAdd: () -> Void
    let onCancel: () -> Void

    @FocusState private var isNameFocused: Bool

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SheetHeader(
                icon: "chart.line.text.clipboard",
                title: "新增股票",
                subtitle: "先用名称建档，之后再补充研究笔记"
            )

            ModernInputField(
                placeholder: "股票名称，例如：贵州茅台",
                text: $name,
                icon: "magnifyingglass",
                tint: .blue
            )
            .focused($isNameFocused)

            VStack(alignment: .leading, spacing: 8) {
                Text("快速添加")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                let suggestions = ["贵州茅台", "腾讯控股", "苹果", "英伟达", "宁德时代"]
                FlexibleChips(items: suggestions) { suggestion in
                    name = suggestion
                }
            }

            Spacer(minLength: 0)

            Button(action: onAdd) {
                Text("添加")
            }
            .buttonStyle(AppPrimaryButtonStyle(tint: .blue))
            .disabled(!canAdd)
        }
        .padding(20)
        .presentationBackground(Color(.systemGroupedBackground))
        .overlay(alignment: .topTrailing) {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(16)
        }
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

    @Environment(\.dismiss) private var dismiss
    @State private var nameInput: String

    init(
        item: StockResearchItem,
        thesis: Binding<String>,
        updatedText: String,
        onRename: @escaping (String) -> Void
    ) {
        self.item = item
        _thesis = thesis
        self.updatedText = updatedText
        self.onRename = onRename
        _nameInput = State(initialValue: item.name)
    }

    var body: some View {
        NavigationStack {
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                }
            }
        }
    }
}

struct FinanceAssetEditorSheet: View {
    let asset: FinanceAsset
    let amountText: String
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountInput: String

    init(asset: FinanceAsset, amountText: String, onSave: @escaping (Double) -> Void) {
        self.asset = asset
        self.amountText = amountText
        self.onSave = onSave
        _amountInput = State(initialValue: String(format: "%.0f", asset.amount))
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

                Text("这里只记录整数金额，几毛几分钱会自动忽略。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

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
        .presentationDetents([.medium])
    }

    func saveAmount() {
        let normalizedAmount = amountInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Double(normalizedAmount) else { return }
        onSave(amount)
        dismiss()
    }
}

struct FinanceAssetRow: View {
    let asset: FinanceAsset
    let amountText: String
    let updatedText: String
    let tint: Color
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(
            onDelete: onDelete,
            confirmation: DeleteConfirmationContent(
                title: "删除资产记录？",
                message: "“\(asset.name)” 的金额记录会被移除，删除后无法恢复。",
                confirmTitle: "删除资产"
            )
        ) {
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
        }
    }
}

struct WeightLogRow: View {
    let log: FastingLog
    let weightText: String
    let dateText: String
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(
            onDelete: onDelete,
            confirmation: DeleteConfirmationContent(
                title: "删除体重记录？",
                message: "\(dateText) 的 \(weightText) kg 记录会被移除。",
                confirmTitle: "删除记录"
            )
        ) {
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
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
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
