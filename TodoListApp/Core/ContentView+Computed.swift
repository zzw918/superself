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
            .sorted { $0.createdAt > $1.createdAt }
    }

    var completedTodoTasks: [TodoTask] {
        todoTasks
            .filter(\.isCompleted)
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
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
        stockResearchItems.sorted { $0.updatedAt > $1.updatedAt }
    }

    var filteredStockResearchItems: [StockResearchItem] {
        let trimmedSearchText = stockSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return sortedStockResearchItems }

        return sortedStockResearchItems.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearchText)
        }
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
                    date: log.date,
                    weight: log.weight,
                    topLabel: chineseMonth(log.date),
                    bottomLabel: chineseDay(log.date)
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
        guard let height = Double(heightCm.replacingOccurrences(of: ",", with: ".")),
              let weight = latestWeightLog?.weight,
              height > 0 else {
            return nil
        }

        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }

    var targetWeightValue: Double? {
        Double(targetWeight.replacingOccurrences(of: ",", with: "."))
    }

    var bmiStatusText: String {
        guard let bmiValue else { return "录入身高和体重后显示 BMI" }

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
        guard let currentWeight = latestWeightLog?.weight, let targetWeightValue else {
            return "设置目标体重后，会显示距离目标还差多少。"
        }

        let difference = currentWeight - targetWeightValue

        if abs(difference) < 0.05 {
            return "已达标，继续保持"
        }

        if difference > 0 {
            return "还差 \(weightText(difference)) kg，抓紧"
        }

        return "低于目标 \(weightText(abs(difference))) kg，注意健康"
    }

    var targetProgressColor: Color {
        guard let currentWeight = latestWeightLog?.weight, let targetWeightValue else {
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
        guard let currentWeight = latestWeightLog?.weight, let targetWeightValue else {
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
}
