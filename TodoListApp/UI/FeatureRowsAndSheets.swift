import SwiftUI

struct TodoTaskRow: View {
    let task: TodoTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(onDelete: onDelete) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.borderless)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)

                    Text(task.isCompleted ? "完成于 \(dateText(task.completedAt ?? task.createdAt))" : "创建于 \(dateText(task.createdAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
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
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : item.category.icon)
                        .font(.title3)
                        .foregroundStyle(item.isCompleted ? .green : .purple)
                        .frame(width: 24)
                }
                .buttonStyle(.borderless)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.headline)
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)

                        Text(item.category.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
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
    let nextText: String
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(onDelete: onDelete) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.kind.icon)
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.headline)

                        Text(item.kind.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.14))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 8) {
                        Text(dateText)
                        Text(nextText)
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}

struct StockResearchRow: View {
    let item: StockResearchItem
    let updatedText: String
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(onDelete: onDelete) {
            Button(action: onOpen) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "chart.line.text.clipboard")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(stockResearchSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    var stockResearchSummary: String {
        item.thesis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "还没有研究笔记 · 更新于 \(updatedText)"
            : "已有研究笔记 · 更新于 \(updatedText)"
    }
}

struct StockResearchEditorSheet: View {
    let item: StockResearchItem
    @Binding var thesis: String
    let updatedText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title2.bold())

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
                        dismiss()
                    }
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
                        .font(.headline)
                        .foregroundStyle(canSaveAmount ? .white : Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canSaveAmount ? Color.blue : Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
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
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SwipeToDeleteRow(onDelete: onDelete) {
            Button(action: onEdit) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: asset.kind.icon)
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.10))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(asset.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(asset.kind.title)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }

                        Text("更新于 \(updatedText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(amountText)
                            .font(.headline.bold())
                            .foregroundStyle(.primary)

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                }
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
        SwipeToDeleteRow(onDelete: onDelete) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "scalemass")
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(weightText) kg")
                            .font(.headline)

                        Text(dateText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !log.note.isEmpty {
                        Text(log.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField(placeholder, text: $value)
                    .keyboardType(.decimalPad)
                    .font(.headline)
                Text(unit)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
