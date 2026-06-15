import SwiftUI

extension ContentView {
    var fastingStartDate: Date {
        Date(timeIntervalSince1970: fastingStartTime)
    }

    var phaseDuration: TimeInterval {
        TimeInterval((isFasting ? fastingGoalHours : eatingGoalHours) * 60 * 60)
    }

    var elapsed: TimeInterval {
        max(0, now.timeIntervalSince(fastingStartDate))
    }

    var remaining: TimeInterval {
        max(0, phaseDuration - elapsed)
    }

    var progress: Double {
        min(1, elapsed / phaseDuration)
    }

    var hasReachedCurrentGoal: Bool {
        elapsed >= phaseDuration
    }

    /// 超过当前阶段目标的时长（达标后才大于 0）。
    var overtime: TimeInterval {
        max(0, elapsed - phaseDuration)
    }

    /// 断食进度阶段：0 刚开始 → 3 临近，4 表示进入最后冲刺（剩余很短）。
    var fastingStage: Int {
        if remaining <= 30 * 60 { return 4 }
        switch progress {
        case ..<0.25: return 0
        case ..<0.5: return 1
        case ..<0.75: return 2
        default: return 3
        }
    }

    /// 倒计时环中央的标题：进食阶段固定，断食阶段随进度变化。
    var fastingPhaseHeadline: String {
        if isFasting {
            if hasReachedCurrentGoal { return "已达标，可以开吃" }

            switch fastingStage {
            case 0: return "刚刚开始，状态正好"
            case 1: return "渐入佳境"
            case 2: return "已经过半，稳住"
            case 3: return "胜利在望"
            default: return "最后冲刺"
            }
        }

        return hasReachedCurrentGoal ? "进食超时，该断食了" : "享受进食时间"
    }

    var phaseEndDate: Date {
        fastingStartDate.addingTimeInterval(phaseDuration)
    }

    var sortedWeightLogs: [FastingLog] {
        weightLogs.sorted { $0.date > $1.date }
    }

    var latestWeightLog: FastingLog? {
        sortedWeightLogs.first
    }

    var oldestWeightLog: FastingLog? {
        sortedWeightLogs.last
    }

    var sortedFastingSessions: [FastingSession] {
        fastingSessions.sorted { $0.endDate > $1.endDate }
    }

    var activeTodoTasks: [TodoTask] {
        todoTasks
            .filter { !$0.isCompleted }
            .filter { task in todoFilter == nil || task.priority == todoFilter }
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    var completedTodoTasks: [TodoTask] {
        todoTasks
            .filter(\.isCompleted)
            .filter { task in todoFilter == nil || task.priority == todoFilter }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    func todoCount(for priority: TodoPriority?) -> Int {
        guard let priority else {
            return todoTasks.filter { !$0.isCompleted }.count
        }
        return todoTasks.filter { !$0.isCompleted && $0.priority == priority }.count
    }

    var openWishlistItems: [WishlistItem] {
        wishlistItems
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var completedWishlistItems: [WishlistItem] {
        wishlistItems
            .filter(\.isCompleted)
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    var filteredOpenWishlistItems: [WishlistItem] {
        openWishlistItems.filter { item in
            wishlistFilter.categoryID.map { item.categoryID == $0 } ?? true
        }
    }

    var filteredCompletedWishlistItems: [WishlistItem] {
        completedWishlistItems.filter { item in
            wishlistFilter.categoryID.map { item.categoryID == $0 } ?? true
        }
    }

    func wishlistCount(for filter: WishlistFilter) -> Int {
        wishlistItems.filter { item in
            filter.categoryID.map { item.categoryID == $0 } ?? true
        }.count
    }

    var sortedWishlistCategories: [WishlistCategory] {
        wishlistCategories.enumerated().sorted { lhs, rhs in
            let lhsCount = wishlistCount(for: WishlistFilter(category: lhs.element))
            let rhsCount = wishlistCount(for: WishlistFilter(category: rhs.element))
            if lhsCount != rhsCount {
                return lhsCount > rhsCount
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
    }

    func wishlistCategory(for item: WishlistItem) -> WishlistCategory {
        wishlistCategories.first { $0.id == item.categoryID } ?? WishlistCategory.fallback
    }

    var sortedAnniversaryItems: [AnniversaryItem] {
        anniversaryItems.sorted { lhs, rhs in
            let lhsDate = nextAnniversaryDate(for: lhs) ?? lhs.date
            let rhsDate = nextAnniversaryDate(for: rhs) ?? rhs.date

            if lhsDate == rhsDate {
                return lhs.createdAt > rhs.createdAt
            }

            return lhsDate < rhsDate
        }
    }

    var canAddAnniversary: Bool {
        !anniversaryTitleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isEditingTabs: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var visibleMainTabs: [MainAppTab] {
        let orderedVisibleTabs = mainTabOrder.filter { visibleMainTabSet.contains($0) }
        return orderedVisibleTabs.isEmpty ? [.health] : orderedVisibleTabs
    }

    var visibleHealthSections: [HealthSection] {
        healthSectionPrefs.orderedVisible
    }

    var visibleMemoSections: [MemoSection] {
        memoSectionPrefs.orderedVisible
    }

    var visibleFinanceSections: [FinanceSection] {
        financeSectionPrefs.orderedVisible
    }

    var totalFinanceAmount: Double {
        financeAssets.map(\.amount).reduce(0, +)
    }

    var financeDistributionPoints: [FinanceDistributionPoint] {
        let amountsByKind = Dictionary(grouping: financeAssets, by: \.kind)
            .mapValues { assets in
                assets.map(\.amount).reduce(0, +)
            }

        return amountsByKind
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { index, item in
                FinanceDistributionPoint(
                    title: item.key.title,
                    amount: item.value,
                    color: financeDistributionColor(at: index)
                )
            }
    }

    var sortedFinanceAssets: [FinanceAsset] {
        financeAssets.sorted { $0.updatedAt > $1.updatedAt }
    }

    var sortedFinanceSnapshots: [FinanceSnapshot] {
        financeSnapshots.sorted { $0.date > $1.date }
    }

    var monthlyFinanceTrendPoints: [FinanceTrendPoint] {
        let snapshotsByMonth = Dictionary(grouping: financeSnapshots) { snapshot in
            Calendar.current.dateInterval(of: .month, for: snapshot.date)?.start ?? Calendar.current.startOfDay(for: snapshot.date)
        }

        let latestSnapshotsPerMonth = snapshotsByMonth.values.compactMap { snapshots in
            snapshots.max { $0.date < $1.date }
        }

        return Array(latestSnapshotsPerMonth.sorted { $0.date < $1.date }.suffix(12)).map { snapshot in
            FinanceTrendPoint(
                date: snapshot.date,
                amount: snapshot.totalAmount,
                topLabel: chineseYear(snapshot.date),
                bottomLabel: chineseMonth(snapshot.date)
            )
        }
    }

    var financeMonthChangeText: String? {
        guard let firstPoint = monthlyFinanceTrendPoints.first,
              let lastPoint = monthlyFinanceTrendPoints.last,
              firstPoint.id != lastPoint.id else {
            return nil
        }

        let change = lastPoint.amount - firstPoint.amount
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(currencyText(change))"
    }

    var sortedStockResearchItems: [StockResearchItem] {
        stockResearchItems.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    var hasActiveStockFilters: Bool {
        stockCertaintyFilter != nil || stockGrowthFilter != nil || stockAttentionFilter != nil
    }

    var filteredStockResearchItems: [StockResearchItem] {
        var items = sortedStockResearchItems

        let trimmedSearchText = stockSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(trimmedSearchText) }
        }

        if let certainty = stockCertaintyFilter {
            items = items.filter { $0.certainty == certainty }
        }
        if let growth = stockGrowthFilter {
            items = items.filter { $0.growth == growth }
        }
        if let attention = stockAttentionFilter {
            items = items.filter { $0.attention == attention }
        }

        return items
    }

    var dailyTrendLogs: [FastingLog] {
        let logsByDay = Dictionary(grouping: weightLogs) { log in
            Calendar.current.startOfDay(for: log.date)
        }

        let latestLogPerDay = logsByDay.values.compactMap { logs in
            logs.max { $0.date < $1.date }
        }

        return Array(latestLogPerDay.sorted { $0.date < $1.date }.suffix(30))
    }

    var trendPoints: [WeightTrendPoint] {
        switch trendGranularity {
        case .day:
            return dailyTrendLogs.map { log in
                WeightTrendPoint(
                    date: Calendar.current.startOfDay(for: log.date),
                    weight: log.weight,
                    topLabel: chineseMonth(log.date),
                    bottomLabel: dayNumber(log.date)
                )
            }
        case .week:
            return averagedTrendPoints(groupedBy: { log in
                isoCalendar.dateInterval(of: .weekOfYear, for: log.date)?.start ?? Calendar.current.startOfDay(for: log.date)
            }, labelFor: { date in
                (chineseMonth(date), "\(chineseDay(date))起")
            })
        case .month:
            return averagedTrendPoints(groupedBy: { log in
                Calendar.current.dateInterval(of: .month, for: log.date)?.start ?? Calendar.current.startOfDay(for: log.date)
            }, labelFor: { date in
                (chineseYear(date), chineseMonth(date))
            })
        }
    }

    var displayedWeightLogs: [FastingLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoffDate = calendar.date(byAdding: .day, value: -(visibleWeightHistoryDays - 1), to: today) ?? today

        return sortedWeightLogs.filter { $0.date >= cutoffDate }
    }

    var bmiValue: Double? {
        guard let height = heightValue,
              let weight = currentWeightValue,
              height > 0 else {
            return nil
        }

        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }

    var heightValue: Double? {
        Double(heightCm.replacingOccurrences(of: ",", with: "."))
    }

    var currentWeightValue: Double? {
        if let latestWeightLog {
            return latestWeightLog.weight
        }

        let normalizedWeight = latestWeight.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalizedWeight)
    }

    var targetWeightValue: Double? {
        Double(targetWeight.replacingOccurrences(of: ",", with: "."))
    }

    var isWeightInputEmpty: Bool {
        weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var weightInputPlaceholder: String {
        if let target = targetWeightValue {
            return weightText(target)
        }
        if let latest = latestWeightLog {
            return weightText(latest.weight)
        }
        return "0.0"
    }

    var bmiStatusText: String {
        guard let bmiValue else {
            if heightValue == nil {
                return "请先填写身高"
            }

            return "请先记录当前体重"
        }

        switch bmiValue {
        case ..<18.5:
            return "偏瘦"
        case 18.5..<24:
            return "正常"
        case 24..<28:
            return "偏胖"
        default:
            return "肥胖"
        }
    }

    var targetProgressText: String {
        guard let targetWeightValue else {
            return "设置目标体重后，这里会显示和目标的距离。"
        }

        guard let currentWeight = currentWeightValue else {
            return "先记录一次当前体重，才能计算离目标还差多少。"
        }

        let difference = currentWeight - targetWeightValue

        if abs(difference) < 0.05 {
            return "保持当前节奏，继续关注体脂和状态。"
        }

        if difference > 0 {
            return difference >= 3 ? "先稳住饮食和作息，再继续减重。" : "继续保持，离目标已经不远了。"
        }

        return "已经低于目标，建议优先关注健康状态。"
    }

    var targetProgressHeadline: String {
        guard let targetWeightValue else {
            return "去设置目标"
        }

        guard let currentWeight = currentWeightValue else {
            return "先记体重"
        }

        let difference = currentWeight - targetWeightValue

        if abs(difference) < 0.05 {
            return "已达标"
        }

        if difference > 0 {
            return "还差 \(weightText(difference)) kg"
        }

        return "低于目标 \(weightText(abs(difference))) kg"
    }

    var targetProgressColor: Color {
        guard let currentWeight = currentWeightValue, let targetWeightValue else {
            return .secondary
        }

        let difference = currentWeight - targetWeightValue

        if abs(difference) < 0.05 {
            return .green
        }

        if difference >= 3 {
            return .red
        }

        if difference > 0 {
            return .orange
        }

        return .orange
    }

    var targetProgressIcon: String {
        guard let currentWeight = currentWeightValue, let targetWeightValue else {
            return "flag.checkered"
        }

        let difference = currentWeight - targetWeightValue

        if abs(difference) < 0.05 {
            return "checkmark.seal.fill"
        }

        if difference > 0 {
            return difference >= 3 ? "exclamationmark.triangle.fill" : "flame.fill"
        }

        return "heart.text.square.fill"
    }

    /// 减重起点：取最早一次记录的体重，用来衡量已经减了多少。
    var weightStartValue: Double? {
        oldestWeightLog?.weight
    }

    /// 距离目标还差多少（仅在还需减重时返回正值）。
    var weightRemainingValue: Double? {
        guard let current = currentWeightValue, let target = targetWeightValue else { return nil }
        let diff = current - target
        return diff > 0.05 ? diff : nil
    }

    /// 相比起点已经减掉的体重。
    var weightLostValue: Double? {
        guard let start = weightStartValue, let current = currentWeightValue else { return nil }
        let lost = start - current
        return lost > 0.05 ? lost : nil
    }

    /// 减重进度 0...1（起点 → 目标）。
    var goalProgressFraction: Double? {
        guard let start = weightStartValue,
              let current = currentWeightValue,
              let target = targetWeightValue else { return nil }
        let total = start - target
        guard total > 0.05 else { return nil }
        let done = start - current
        return min(1, max(0, done / total))
    }
}
