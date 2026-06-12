import SwiftUI

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct SummaryPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AppEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.tertiary)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    var tint: Color = .blue
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint.opacity(configuration.isPressed ? 0.8 : 1))
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(tint.opacity(configuration.isPressed ? 0.16 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.08), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    var tint: Color = .blue
    var isFullWidth: Bool = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? .white : Color(.tertiaryLabel))
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 50)
            .background(isEnabled ? tint : Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: isEnabled ? tint.opacity(configuration.isPressed ? 0.14 : 0.22) : .clear, radius: 10, y: 5)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.985 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

struct AppIconCircleButton: View {
    let icon: String
    let tint: Color
    var size: CGFloat = 36
    var iconFont: Font = .headline

    var body: some View {
        Image(systemName: icon)
            .font(iconFont)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint)
            .clipShape(Circle())
            .shadow(color: tint.opacity(0.22), radius: 8, x: 0, y: 4)
    }
}

struct AppDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(configuration.isPressed ? Color.red.opacity(0.82) : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.red.opacity(configuration.isPressed ? 0.10 : 0.18), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

struct DeleteConfirmationContent {
    let title: String
    let message: String
    let confirmTitle: String
}

struct AppSegmentedControl<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        selection = option
                    }
                } label: {
                    Text(title(option))
                        .font(selection == option ? .headline.bold() : .subheadline.bold())
                        .foregroundStyle(selection == option ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.blue.gradient)
                                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                                    .shadow(color: Color.blue.opacity(0.26), radius: 10, x: 0, y: 4)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.16), lineWidth: 1)
        }
    }
}

struct ModernInputField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let tint: Color
    var keyboardType: UIKeyboardType = .default
    var axis: Axis = .horizontal

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 20)

            TextField(placeholder, text: $text, axis: axis)
                .lineLimit(axis == .vertical ? 1...3 : 1...1)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .font(.body)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 48)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.22), lineWidth: 1)
        }
    }
}

struct AddEntryBar: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let tint: Color
    var keyboardType: UIKeyboardType = .default
    var buttonTitle: String?
    let action: () -> Void

    var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            ModernInputField(
                placeholder: placeholder,
                text: $text,
                icon: icon,
                tint: tint,
                keyboardType: keyboardType,
                axis: .vertical
            )

            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))

                    if let buttonTitle {
                        Text(buttonTitle)
                            .font(.headline)
                    }
                }
                .foregroundStyle(canSubmit ? .white : Color(.tertiaryLabel))
                .frame(minWidth: buttonTitle == nil ? 48 : 86)
                .frame(height: 48)
                .background(canSubmit ? tint : Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: canSubmit ? tint.opacity(0.22) : .clear, radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
        }
    }
}

struct SearchInputBar: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 48)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
        }
    }
}

struct SwipePinAction {
    let isPinned: Bool
    let onToggle: () -> Void
}

struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    var confirmation: DeleteConfirmationContent?
    var pinAction: SwipePinAction?
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var isShowingDeleteConfirmation = false
    let singleActionWidth: CGFloat = 64

    init(
        onDelete: @escaping () -> Void,
        confirmation: DeleteConfirmationContent? = nil,
        pinAction: SwipePinAction? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onDelete = onDelete
        self.confirmation = confirmation
        self.pinAction = pinAction
        self.content = content
    }

    var actionsWidth: CGFloat {
        pinAction == nil ? singleActionWidth : singleActionWidth * 2
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                HStack(spacing: 0) {
                    if let pinAction {
                        Button {
                            resetOffset()
                            pinAction.onToggle()
                        } label: {
                            Image(systemName: pinAction.isPinned ? "pin.slash.fill" : "pin.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: singleActionWidth)
                                .frame(maxHeight: .infinity)
                                .background(Color.orange)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        triggerDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: singleActionWidth)
                            .frame(maxHeight: .infinity)
                            .background(Color.red)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 18)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }

                            if value.translation.width < 0 {
                                offset = max(-actionsWidth, value.translation.width)
                            } else if offset < 0 {
                                offset = min(0, -actionsWidth + value.translation.width)
                            }
                        }
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }

                            withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                                offset = value.translation.width < -actionsWidth / 2 ? -actionsWidth : 0
                            }
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .alert(confirmation?.title ?? "确认删除", isPresented: $isShowingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                resetOffset()
            }
            Button(confirmation?.confirmTitle ?? "删除", role: .destructive) {
                resetOffset()
                onDelete()
            }
        } message: {
            if let confirmation {
                Text(confirmation.message)
            }
        }
    }

    func triggerDelete() {
        if confirmation != nil {
            isShowingDeleteConfirmation = true
        } else {
            resetOffset()
            onDelete()
        }
    }

    func resetOffset() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
            offset = 0
        }
    }
}
