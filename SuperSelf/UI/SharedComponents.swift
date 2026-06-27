import SwiftUI

struct SheetHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    var gradient: [Color] = [.blue, .indigo]

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

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
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
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
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font((compact ? Font.caption : .subheadline).weight(.semibold))
            .foregroundStyle(tint.opacity(configuration.isPressed ? 0.8 : 1))
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, compact ? 12 : 14)
            .padding(.vertical, compact ? 8 : 11)
            .background(tint.opacity(configuration.isPressed ? 0.16 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 14 : 16, style: .continuous)
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

enum LongPressActionPresentation {
    case contextMenu
    case blurredOverlay
}

struct AppSegmentedControl<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    var compact: Bool = false

    @Namespace private var selectionNamespace

    private var controlHeight: CGFloat { compact ? 34 : 46 }
    private var corner: CGFloat { compact ? 12 : 16 }
    private var outerCorner: CGFloat { compact ? 15 : 20 }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        selection = option
                    }
                } label: {
                    Text(title(option))
                        .font(segmentFont(isSelected: selection == option))
                        .foregroundStyle(selection == option ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: controlHeight)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: corner, style: .continuous)
                                    .fill(Color.blue.gradient)
                                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                                    .shadow(color: Color.blue.opacity(0.26), radius: compact ? 6 : 10, x: 0, y: compact ? 2 : 4)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: outerCorner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                .stroke(Color(.separator).opacity(0.16), lineWidth: 1)
        }
    }

    private func segmentFont(isSelected: Bool) -> Font {
        if compact {
            return isSelected ? .subheadline.bold() : .subheadline.weight(.medium)
        }
        return isSelected ? .headline.bold() : .subheadline.bold()
    }
}

struct AppUnderlineTabs<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    var spacing: CGFloat = 24

    @Namespace private var underlineNamespace

    private var usesCompactLayout: Bool {
        options.count >= 5
    }

    private var effectiveSpacing: CGFloat {
        usesCompactLayout ? min(spacing, 10) : spacing
    }

    var body: some View {
        HStack(spacing: effectiveSpacing) {
            ForEach(options) { option in
                let isSelected = selection == option
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selection = option
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(title(option))
                            .font(tabFont(isSelected: isSelected))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        ZStack {
                            Capsule()
                                .fill(Color.clear)
                                .frame(height: 3)
                            if isSelected {
                                Capsule()
                                    .fill(Color.blue)
                                    .frame(width: 22, height: 3)
                                    .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tabFont(isSelected: Bool) -> Font {
        if usesCompactLayout {
            return isSelected ? .headline.bold() : .headline.weight(.medium)
        }
        return isSelected ? .title3.bold() : .title3.weight(.medium)
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
                .lineLimit(axis == .vertical ? 1...6 : 1...1)
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
        .padding(.leading, 12)
        .padding(.trailing, 14)
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

struct SheetDeleteButton: View {
    let title: String
    var confirmation: DeleteConfirmationContent?
    let onDelete: () -> Void

    @State private var isShowingConfirmation = false

    var body: some View {
        Button(role: .destructive) {
            if confirmation != nil {
                isShowingConfirmation = true
            } else {
                onDelete()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .alert(confirmation?.title ?? "确认删除", isPresented: $isShowingConfirmation) {
            Button("取消", role: .cancel) {}
            Button(confirmation?.confirmTitle ?? "删除", role: .destructive) {
                onDelete()
            }
        } message: {
            if let confirmation {
                Text(confirmation.message)
            }
        }
    }
}

struct LongPressDeleteModifier: ViewModifier {
    let confirmation: DeleteConfirmationContent
    let onDelete: (() -> Void)?
    var isPinned: Bool = false
    var onTogglePin: (() -> Void)? = nil
    var presentation: LongPressActionPresentation = .contextMenu

    @State private var isShowingConfirmation = false
    @State private var isShowingActionsOverlay = false
    @State private var itemFrame: CGRect = .zero

    func body(content: Content) -> some View {
        if onDelete != nil || onTogglePin != nil {
            switch presentation {
            case .contextMenu:
                content
                    .contextMenu {
                        if let onTogglePin {
                            Button {
                                onTogglePin()
                            } label: {
                                Label(isPinned ? "取消置顶" : "置顶", systemImage: isPinned ? "pin.slash" : "pin")
                            }
                        }
                        if onDelete != nil {
                            Button(role: .destructive) {
                                isShowingConfirmation = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                    .confirmationDialog(
                        confirmation.title,
                        isPresented: $isShowingConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(confirmation.confirmTitle, role: .destructive) {
                            onDelete?()
                        }
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text(confirmation.message)
                    }

            case .blurredOverlay:
                content
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                itemFrame = geo.frame(in: .global)
                            }
                            .onChange(of: geo.frame(in: .global)) { newFrame in
                                itemFrame = newFrame
                            }
                        }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                isShowingActionsOverlay = true
                            }
                    )
                    .fullScreenCover(isPresented: $isShowingActionsOverlay) {
                        LongPressActionsOverlay(
                            isPinned: isPinned,
                            canDelete: onDelete != nil,
                            itemFrame: itemFrame,
                            highlightContent: { content },
                            onTogglePin: {
                                isShowingActionsOverlay = false
                                onTogglePin?()
                            },
                            onDelete: {
                                isShowingActionsOverlay = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                    isShowingConfirmation = true
                                }
                            }
                        )
                        .presentationBackground(.clear)
                    }
                    .confirmationDialog(
                        confirmation.title,
                        isPresented: $isShowingConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(confirmation.confirmTitle, role: .destructive) {
                            onDelete?()
                        }
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text(confirmation.message)
                    }
            }
        } else {
            content
        }
    }
}

struct LongPressActionsOverlay<HighlightContent: View>: View {
    let isPinned: Bool
    let canDelete: Bool
    let itemFrame: CGRect
    @ViewBuilder let highlightContent: () -> HighlightContent
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            let menuWidth = min(308, proxy.size.width - 64)
            let menuHeight: CGFloat = canDelete ? 118 : 64
            let menuX = min(max(itemFrame.midX, menuWidth / 2 + 16), proxy.size.width - menuWidth / 2 - 16)
            let bottomMenuY = itemFrame.maxY + 14 + menuHeight / 2
            let topMenuY = itemFrame.minY - 14 - menuHeight / 2
            let menuY = bottomMenuY < proxy.size.height - 96 ? bottomMenuY : max(80 + menuHeight / 2, topMenuY)

            ZStack {
                Rectangle()
                    .fill(.regularMaterial)
                    .ignoresSafeArea()

                Color.black.opacity(0.22)
                    .ignoresSafeArea()

                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                if itemFrame != .zero {
                    highlightContent()
                        .frame(width: itemFrame.width, height: itemFrame.height, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
                        .position(x: itemFrame.midX, y: itemFrame.midY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                actionMenu
                    .frame(width: menuWidth)
                    .position(x: menuX, y: menuY)
            }
        }
    }

    private var actionMenu: some View {
        VStack(spacing: 0) {
            Button {
                onTogglePin()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 28)

                    Text(isPinned ? "取消置顶" : "置顶")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: 58)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if canDelete {
                Divider()
                    .padding(.leading, 60)

                Button {
                    onDelete()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .frame(width: 28)

                        Text("删除")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.red)

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
    }
}

extension View {
    func longPressDelete(_ confirmation: DeleteConfirmationContent, onDelete: (() -> Void)?) -> some View {
        modifier(LongPressDeleteModifier(confirmation: confirmation, onDelete: onDelete))
    }

    func longPressActions(
        _ confirmation: DeleteConfirmationContent,
        onDelete: (() -> Void)?,
        isPinned: Bool,
        onTogglePin: (() -> Void)?,
        presentation: LongPressActionPresentation = .contextMenu
    ) -> some View {
        modifier(LongPressDeleteModifier(
            confirmation: confirmation,
            onDelete: onDelete,
            isPinned: isPinned,
            onTogglePin: onTogglePin,
            presentation: presentation
        ))
    }
}

struct SheetPinButton: View {
    let isPinned: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                Text(isPinned ? "取消置顶" : "置顶")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
