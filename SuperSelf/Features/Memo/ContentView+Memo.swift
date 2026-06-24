import SwiftUI
import UIKit

enum MemoCalendarSpecialDayKind {
    case holiday
    case solarTerm
}

struct MemoCalendarSpecialDay {
    let name: String
    let kind: MemoCalendarSpecialDayKind
    let description: String
}

struct MemoCalendarSolarTermRule {
    let name: String
    let month: Int
    let century20: Double
    let century21: Double
}

struct MemoCalendarReminderItem: Identifiable {
    enum Kind {
        case todo
        case anniversary
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let extraText: String?
    let countdownText: String
    let date: Date
    let icon: String
    let tint: Color
}

struct MemoCalendarDayContext {
    let date: Date
    let specialDay: MemoCalendarSpecialDay?
    let anniversaryItems: [AnniversaryItem]
    let todoItems: [TodoTask]
    let dayLabel: String?
}

struct MemoCalendarMonthPage {
    let month: Date
    let cells: [MemoCalendarDayContext?]

    var weekCount: Int {
        max(1, cells.count / 7)
    }
}

struct HorizontalPanHost<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let onChanged: (CGSize) -> Void
    let onEnded: (CGSize, CGSize) -> Void

    init(
        @ViewBuilder content: () -> Content,
        onChanged: @escaping (CGSize) -> Void,
        onEnded: @escaping (CGSize, CGSize) -> Void
    ) {
        self.content = content()
        self.onChanged = onChanged
        self.onEnded = onEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    func makeUIViewController(context: Context) -> ContainerViewController<Content> {
        let controller = ContainerViewController(rootView: content, coordinator: context.coordinator)
        controller.applyColorScheme(context.environment.colorScheme)
        return controller
    }

    func updateUIViewController(_ uiViewController: ContainerViewController<Content>, context: Context) {
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
        uiViewController.update(rootView: content)
        uiViewController.applyColorScheme(context.environment.colorScheme)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChanged: (CGSize) -> Void
        var onEnded: (CGSize, CGSize) -> Void

        init(
            onChanged: @escaping (CGSize) -> Void,
            onEnded: @escaping (CGSize, CGSize) -> Void
        ) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let translation = recognizer.translation(in: view)
            let velocity = recognizer.velocity(in: view)
            let translationSize = CGSize(width: translation.x, height: translation.y)
            let velocitySize = CGSize(width: velocity.x, height: velocity.y)

            switch recognizer.state {
            case .began, .changed:
                onChanged(translationSize)
            case .ended, .cancelled, .failed:
                onEnded(translationSize, velocitySize)
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = gestureRecognizer.view else {
                return true
            }

            let velocity = panGesture.velocity(in: view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }
    }

    final class ContainerViewController<HostedContent: View>: UIViewController {
        private let hostingController: UIHostingController<HostedContent>

        init(rootView: HostedContent, coordinator: Coordinator) {
            self.hostingController = UIHostingController(rootView: rootView)
            super.init(nibName: nil, bundle: nil)

            let panGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
            panGesture.delegate = coordinator
            view.addGestureRecognizer(panGesture)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            hostingController.view.backgroundColor = .clear
            addChild(hostingController)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostingController.view)
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            hostingController.didMove(toParent: self)
        }

        func update(rootView: HostedContent) {
            hostingController.rootView = rootView
        }

        func applyColorScheme(_ colorScheme: ColorScheme) {
            let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
            overrideUserInterfaceStyle = style
            hostingController.overrideUserInterfaceStyle = style
            view.setNeedsLayout()
            hostingController.view.setNeedsLayout()
        }
    }
}

extension ContentView {
    static let memoCalendarSolarTermRules: [MemoCalendarSolarTermRule] = [
        .init(name: "小寒", month: 1, century20: 6.11, century21: 5.4055),
        .init(name: "大寒", month: 1, century20: 20.84, century21: 20.12),
        .init(name: "立春", month: 2, century20: 4.6295, century21: 3.87),
        .init(name: "雨水", month: 2, century20: 19.4599, century21: 18.73),
        .init(name: "惊蛰", month: 3, century20: 6.3826, century21: 5.63),
        .init(name: "春分", month: 3, century20: 21.4155, century21: 20.646),
        .init(name: "清明", month: 4, century20: 5.59, century21: 4.81),
        .init(name: "谷雨", month: 4, century20: 20.888, century21: 20.1),
        .init(name: "立夏", month: 5, century20: 6.318, century21: 5.52),
        .init(name: "小满", month: 5, century20: 21.86, century21: 21.04),
        .init(name: "芒种", month: 6, century20: 6.5, century21: 5.678),
        .init(name: "夏至", month: 6, century20: 22.2, century21: 21.37),
        .init(name: "小暑", month: 7, century20: 7.928, century21: 7.108),
        .init(name: "大暑", month: 7, century20: 23.65, century21: 22.83),
        .init(name: "立秋", month: 8, century20: 8.35, century21: 7.5),
        .init(name: "处暑", month: 8, century20: 23.95, century21: 23.13),
        .init(name: "白露", month: 9, century20: 8.44, century21: 7.646),
        .init(name: "秋分", month: 9, century20: 23.822, century21: 23.042),
        .init(name: "寒露", month: 10, century20: 9.098, century21: 8.318),
        .init(name: "霜降", month: 10, century20: 24.218, century21: 23.438),
        .init(name: "立冬", month: 11, century20: 8.218, century21: 7.438),
        .init(name: "小雪", month: 11, century20: 23.08, century21: 22.36),
        .init(name: "大雪", month: 12, century20: 7.9, century21: 7.18),
        .init(name: "冬至", month: 12, century20: 22.6, century21: 21.94)
    ]

    var memoCalendarSection: some View {
        VStack(spacing: 20) {
            memoCalendarCard
            memoCalendarSelectedDetailCard
            memoCalendarUpcomingRemindersCard
        }
    }

    var memoCalendarCard: some View {
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    moveMemoCalendarMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color.blue.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(memoCalendarMonthTitle)
                        .font(.title3.bold())
                    Text(memoCalendarSelectedDateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !memoCalendarIsSelectedToday {
                    Button("今天") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            memoCalendarMonth = Date()
                            memoCalendarSelectedDate = Calendar.current.startOfDay(for: Date())
                        }
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.10), in: Capsule())
                }

                Button {
                    moveMemoCalendarMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color.blue.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
            }

            memoCalendarPager
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var memoCalendarPager: some View {
        let weekdayHeaderHeight: CGFloat = 18
        let pagerTotalHeight = weekdayHeaderHeight + 10 + memoCalendarPagerHeight

        return HorizontalPanHost {
            VStack(spacing: 10) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 10) {
                    ForEach(Array(memoCalendarWeekdays.enumerated()), id: \.offset) { index, weekday in
                        Text(weekday)
                            .font(.caption.bold())
                            .foregroundStyle(index >= 5 ? .red : .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                GeometryReader { proxy in
                    let pageWidth = proxy.size.width

                    HStack(spacing: 0) {
                        ForEach(memoCalendarPages, id: \.month.timeIntervalSinceReferenceDate) { page in
                            memoCalendarMonthGrid(for: page)
                                .frame(width: pageWidth)
                        }
                    }
                    .offset(x: -pageWidth + memoCalendarSwipeOffset)
                    .animation(
                        isMemoCalendarSwipeAnimating
                            ? .spring(response: 0.24, dampingFraction: 0.86)
                            : nil,
                        value: memoCalendarSwipeOffset
                    )
                    .frame(width: pageWidth, alignment: .leading)
                    .clipped()
                    .onAppear {
                        memoCalendarPageWidth = pageWidth
                        refreshMemoCalendarPages()
                    }
                    .onChange(of: pageWidth) { _, newWidth in
                        memoCalendarPageWidth = newWidth
                    }
                }
                .frame(height: memoCalendarPagerHeight)
                .clipped()
            }
            .contentShape(Rectangle())
        } onChanged: { translation in
            handleMemoCalendarSwipeChanged(
                horizontalOffset: translation.width,
                verticalOffset: translation.height
            )
        } onEnded: { translation, velocity in
            handleMemoCalendarSwipeEnded(
                horizontalOffset: translation.width,
                verticalOffset: translation.height,
                velocityWidth: velocity.width
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: pagerTotalHeight)
        .onAppear(perform: refreshMemoCalendarPages)
        .onChange(of: memoCalendarMonth) { _, _ in
            refreshMemoCalendarPages()
        }
        .onChange(of: todoTasks) { _, _ in
            refreshMemoCalendarPages()
        }
        .onChange(of: anniversaryItems) { _, _ in
            refreshMemoCalendarPages()
        }
    }

    var memoCalendarPagerMonths: [Date] {
        [-1, 0, 1].compactMap { offset in
            Calendar.current.date(byAdding: .month, value: offset, to: memoCalendarMonth)
        }
    }

    var memoCalendarPagerHeight: CGFloat {
        let maxCount = memoCalendarPages.map(\.weekCount).max() ?? 6
        return CGFloat(maxCount) * 54 + CGFloat(max(0, maxCount - 1)) * 10
    }

    @ViewBuilder
    func memoCalendarMonthGrid(for page: MemoCalendarMonthPage) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 10) {
            ForEach(Array(page.cells.enumerated()), id: \.offset) { _, dayContext in
                if let dayContext {
                    memoCalendarDayCell(dayContext)
                } else {
                    Color.clear
                        .frame(height: 54)
                }
            }
        }
    }

    var memoCalendarSelectedDetailCard: some View {
        let selectedAnniversaryItems = memoCalendarAnniversaryItems(on: memoCalendarSelectedDate)
        let selectedSpecialDay = memoCalendarSpecialDay(for: memoCalendarSelectedDate)
        let selectedTodoItems = memoCalendarTodoItems(on: memoCalendarSelectedDate)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                memoCalendarSelectedLeadingIcon(for: selectedAnniversaryItems)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(memoCalendarSelectedFullDateText)
                            .font(.subheadline.bold())

                        Spacer(minLength: 8)

                        Text(memoCalendarSelectedDistanceText)
                            .font(.caption.bold())
                            .foregroundStyle(memoCalendarSelectedDistanceTint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(memoCalendarSelectedDistanceTint.opacity(0.12), in: Capsule())
                    }

                    Text(memoCalendarSelectedLunarDateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let selectedSpecialDay {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: memoCalendarSpecialDayIconName(for: selectedSpecialDay))
                                .font(.subheadline.bold())
                                .foregroundStyle(memoCalendarSpecialDayTint(for: selectedSpecialDay))
                                .frame(width: 28, height: 28)
                                .background(
                                    memoCalendarSpecialDayTint(for: selectedSpecialDay).opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedSpecialDay.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(memoCalendarSpecialDayTint(for: selectedSpecialDay))

                                Text(selectedSpecialDay.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            memoCalendarSpecialDayTint(for: selectedSpecialDay).opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }

                    if !selectedAnniversaryItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(selectedAnniversaryItems.prefix(3)) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: item.kind.icon)
                                        .font(.caption.bold())
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                    if item.showsElapsedDays {
                                        Text(elapsedDaysText(for: item))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if !selectedTodoItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(selectedTodoItems.prefix(3)) { task in
                                HStack(spacing: 8) {
                                    Image(systemName: "checklist")
                                        .font(.caption.bold())
                                    Text(task.title)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                    Text("截止")
                                        .font(.caption2.weight(.semibold))
                                }
                                .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if selectedSpecialDay == nil && selectedAnniversaryItems.isEmpty && selectedTodoItems.isEmpty {
                        Text("这一天暂时没有节日、节气、纪念日或截止任务，适合留给普通但也值得记住的一天。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var memoCalendarUpcomingRemindersCard: some View {
        let upcomingItems = Array(memoCalendarUpcomingReminderItems.prefix(5))

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("近期提醒")
                    .font(.headline.bold())

                Spacer()

                if !upcomingItems.isEmpty {
                    Text("最近 \(upcomingItems.count) 项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if upcomingItems.isEmpty {
                AppEmptyState(
                    title: "还没有近期提醒",
                    systemImage: "calendar.badge.clock",
                    description: "有截止日期的 TODO 和纪念日都会出现在这里。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 10) {
                    ForEach(upcomingItems) { item in
                        HStack(spacing: 12) {
                            if item.kind == .anniversary {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.red)
                                    .frame(width: 38, height: 38)
                            } else {
                                Image(systemName: item.icon)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(item.tint)
                                    .frame(width: 38, height: 38)
                                    .background(
                                        item.tint.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let extraText = item.extraText {
                                    Text(extraText)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 8)

                            Text(item.countdownText)
                                .font(.caption.bold())
                                .foregroundStyle(item.tint)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    item.tint.opacity(0.10),
                                    in: Capsule()
                                )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func memoCalendarDayCell(_ dayContext: MemoCalendarDayContext) -> some View {
        let calendar = Calendar.current
        let date = dayContext.date
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: memoCalendarSelectedDate)
        let isWeekend = memoCalendarIsWeekend(date)
        let specialDay = dayContext.specialDay
        let anniversaryItems = dayContext.anniversaryItems
        let todoItems = dayContext.todoItems
        let dayLabel = dayContext.dayLabel
        let dayLabelTint = memoCalendarDayLabelTint(
            isSelected: isSelected,
            isAnniversary: !anniversaryItems.isEmpty,
            hasTodo: !todoItems.isEmpty,
            specialDay: specialDay
        )

        return Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
                memoCalendarSelectedDate = calendar.startOfDay(for: date)
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? .white : (isToday ? .blue : (isWeekend ? .red : .primary)))

                if let dayLabel {
                    if anniversaryItems.isEmpty {
                        Text(dayLabel)
                            .font(.system(size: 9, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(dayLabelTint)
                    } else {
                        Text(dayLabel)
                            .font(.system(size: 8, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(isSelected ? .blue : .white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1.5)
                            .background(
                                isSelected ? Color.white.opacity(0.92) : Color.blue,
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                    }
                } else {
                    Circle()
                        .fill(isToday ? (isSelected ? Color.white : Color.blue) : Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.gradient)
                } else if !anniversaryItems.isEmpty {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.08))
                } else if !todoItems.isEmpty {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.08))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        }
        .buttonStyle(.plain)
    }

    func refreshMemoCalendarPages() {
        memoCalendarPages = memoCalendarPagerMonths.map { month in
            let cells = memoCalendarDates(for: month).map { date -> MemoCalendarDayContext? in
                guard let date else { return nil }
                let specialDay = memoCalendarSpecialDay(for: date)
                let anniversaryItems = memoCalendarAnniversaryItems(on: date)
                let todoItems = memoCalendarTodoItems(on: date)
                return MemoCalendarDayContext(
                    date: date,
                    specialDay: specialDay,
                    anniversaryItems: anniversaryItems,
                    todoItems: todoItems,
                    dayLabel: memoCalendarDayLabel(
                        specialDay: specialDay,
                        anniversaryItems: anniversaryItems,
                        todoItems: todoItems
                    )
                )
            }
            return MemoCalendarMonthPage(month: month, cells: cells)
        }
    }

    var memoCalendarWeekdays: [String] {
        ["一", "二", "三", "四", "五", "六", "日"]
    }

    var memoCalendarIsSelectedToday: Bool {
        Calendar.current.isDateInToday(memoCalendarSelectedDate)
    }

    func memoCalendarIsWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    func memoCalendarDayLabel(
        specialDay: MemoCalendarSpecialDay?,
        anniversaryItems: [AnniversaryItem],
        todoItems: [TodoTask]
    ) -> String? {
        if let firstAnniversary = anniversaryItems.first {
            if anniversaryItems.count > 1 {
                return "\(firstAnniversary.title)+\(anniversaryItems.count - 1)"
            }
            return firstAnniversary.title
        }
        if let firstTodo = todoItems.first {
            if todoItems.count > 1 {
                return "TODO+\(todoItems.count - 1)"
            }
            return firstTodo.title.count <= 4 ? firstTodo.title : "TODO"
        }
        return specialDay?.name
    }

    func memoCalendarTodoItems(on date: Date) -> [TodoTask] {
        let calendar = Calendar.current
        return todoTasks
            .filter { !$0.isCompleted }
            .filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            .sorted { lhs, rhs in
                if lhs.isInProgress != rhs.isInProgress {
                    return lhs.isInProgress
                }

                switch (lhs.dueDate, rhs.dueDate) {
                case let (lhsDate?, rhsDate?):
                    if lhsDate != rhsDate { return lhsDate < rhsDate }
                case (.some, nil):
                    return true
                case (nil, .some):
                    return false
                case (nil, nil):
                    break
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func memoCalendarAnniversaryItems(on date: Date) -> [AnniversaryItem] {
        anniversaryItems
            .filter { memoCalendarAnniversary($0, occursOn: date) }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned
                }
                if lhs.kind != rhs.kind {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func memoCalendarAnniversary(_ item: AnniversaryItem, occursOn date: Date) -> Bool {
        switch item.calendarKind {
        case .solar:
            let calendar = Calendar.current
            let itemComponents = calendar.dateComponents([.month, .day], from: item.date)
            let targetComponents = calendar.dateComponents([.month, .day], from: date)
            return itemComponents.month == targetComponents.month
                && itemComponents.day == targetComponents.day

        case .lunar:
            var chineseCalendar = Calendar(identifier: .chinese)
            chineseCalendar.locale = Locale(identifier: "zh_CN")
            let itemComponents = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: item.date)
            let targetComponents = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
            return itemComponents.month == targetComponents.month
                && itemComponents.day == targetComponents.day
                && itemComponents.isLeapMonth == targetComponents.isLeapMonth
        }
    }

    func memoCalendarSpecialDay(for date: Date) -> MemoCalendarSpecialDay? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        switch (month, day) {
        case (1, 1):
            return .init(name: "元旦", kind: .holiday, description: "新一年的开始，适合给这一年定个轻一点的计划。")
        case (4, memoCalendarQingmingDay(for: year)):
            return .init(name: "清明", kind: .holiday, description: "清明既是节气，也是传统节日，常见于祭扫追思与踏青出游。")
        case (5, 1):
            return .init(name: "劳动", kind: .holiday, description: "劳动节，通常是法定假期，适合安排休息、出行或整理生活节奏。")
        case (10, 1):
            return .init(name: "国庆", kind: .holiday, description: "国庆节是法定节假日，通常会开启国庆假期，也是出行高峰。")
        default:
            break
        }

        var chineseCalendar = Calendar(identifier: .chinese)
        chineseCalendar.locale = Locale(identifier: "zh_CN")
        let lunarComponents = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        if lunarComponents.isLeapMonth != true,
           let lunarMonth = lunarComponents.month,
           let lunarDay = lunarComponents.day {
            switch (lunarMonth, lunarDay) {
            case (1, 1):
                return .init(name: "春节", kind: .holiday, description: "春节是最重要的传统节日，常用于团圆、拜年和开启新年生活。")
            case (1, 15):
                return .init(name: "元宵", kind: .holiday, description: "元宵节常见习俗有赏灯、猜灯谜、吃元宵，意味着春节尾声。")
            case (5, 5):
                return .init(name: "端午", kind: .holiday, description: "端午节是传统节日，常见习俗有吃粽子、赛龙舟，也属于法定节假日。")
            case (7, 7):
                return .init(name: "七夕", kind: .holiday, description: "七夕是中国传统节日，常被视作带有浪漫意味的民俗节日。")
            case (8, 15):
                return .init(name: "中秋", kind: .holiday, description: "中秋节强调团圆与赏月，也是常见的法定节假日。")
            case (9, 9):
                return .init(name: "重阳", kind: .holiday, description: "重阳节有登高、赏秋、敬老等传统含义。")
            case (12, 8):
                return .init(name: "腊八", kind: .holiday, description: "腊八通常被看作年节序幕之一，民俗上有喝腊八粥的习惯。")
            default:
                break
            }
        }

        return memoCalendarSolarTerm(for: date)
    }

    func memoCalendarQingmingDay(for year: Int) -> Int {
        let shortYear = year % 100
        return Int(Double(shortYear) * 0.2422 + 4.81) - Int(Double(shortYear - 1) / 4.0)
    }

    func memoCalendarSolarTerm(for date: Date) -> MemoCalendarSpecialDay? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let rule = Self.memoCalendarSolarTermRules.first(where: {
                  $0.month == month && memoCalendarSolarTermDay(for: year, rule: $0) == day
              }) else {
            return nil
        }

        return .init(
            name: rule.name,
            kind: .solarTerm,
            description: memoCalendarSolarTermDescription(for: rule.name)
        )
    }

    func memoCalendarSolarTermDay(for year: Int, rule: MemoCalendarSolarTermRule) -> Int {
        let shortYear = year % 100
        let centuryValue = year >= 2001 ? rule.century21 : rule.century20
        let leapAdjustedYear = rule.month <= 2 ? shortYear - 1 : shortYear
        let leapAdjustment = Int(Double(max(leapAdjustedYear, 0)) / 4.0)
        return Int(Double(shortYear) * 0.2422 + centuryValue) - leapAdjustment
    }

    func memoCalendarSolarTermDescription(for name: String) -> String {
        switch name {
        case "小寒":
            return "小寒意味着进入严冬时段，天气偏冷，注意保暖和作息稳定。"
        case "大寒":
            return "大寒通常是一年中寒意较重的阶段，适合收敛节奏、养精蓄锐。"
        case "立春":
            return "立春表示春季开始，气温会逐步回升，万物进入新一轮生长。"
        case "雨水":
            return "雨水之后降水渐多，空气湿润，春天的感觉会更明显。"
        case "惊蛰":
            return "惊蛰象征春雷始动、万物萌发，常被视作春耕准备节点。"
        case "春分":
            return "春分昼夜接近均分，春意更盛，体感通常比前期更舒展。"
        case "清明":
            return "清明也是节气，往往天气转暖，适合踏青出游和整理春日安排。"
        case "谷雨":
            return "谷雨意味着春季后段雨水增多，对农作物生长尤其关键。"
        case "立夏":
            return "立夏表示夏季开始，气温和日照会进一步增强。"
        case "小满":
            return "小满意味着作物籽粒渐满但未全熟，通常也提示天气渐热。"
        case "芒种":
            return "芒种适合抢收抢种，是农时较忙的节气之一。"
        case "夏至":
            return "夏至是一年中白昼较长的时段之一，之后天气通常会更热。"
        case "小暑":
            return "小暑说明盛夏已近，闷热感会逐步增强。"
        case "大暑":
            return "大暑常是一年里体感最热的阶段之一，注意补水和休息。"
        case "立秋":
            return "立秋表示节气上进入秋季，但很多地区暑气仍未明显消退。"
        case "处暑":
            return "处暑意味着暑气开始收敛，早晚体感通常会慢慢转凉。"
        case "白露":
            return "白露之后昼夜温差会更明显，清晨常有露水。"
        case "秋分":
            return "秋分昼夜接近均分，天气往往更适合户外活动。"
        case "寒露":
            return "寒露意味着秋意更深，露水渐寒，体感会明显偏凉。"
        case "霜降":
            return "霜降常意味着秋季尾声，冷空气活动会更频繁。"
        case "立冬":
            return "立冬表示冬季开始，适合逐步切换到更保暖的生活节奏。"
        case "小雪":
            return "小雪代表天气进一步转冷，部分地区开始出现降雪迹象。"
        case "大雪":
            return "大雪意味着仲冬加深，寒冷和降雪概率都会提升。"
        case "冬至":
            return "冬至是一年中白昼较短的节点之一，也常被视作重要节令。"
        default:
            return "这是一个重要节气，反映季节变化和自然节律。"
        }
    }

    var memoCalendarDates: [Date?] {
        memoCalendarDates(for: memoCalendarMonth)
    }

    func memoCalendarDates(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }

        let firstDay = monthInterval.start
        let leadingEmptyDays = (calendar.component(.weekday, from: firstDay) + 5) % 7
        let dates = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
        let totalCount = leadingEmptyDays + dates.count
        let trailingEmptyDays = (7 - totalCount % 7) % 7

        return Array(repeating: nil, count: leadingEmptyDays)
            + dates.map(Optional.some)
            + Array(repeating: nil, count: trailingEmptyDays)
    }

    var memoCalendarMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: memoCalendarMonth)
    }

    var memoCalendarSelectedDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: memoCalendarSelectedDate)
    }

    var memoCalendarSelectedFullDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: memoCalendarSelectedDate)
    }

    var memoCalendarSelectedLunarDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .chinese)
        formatter.setLocalizedDateFormatFromTemplate("MMMEd")
        return "农历 \(formatter.string(from: memoCalendarSelectedDate))"
    }

    var memoCalendarSelectedDistanceText: String {
        memoCalendarDistanceText(from: Date(), to: memoCalendarSelectedDate)
    }

    func memoCalendarDayLabelTint(
        isSelected: Bool,
        isAnniversary: Bool,
        hasTodo: Bool,
        specialDay: MemoCalendarSpecialDay?
    ) -> Color {
        if isAnniversary {
            return isSelected ? .blue : .white
        }
        if hasTodo {
            return isSelected ? .white : .orange
        }
        if isSelected {
            return .white.opacity(0.92)
        }
        switch specialDay?.kind {
        case .holiday:
            return .red
        case .solarTerm:
            return .blue
        case nil:
            return .secondary
        }
    }

    func memoCalendarSpecialDayTint(for specialDay: MemoCalendarSpecialDay) -> Color {
        switch specialDay.kind {
        case .holiday:
            return .red
        case .solarTerm:
            return .blue
        }
    }

    func memoCalendarSpecialDayIconName(for specialDay: MemoCalendarSpecialDay) -> String {
        switch specialDay.kind {
        case .holiday:
            return "flag.fill"
        case .solarTerm:
            return "leaf.fill"
        }
    }

    func memoCalendarSelectedIconName(for anniversaryItems: [AnniversaryItem]) -> String {
        anniversaryItems.first?.kind.icon ?? "calendar"
    }

    func memoCalendarSelectedIconTint(for anniversaryItems: [AnniversaryItem]) -> Color {
        switch anniversaryItems.first?.kind {
        case .birthday:
            return .orange
        case .wedding:
            return .pink
        case .other:
            return .blue
        case nil:
            return .blue
        }
    }

    @ViewBuilder
    func memoCalendarSelectedLeadingIcon(for anniversaryItems: [AnniversaryItem]) -> some View {
        if !anniversaryItems.isEmpty {
            Image(systemName: "heart.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.red)
                .frame(width: 34, height: 34)
        } else {
            Image(systemName: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.10), in: Circle())
        }
    }

    var memoCalendarUpcomingReminderItems: [MemoCalendarReminderItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todoReminderItems = todoTasks.compactMap { task -> MemoCalendarReminderItem? in
            guard !task.isCompleted,
                  let dueDate = task.dueDate,
                  calendar.startOfDay(for: dueDate) >= today else {
                return nil
            }

            return MemoCalendarReminderItem(
                id: "todo-\(task.id.uuidString)",
                kind: .todo,
                title: task.title,
                subtitle: "TODO 截止 · \(memoCalendarReminderDateText(for: dueDate, includesTime: true))",
                extraText: task.priority.title,
                countdownText: memoCalendarCountdownText(to: dueDate),
                date: dueDate,
                icon: "checklist",
                tint: .orange
            )
        }

        let anniversaryReminderItems = sortedAnniversaryItems.compactMap { item -> MemoCalendarReminderItem? in
            guard let nextDate = nextAnniversaryDate(for: item),
                  calendar.startOfDay(for: nextDate) >= today else {
                return nil
            }

            return MemoCalendarReminderItem(
                id: "anniversary-\(item.id.uuidString)",
                kind: .anniversary,
                title: item.title,
                subtitle: "纪念日 · \(memoCalendarReminderDateText(for: nextDate, includesTime: false))",
                extraText: anniversarySolarText(for: item),
                countdownText: memoCalendarUpcomingCountdownText(for: item),
                date: nextDate,
                icon: item.kind.icon,
                tint: memoCalendarUpcomingItemTint(for: item)
            )
        }

        return (todoReminderItems + anniversaryReminderItems).sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }
            if lhs.kind != rhs.kind {
                return lhs.kind == .todo
            }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    func memoCalendarReminderDateText(for date: Date, includesTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = includesTime ? "M月d日 HH:mm EEEE" : "M月d日 EEEE"
        return formatter.string(from: date)
    }

    func memoCalendarCountdownText(to date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        if days == 0 {
            return "今天"
        }
        return days > 0 ? "\(days)天后" : "\(abs(days))天前"
    }

    func memoCalendarUpcomingItemTint(for item: AnniversaryItem) -> Color {
        switch item.kind {
        case .birthday:
            return .orange
        case .wedding:
            return .pink
        case .other:
            return .blue
        }
    }

    func memoCalendarUpcomingDateText(for item: AnniversaryItem) -> String {
        guard let nextDate = nextAnniversaryDate(for: item) else {
            return anniversaryDateText(for: item)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: nextDate)
    }

    func memoCalendarUpcomingCountdownText(for item: AnniversaryItem) -> String {
        guard let days = daysUntilAnniversary(for: item) else { return "待定" }
        if days == 0 {
            return "今天"
        }
        return "\(days)天后"
    }

    var memoCalendarSelectedDistanceTint: Color {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: memoCalendarSelectedDate)
        ).day ?? 0

        if days == 0 {
            return .blue
        }
        return days > 0 ? .blue : .orange
    }

    func memoCalendarDistanceText(from sourceDate: Date, to targetDate: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: sourceDate),
            to: calendar.startOfDay(for: targetDate)
        ).day ?? 0

        if days == 0 {
            return "今天"
        }
        return days > 0 ? "\(days)天后" : "\(abs(days))天前"
    }

    func moveMemoCalendarMonth(by value: Int) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            let calendar = Calendar.current
            memoCalendarMonth = calendar.date(byAdding: .month, value: value, to: memoCalendarMonth) ?? memoCalendarMonth
            if !calendar.isDate(memoCalendarSelectedDate, equalTo: memoCalendarMonth, toGranularity: .month),
               let monthStart = calendar.dateInterval(of: .month, for: memoCalendarMonth)?.start {
                memoCalendarSelectedDate = monthStart
            }
        }
    }

    func handleMemoCalendarGridSwipe(_ value: DragGesture.Value) {
        let horizontalOffset = value.translation.width
        let verticalOffset = value.translation.height

        guard abs(horizontalOffset) > abs(verticalOffset),
              abs(horizontalOffset) > 42 else {
            return
        }

        moveMemoCalendarMonth(by: horizontalOffset < 0 ? 1 : -1)
    }

    func handleMemoCalendarSwipeChanged(horizontalOffset: CGFloat, verticalOffset: CGFloat) {
        guard !isMemoCalendarSwipeAnimating else { return }

        if abs(horizontalOffset) >= abs(verticalOffset) {
            memoCalendarSwipeOffset = horizontalOffset
        }
    }

    func handleMemoCalendarSwipeEnded(
        horizontalOffset: CGFloat,
        verticalOffset: CGFloat,
        velocityWidth: CGFloat
    ) {
        guard !isMemoCalendarSwipeAnimating else { return }

        let predictedOffset = horizontalOffset + velocityWidth * 0.12
        let effectiveOffset = abs(predictedOffset) > abs(horizontalOffset) ? predictedOffset : horizontalOffset
        let threshold: CGFloat = 48

        guard abs(horizontalOffset) >= abs(verticalOffset) else {
            resetMemoCalendarSwipeOffset()
            return
        }

        let monthDelta: Int
        if effectiveOffset <= -threshold {
            monthDelta = 1
        } else if effectiveOffset >= threshold {
            monthDelta = -1
        } else {
            monthDelta = 0
        }

        guard monthDelta != 0 else {
            resetMemoCalendarSwipeOffset()
            return
        }

        isMemoCalendarSwipeAnimating = true
        let animationWidth = memoCalendarPageWidth > 0 ? memoCalendarPageWidth : UIScreen.main.bounds.width
        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
            memoCalendarSwipeOffset = monthDelta > 0 ? -animationWidth : animationWidth
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            let calendar = Calendar.current
            memoCalendarMonth = calendar.date(byAdding: .month, value: monthDelta, to: memoCalendarMonth) ?? memoCalendarMonth
            if !calendar.isDate(memoCalendarSelectedDate, equalTo: memoCalendarMonth, toGranularity: .month),
               let monthStart = calendar.dateInterval(of: .month, for: memoCalendarMonth)?.start {
                memoCalendarSelectedDate = monthStart
            }
            memoCalendarSwipeOffset = 0
            isMemoCalendarSwipeAnimating = false
        }
    }

    func resetMemoCalendarSwipeOffset() {
        isMemoCalendarSwipeAnimating = true
        withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
            memoCalendarSwipeOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            isMemoCalendarSwipeAnimating = false
        }
    }

    var anniversaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if anniversaryItems.isEmpty {
                AppEmptyState(
                    title: "还没有纪念日",
                    systemImage: "calendar.badge.plus",
                    description: "把生日、结婚纪念日或其他重要日子记下来。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedAnniversaryItems) { item in
                        AnniversaryRow(
                            item: item,
                            dateText: anniversaryDateText(for: item),
                            solarText: anniversarySolarText(for: item),
                            daysUntil: daysUntilAnniversary(for: item),
                            elapsedText: item.showsElapsedDays ? elapsedDaysText(for: item) : nil,
                            onEdit: {
                                editingAnniversaryItem = item
                            },
                            onDelete: {
                                deleteAnniversaryItem(item)
                            },
                            onTogglePin: {
                                toggleAnniversaryItemPin(item)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var anniversaryAddSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel("日期类型")
                        AppSegmentedControl(
                            options: AnniversaryCalendarKind.allCases,
                            selection: $anniversaryCalendarKind,
                            title: \.title
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel("名称")
                        ModernInputField(
                            placeholder: "记录个重要的日子",
                            text: $anniversaryTitleInput,
                            icon: "calendar.badge.heart",
                            tint: .blue
                        )
                        .focused($isAnniversaryTitleFocused)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        anniversaryFieldLabel(anniversaryCalendarKind == .lunar ? "日期（按农历选择）" : "日期")
                        WheelDatePicker(
                            date: $anniversaryDate,
                            calendarKind: anniversaryCalendarKind,
                            tint: .blue
                        )
                        .id(anniversaryCalendarKind)

                        if anniversaryCalendarKind == .lunar,
                           let solarPreview = anniversarySolarPreviewText(date: anniversaryDate, calendarKind: .lunar) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("今年对应阳历")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(solarPreview)
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

                    Toggle(isOn: $anniversaryShowsElapsedDays) {
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
            .navigationTitle("添加纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingAnniversarySheet = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addAnniversaryItem()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(!canAddAnniversary)
                }
            }
        }
        .presentationDetents([.large])
        .task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            isAnniversaryTitleFocused = true
        }
    }

    func anniversaryFieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }

    var todoTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            todoFilterBar
                .frame(maxWidth: .infinity, alignment: .leading)

            if activeTodoTasks.isEmpty && completedTodoTasks.isEmpty {
                AppEmptyState(
                    title: todoFilter == nil ? "还没有待办" : "这个优先级还没有待办",
                    systemImage: "checklist",
                    description: todoFilter == nil ? "把要做的事情写在这里，避免之后忘记。" : "可以直接在这个优先级下新增一条。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !activeTodoTasks.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(activeTodoTasks) { task in
                            TodoTaskRow(task: task, onMarkPending: {
                                setTodoTaskStatus(task, status: .pending)
                            }, onMarkInProgress: {
                                setTodoTaskStatus(task, status: .inProgress)
                            }, onMarkCompleted: {
                                setTodoTaskStatus(task, status: .completed)
                            }, onEdit: {
                                editingTodoTask = task
                            }, onDelete: {
                                deleteTodoTask(task)
                            }, onTogglePin: {
                                toggleTodoTaskPin(task)
                            })
                        }
                    }
                }

                if !completedTodoTasks.isEmpty {
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            ForEach(completedTodoTasks.prefix(8)) { task in
                                TodoTaskRow(task: task, onMarkPending: {
                                    setTodoTaskStatus(task, status: .pending)
                                }, onMarkInProgress: {
                                    setTodoTaskStatus(task, status: .inProgress)
                                }, onMarkCompleted: {
                                    setTodoTaskStatus(task, status: .completed)
                                }, onEdit: {
                                    editingTodoTask = task
                                }, onDelete: {
                                    deleteTodoTask(task)
                                }, onTogglePin: {
                                    toggleTodoTaskPin(task)
                                })
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                            Text("已完成 \(completedTodoTasks.count) 件")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .tint(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var memoNotesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            noteFilterSearchBar

            if isNoteSearchExpanded {
                noteSearchField
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if sortedMemoNotes.isEmpty {
                AppEmptyState(
                    title: memoNoteEmptyTitle,
                    systemImage: "square.text.square",
                    description: memoNoteEmptyDescription
                )
                .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedMemoNotes) { note in
                        MemoNoteCard(
                            note: note,
                            dateText: preciseDateTime(note.lastActivityAt),
                            imageDatas: note.imageFileNames.compactMap(loadMemoNoteImageData),
                            onTagTap: { tag in
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    noteTagFilter = tag
                                }
                            },
                            onEdit: {
                                editingMemoNote = note
                            },
                            onDelete: {
                                deleteMemoNote(note)
                            },
                            onTogglePin: {
                                toggleMemoNotePin(note)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var noteFilterSearchBar: some View {
        HStack(spacing: 10) {
            if !allMemoNoteTags.isEmpty {
                noteTagFilterBar
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    isNoteSearchExpanded.toggle()
                    if isNoteSearchExpanded {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isNoteSearchFocused = true
                        }
                    } else {
                        noteSearchText = ""
                        isNoteSearchFocused = false
                    }
                }
            } label: {
                Image(systemName: isNoteSearchExpanded ? "xmark" : "magnifyingglass")
                    .font(.subheadline.bold())
                    .foregroundStyle(isNoteSearchExpanded || !noteSearchText.isEmpty ? .white : .blue)
                    .frame(width: 36, height: 36)
                    .background((isNoteSearchExpanded || !noteSearchText.isEmpty) ? Color.blue : Color.blue.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isNoteSearchExpanded ? "收起搜索" : "搜索笔记")
        }
    }

    var noteSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("搜索笔记内容或标签", text: $noteSearchText)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isNoteSearchFocused)

            if !noteSearchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        noteSearchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var memoNoteEmptyTitle: String {
        if !noteSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "没有搜到相关笔记"
        }
        return noteTagFilter == nil ? "还没有笔记" : "这个标签下还没有笔记"
    }

    var memoNoteEmptyDescription: String {
        if !noteSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "换个关键词试试，搜索会匹配正文和标签。"
        }
        return noteTagFilter == nil ? "随手记想法、资料和灵感，也可以配图。" : "换个标签看看，或者在当前标签下新建一条。"
    }

    var todoFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                todoFilterChip(for: nil)
                ForEach(TodoPriority.allCases) { priority in
                    todoFilterChip(for: priority)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    func todoFilterChip(for priority: TodoPriority?) -> some View {
        let isSelected = todoFilter == priority
        let tint = priority?.color ?? .blue
        let title = priority?.title ?? "全部"

        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                todoFilter = priority
            }
        } label: {
            HStack(spacing: 5) {
                Text(title)

                let count = todoCount(for: priority)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background((isSelected ? Color.white.opacity(0.22) : tint.opacity(0.12)), in: Capsule())
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule().fill(tint.gradient)
                } else {
                    Capsule().fill(tint.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
    }

    var noteTagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                noteTagChip(for: nil)
                ForEach(allMemoNoteTags, id: \.self) { tag in
                    noteTagChip(for: tag)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    func noteTagChip(for tag: String?) -> some View {
        let isSelected = noteTagFilter == tag
        let title = tag ?? "全部"
        let tint = Color.blue

        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                noteTagFilter = tag
            }
        } label: {
            HStack(spacing: 5) {
                Text(title)

                let count = memoNoteCount(for: tag)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background((isSelected ? Color.white.opacity(0.22) : tint.opacity(0.12)), in: Capsule())
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule().fill(tint.gradient)
                } else {
                    Capsule().fill(tint.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
    }

    var wishlistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            wishlistFilterBar
                .frame(maxWidth: .infinity, alignment: .leading)

            if filteredOpenWishlistItems.isEmpty && filteredCompletedWishlistItems.isEmpty {
                AppEmptyState(
                    title: wishlistFilter == .all ? "还没有愿望" : "这里还没有愿望",
                    systemImage: "sparkles",
                    description: wishlistFilter == .all ? "把想读的书、想看的电影、想尝试的新鲜事都放进来。" : "可以直接在当前分类下新增一条。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !filteredOpenWishlistItems.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(filteredOpenWishlistItems) { item in
                            WishlistRow(item: item, category: wishlistCategory(for: item), onToggle: {
                                toggleWishlistItem(item)
                            }, onEdit: {
                                editingWishlistItem = item
                            }, onDelete: {
                                deleteWishlistItem(item)
                            }, onTogglePin: {
                                toggleWishlistItemPin(item)
                            })
                        }
                    }
                }

                if !filteredCompletedWishlistItems.isEmpty {
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            ForEach(filteredCompletedWishlistItems.prefix(8)) { item in
                                WishlistRow(item: item, category: wishlistCategory(for: item), onToggle: {
                                    toggleWishlistItem(item)
                                }, onEdit: {
                                    editingWishlistItem = item
                                }, onDelete: {
                                    deleteWishlistItem(item)
                                }, onTogglePin: {
                                    toggleWishlistItemPin(item)
                                })
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                            Text("已经实现 \(filteredCompletedWishlistItems.count) 个")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .tint(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var wishlistInputIcon: String {
        if wishlistFilter == .all {
            return WishlistFilter.all.icon
        }
        return wishlistCategories.first { $0.id == (wishlistFilter.categoryID ?? wishlistCategoryID) }?.icon ?? "sparkles"
    }

    var wishlistFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([WishlistFilter.all] + sortedWishlistCategories.map(WishlistFilter.init(category:))) { filter in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            wishlistFilter = filter
                            if let categoryID = filter.categoryID {
                                wishlistCategoryID = categoryID
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption.weight(.bold))

                            Text(filter.title)

                            let count = wishlistCount(for: filter)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background((wishlistFilter == filter ? Color.white.opacity(0.22) : Color.blue.opacity(0.12)), in: Capsule())
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(wishlistFilter == filter ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            if wishlistFilter == filter {
                                Capsule()
                                    .fill(Color.blue.gradient)
                            } else {
                                Capsule()
                                    .fill(Color.blue.opacity(0.08))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isShowingWishlistCategorySheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color.blue.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
    }
}
