import SwiftUI

private enum WeightTrendGranularity: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            return "天"
        case .week:
            return "周"
        case .month:
            return "月"
        }
    }
}

private struct WeightTrendPoint: Identifiable {
    let date: Date
    let weight: Double
    let topLabel: String
    let bottomLabel: String

    var id: String {
        "\(date.timeIntervalSince1970)-\(topLabel)-\(bottomLabel)"
    }
}

private struct FinanceTrendPoint: Identifiable {
    let date: Date
    let amount: Double
    let topLabel: String
    let bottomLabel: String

    var id: String {
        "\(date.timeIntervalSince1970)-\(amount)"
    }
}

private struct FinanceDistributionPoint: Identifiable {
    let title: String
    let amount: Double
    let color: Color

    var id: String { title }
}

private enum HealthSection: String, CaseIterable, Identifiable {
    case fasting
    case weight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fasting:
            return "16 + 8"
        case .weight:
            return "体重"
        }
    }
}

private enum MemoSection: String, CaseIterable, Identifiable {
    case todo
    case wishlist
    case anniversary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todo:
            return "TODO"
        case .wishlist:
            return "愿望清单"
        case .anniversary:
            return "纪念日"
        }
    }
}

private enum FinanceSection: String, CaseIterable, Identifiable {
    case assetRecord
    case stockResearch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assetRecord:
            return "资产记录"
        case .stockResearch:
            return "股票研究"
        }
    }
}

private enum MainAppTab: String, CaseIterable, Identifiable, Codable, Hashable {
    case health
    case todo
    case finance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health:
            return "健康"
        case .todo:
            return "备忘录"
        case .finance:
            return "理财"
        }
    }

    var icon: String {
        switch self {
        case .health:
            return "heart"
        case .todo:
            return "note.text"
        case .finance:
            return "yensign.circle"
        }
    }

    var description: String {
        switch self {
        case .health:
            return "16 + 8、体重和健康目标"
        case .todo:
            return "TODO、愿望清单和纪念日"
        case .finance:
            return "资产记录和股票研究"
        }
    }
}

private struct MainTabPreferences: Codable {
    var order: [MainAppTab]
    var visibleTabs: [MainAppTab]
}

struct ContentView: View {
    @Environment(\.editMode) private var editMode

    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let fastingStartTimeCloudKey = "fastingStartTime"
    private let isFastingCloudKey = "isFasting"
    private let latestWeightCloudKey = "latestWeight"
    private let weightLogsCloudKey = "weightLogs"
    private let fastingSessionsCloudKey = "fastingSessions"
    private let fastingGoalHoursCloudKey = "fastingGoalHours"
    private let eatingGoalHoursCloudKey = "eatingGoalHours"
    private let dailyGoalCloudKey = "dailyGoal"
    private let todoTasksCloudKey = "todoTasks"
    private let wishlistItemsCloudKey = "wishlistItems"
    private let anniversaryItemsCloudKey = "anniversaryItems"
    private let financeAssetsCloudKey = "financeAssets"
    private let financeSnapshotsCloudKey = "financeSnapshots"
    private let stockResearchItemsCloudKey = "stockResearchItems"
    private let mainTabPreferencesCloudKey = "mainTabPreferences"
    private let heightCmCloudKey = "heightCm"
    private let targetWeightCloudKey = "targetWeight"
    private let planOptions = [(fasting: 16, eating: 8), (fasting: 18, eating: 6), (fasting: 20, eating: 4)]
    private let isoCalendar = Calendar(identifier: .iso8601)

    @AppStorage("fastingStartTime") private var fastingStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("isFasting") private var isFasting = true
    @AppStorage("fastingGoalHours") private var fastingGoalHours = 16
    @AppStorage("eatingGoalHours") private var eatingGoalHours = 8
    @AppStorage("latestWeight") private var latestWeight = ""
    @AppStorage("weightLogs") private var weightLogsData = Data()
    @AppStorage("fastingSessions") private var fastingSessionsData = Data()
    @AppStorage("todoTasks") private var todoTasksData = Data()
    @AppStorage("wishlistItems") private var wishlistItemsData = Data()
    @AppStorage("anniversaryItems") private var anniversaryItemsData = Data()
    @AppStorage("financeAssets") private var financeAssetsData = Data()
    @AppStorage("financeSnapshots") private var financeSnapshotsData = Data()
    @AppStorage("stockResearchItems") private var stockResearchItemsData = Data()
    @AppStorage("mainTabPreferences") private var mainTabPreferencesData = Data()
    @AppStorage("dailyGoal") private var dailyGoal = "多喝水，优先吃蛋白质，散步 20 分钟"
    @AppStorage("heightCm") private var heightCm = ""
    @AppStorage("targetWeight") private var targetWeight = ""

    @State private var now = Date()
    @State private var weightInput = ""
    @State private var noteInput = ""
    @State private var weightLogs: [FastingLog] = []
    @State private var fastingSessions: [FastingSession] = []
    @State private var todoTasks: [TodoTask] = []
    @State private var wishlistItems: [WishlistItem] = []
    @State private var anniversaryItems: [AnniversaryItem] = []
    @State private var todoInput = ""
    @State private var wishlistInput = ""
    @State private var wishlistCategory: WishlistCategory = .travel
    @State private var anniversaryTitleInput = ""
    @State private var anniversaryKind: AnniversaryKind = .birthday
    @State private var anniversaryCalendarKind: AnniversaryCalendarKind = .solar
    @State private var anniversaryDate = Date()
    @State private var financeAssets: [FinanceAsset] = []
    @State private var financeSnapshots: [FinanceSnapshot] = []
    @State private var financeAssetNameInput = ""
    @State private var financeAssetAmountInput = ""
    @State private var financeAssetKind: FinanceAssetKind = .bankCard
    @State private var healthSection: HealthSection = .fasting
    @State private var memoSection: MemoSection = .todo
    @State private var financeSection: FinanceSection = .assetRecord
    @State private var stockResearchItems: [StockResearchItem] = []
    @State private var stockNameInput = ""
    @State private var stockSearchText = ""
    @State private var editingFinanceAsset: FinanceAsset?
    @State private var editingStockResearchItem: StockResearchItem?
    @State private var mainTabOrder = MainAppTab.allCases
    @State private var visibleMainTabSet = Set(MainAppTab.allCases)
    @State private var syncStatus = "iCloud 同步准备中"
    @State private var isShowingWeightSheet = false
    @State private var isShowingBodySettings = false
    @State private var isShowingFinanceAssetSheet = false
    @State private var isShowingAnniversarySheet = false
    @State private var trendGranularity: WeightTrendGranularity = .day
    @State private var visibleWeightHistoryDays = 10

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            ForEach(visibleMainTabs) { tab in
                mainTabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
            }

            profilePage
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
        }
        .onReceive(timer) { currentTime in
            now = currentTime
        }
        .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
            pullFromICloud()
        }
        .onAppear(perform: loadAppData)
        .onChange(of: dailyGoal) {
            persistSettingsToICloud()
        }
        .onChange(of: fastingGoalHours) {
            persistSettingsToICloud()
        }
        .onChange(of: eatingGoalHours) {
            persistSettingsToICloud()
        }
        .onChange(of: heightCm) {
            persistSettingsToICloud()
        }
        .onChange(of: targetWeight) {
            persistSettingsToICloud()
        }
        .sheet(isPresented: $isShowingWeightSheet) {
            addWeightSheet
        }
        .sheet(isPresented: $isShowingBodySettings) {
            bodySettingsSheet
        }
        .sheet(isPresented: $isShowingFinanceAssetSheet) {
            financeAddAssetSheet
        }
        .sheet(isPresented: $isShowingAnniversarySheet) {
            anniversaryAddSheet
        }
        .sheet(item: $editingFinanceAsset) { asset in
            FinanceAssetEditorSheet(asset: asset, amountText: currencyText(asset.amount)) { newAmount in
                updateFinanceAsset(asset, amount: newAmount)
            }
        }
        .sheet(item: $editingStockResearchItem) { item in
            StockResearchEditorSheet(
                item: item,
                thesis: stockResearchThesisBinding(for: item),
                updatedText: chineseDateTime(item.updatedAt)
            )
        }
    }

    @ViewBuilder
    private func mainTabContent(for tab: MainAppTab) -> some View {
        switch tab {
        case .health:
            healthPage
        case .todo:
            memoPage
        case .finance:
            financePage
        }
    }

    private var healthPage: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    healthSectionPicker

                    switch healthSection {
                    case .fasting:
                        fastingSection
                    case .weight:
                        weightSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("健康")
            .onChange(of: healthSection) { _, newSection in
                if newSection != .weight {
                    visibleWeightHistoryDays = 10
                }
            }
        }
    }

    private var healthSectionPicker: some View {
        AppSegmentedControl(
            options: HealthSection.allCases,
            selection: $healthSection,
            title: \.title
        )
    }

    private var fastingSection: some View {
        VStack(spacing: 20) {
            statusCard
            actionCard
            fastingHistoryCard
            planCard
        }
    }

    private var weightSection: some View {
        VStack(spacing: 20) {
            weightCard
            bmiCard
            trendCard
            historyCard
        }
    }

    private var memoPage: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    memoSectionPicker

                    switch memoSection {
                    case .todo:
                        todoTasksCard
                    case .wishlist:
                        wishlistCard
                    case .anniversary:
                        anniversaryCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("备忘录")
        }
    }

    private var memoSectionPicker: some View {
        AppSegmentedControl(
            options: MemoSection.allCases,
            selection: $memoSection,
            title: \.title
        )
    }

    private var financePage: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    financeSectionPicker

                    switch financeSection {
                    case .assetRecord:
                        financeAssetRecordSection
                    case .stockResearch:
                        stockResearchSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("理财")
        }
    }

    private var financeSectionPicker: some View {
        AppSegmentedControl(
            options: FinanceSection.allCases,
            selection: $financeSection,
            title: \.title
        )
    }

    private var financeAssetRecordSection: some View {
        VStack(spacing: 20) {
            financeSummaryCard
            financeTrendCard
            financeDistributionCard
            financeAssetsCard
        }
    }

    private var stockResearchSection: some View {
        VStack(spacing: 20) {
            stockResearchAddCard
            stockResearchListCard
        }
    }

    private var profilePage: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(mainTabOrder) { tab in
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(tab.title)
                                    .font(.headline)
                                Text(tab.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: mainTabVisibilityBinding(for: tab))
                                .labelsHidden()
                                .disabled(isOnlyVisibleMainTab(tab))
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: moveMainTabs)
                } header: {
                    HStack {
                        Text("功能管理")

                        Spacer()

                        Button {
                            toggleTabEditMode()
                        } label: {
                            Image(systemName: isEditingTabs ? "checkmark.circle.fill" : "square.and.pencil")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("拖动可调整健康、备忘录、理财的顺序；关闭开关可隐藏不常用功能。“我的”固定在最右侧，不参与排序和隐藏。")
                }

                Section {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("我的")
                                .font(.headline)
                            Text("固定在最右侧")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("固定")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    syncCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("数据同步")
                } footer: {
                    Text("健康、备忘录、理财、股票研究、功能设置和个人目标都会保存到本地，并在 iCloud 可用时同步。")
                }
            }
            .navigationTitle("我的")
        }
    }

    private var fastingStartDate: Date {
        Date(timeIntervalSince1970: fastingStartTime)
    }

    private var phaseDuration: TimeInterval {
        TimeInterval((isFasting ? fastingGoalHours : eatingGoalHours) * 60 * 60)
    }

    private var elapsed: TimeInterval {
        max(0, now.timeIntervalSince(fastingStartDate))
    }

    private var remaining: TimeInterval {
        max(0, phaseDuration - elapsed)
    }

    private var progress: Double {
        min(1, elapsed / phaseDuration)
    }

    private var hasReachedCurrentGoal: Bool {
        elapsed >= phaseDuration
    }

    private var phaseEndDate: Date {
        fastingStartDate.addingTimeInterval(phaseDuration)
    }

    private var sortedWeightLogs: [FastingLog] {
        weightLogs.sorted { $0.date > $1.date }
    }

    private var latestWeightLog: FastingLog? {
        sortedWeightLogs.first
    }

    private var oldestWeightLog: FastingLog? {
        sortedWeightLogs.last
    }

    private var sortedFastingSessions: [FastingSession] {
        fastingSessions.sorted { $0.endDate > $1.endDate }
    }

    private var activeTodoTasks: [TodoTask] {
        todoTasks
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var completedTodoTasks: [TodoTask] {
        todoTasks
            .filter(\.isCompleted)
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    private var openWishlistItems: [WishlistItem] {
        wishlistItems
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var completedWishlistItems: [WishlistItem] {
        wishlistItems
            .filter(\.isCompleted)
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    private var sortedAnniversaryItems: [AnniversaryItem] {
        anniversaryItems.sorted { lhs, rhs in
            let lhsDate = nextAnniversaryDate(for: lhs) ?? lhs.date
            let rhsDate = nextAnniversaryDate(for: rhs) ?? rhs.date

            if lhsDate == rhsDate {
                return lhs.createdAt > rhs.createdAt
            }

            return lhsDate < rhsDate
        }
    }

    private var canAddAnniversary: Bool {
        !anniversaryTitleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isEditingTabs: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    private var visibleMainTabs: [MainAppTab] {
        let orderedVisibleTabs = mainTabOrder.filter { visibleMainTabSet.contains($0) }
        return orderedVisibleTabs.isEmpty ? [.health] : orderedVisibleTabs
    }

    private var totalFinanceAmount: Double {
        financeAssets.map(\.amount).reduce(0, +)
    }

    private var financeDistributionPoints: [FinanceDistributionPoint] {
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

    private var sortedFinanceAssets: [FinanceAsset] {
        financeAssets.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var sortedFinanceSnapshots: [FinanceSnapshot] {
        financeSnapshots.sorted { $0.date > $1.date }
    }

    private var monthlyFinanceTrendPoints: [FinanceTrendPoint] {
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

    private var financeMonthChangeText: String? {
        guard let firstPoint = monthlyFinanceTrendPoints.first,
              let lastPoint = monthlyFinanceTrendPoints.last,
              firstPoint.id != lastPoint.id else {
            return nil
        }

        let change = lastPoint.amount - firstPoint.amount
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(currencyText(change))"
    }

    private var sortedStockResearchItems: [StockResearchItem] {
        stockResearchItems.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var filteredStockResearchItems: [StockResearchItem] {
        let trimmedSearchText = stockSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return sortedStockResearchItems }

        return sortedStockResearchItems.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    private var dailyTrendLogs: [FastingLog] {
        let logsByDay = Dictionary(grouping: weightLogs) { log in
            Calendar.current.startOfDay(for: log.date)
        }

        let latestLogPerDay = logsByDay.values.compactMap { logs in
            logs.max { $0.date < $1.date }
        }

        return Array(latestLogPerDay.sorted { $0.date < $1.date }.suffix(30))
    }

    private var trendPoints: [WeightTrendPoint] {
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

    private var displayedWeightLogs: [FastingLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoffDate = calendar.date(byAdding: .day, value: -(visibleWeightHistoryDays - 1), to: today) ?? today

        return sortedWeightLogs.filter { $0.date >= cutoffDate }
    }

    private var bmiValue: Double? {
        guard let height = Double(heightCm.replacingOccurrences(of: ",", with: ".")),
              let weight = latestWeightLog?.weight,
              height > 0 else {
            return nil
        }

        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }

    private var targetWeightValue: Double? {
        Double(targetWeight.replacingOccurrences(of: ",", with: "."))
    }

    private var bmiStatusText: String {
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

    private var targetProgressText: String {
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

    private var targetProgressColor: Color {
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

    private var targetProgressIcon: String {
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

    private var statusCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(isFasting ? "\(fastingGoalHours) 小时挑战" : "\(eatingGoalHours) 小时吃饭时间")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(isFasting ? "先忍住不吃" : "可以吃饭啦")
                    .font(.largeTitle.bold())
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isFasting ? Color.blue : Color.green,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(timeString(from: remaining))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(isFasting ? "再坚持一下" : "吃饭时间还剩")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            HStack {
                Label(startTimeText, systemImage: "play.circle")
                Spacer()
                Label(endTimeText, systemImage: "flag.checkered")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var actionCard: some View {
        VStack(spacing: 12) {
            Button {
                switchPhase()
            } label: {
                Text(primaryActionTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(primaryActionTint)

            Picker("计划模式", selection: planSelection) {
                ForEach(planOptions, id: \.fasting) { option in
                    Text("\(option.fasting)+\(option.eating)")
                        .tag(option.fasting)
                }
            }
            .pickerStyle(.segmented)

            Button {
                resetCurrentPhase()
            } label: {
                Label("重置当前阶段", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var fastingHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("计划记录")
                    .font(.title3.bold())
                Spacer()
                Text("\(fastingSessions.count) 次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sortedFastingSessions.isEmpty {
                Text("每次从“不吃东西”切到“准备吃饭”后，这里会记一条完成情况。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedFastingSessions.prefix(8)) { session in
                        FastingSessionRow(session: session)

                        if session.id != sortedFastingSessions.prefix(8).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var syncCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "icloud")
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("iCloud 同步")
                    .font(.headline)
                Text(syncStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("立即同步") {
                pushAllToICloud()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var weightCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("体重记录")
                    .font(.title3.bold())

                if let latestWeightLog {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(weightText(latestWeightLog.weight))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("kg")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Text("最近：\(chineseDateTime(latestWeightLog.date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("还没有体重记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                prepareWeightSheet()
                isShowingWeightSheet = true
            } label: {
                Label("添加", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var addWeightSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("今天体重")
                        .font(.title2.bold())

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        TextField("67.8", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        Text("kg")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    TextField("可选，例如：空腹、运动后", text: $noteInput, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                }

                Text("体重会保存到本地历史记录，并在 iCloud 可用时尝试同步。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    saveWeight()
                } label: {
                    Text("保存体重")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingWeightSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体重趋势")
                .font(.title3.bold())

            Picker("趋势粒度", selection: $trendGranularity) {
                ForEach(WeightTrendGranularity.allCases) { granularity in
                    Text(granularity.title)
                        .tag(granularity)
                }
            }
            .pickerStyle(.segmented)

            if trendPoints.count >= 2 {
                WeightTrendView(points: trendPoints, targetWeight: targetWeightValue)
                    .frame(height: 120)
            } else {
                ContentUnavailableView(
                    "还没有趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("至少保存 2 个\(trendGranularity.title)粒度记录后会显示趋势。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            }

            Button {
                seedMockWeightLogs()
            } label: {
                Label("生成 30 天示例体重", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var bmiCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("体重目标")
                    .font(.title3.bold())
                Spacer()
                Button {
                    isShowingBodySettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("目标体重")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let targetWeightValue {
                    Text("\(weightText(targetWeightValue)) kg")
                        .font(.title2.bold())
                } else {
                    Text("未设置")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: targetProgressIcon)
                    Text(targetProgressText)
                }
                .font(.caption.bold())
                .foregroundStyle(targetProgressColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(targetProgressColor.opacity(0.12))
                .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(bmiStatusText)
                            .font(.headline)

                        if let bmiValue {
                            Text("BMI \(String(format: "%.1f", bmiValue))")
                                .font(.subheadline.bold())
                                .foregroundStyle(bmiColor(for: bmiValue))
                        }
                    }
                    
                    Spacer()

                    if let latestWeightLog {
                        Text("当前 \(weightText(latestWeightLog.weight)) kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                BMIRangeBar(bmi: bmiValue)

                HStack {
                    Text("偏瘦 <18.5")
                    Spacer()
                    Text("正常 18.5-24")
                    Spacer()
                    Text("偏胖 24-28")
                    Spacer()
                    Text("肥胖 ≥28")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var bodySettingsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("体重目标")
                        .font(.title2.bold())

                    Text("身高和目标体重通常很少变化，设置好之后首页只展示目标体重和 BMI。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    MeasurementField(title: "身高", value: $heightCm, placeholder: "175", unit: "cm")
                    MeasurementField(title: "目标体重", value: $targetWeight, placeholder: "65", unit: "kg")
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("体重目标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingBodySettings = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isShowingBodySettings = false
                    }
                }
            }
        }
        .presentationDetents([.height(360)])
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("体重历史")
                    .font(.title3.bold())
                Spacer()
                Text("\(weightLogs.count) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sortedWeightLogs.isEmpty {
                Text("保存体重后，这里会显示历史记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(displayedWeightLogs) { log in
                        WeightLogRow(log: log, weightText: weightText(log.weight), dateText: chineseDateTime(log.date)) {
                            deleteWeightLog(log)
                        }

                        if log.id != displayedWeightLogs.last?.id {
                            Divider()
                        }
                    }
                }

                if displayedWeightLogs.count < sortedWeightLogs.count {
                    Button {
                        visibleWeightHistoryDays += 10
                    } label: {
                        Text("查看更多")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var anniversaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("纪念日")
                        .font(.title3.bold())
                    Text("生日、结婚纪念日或其他重要日子，阴历阳历都可以记录。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingAnniversarySheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(color: Color.orange.opacity(0.22), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }

            if anniversaryItems.isEmpty {
                ContentUnavailableView(
                    "还没有纪念日",
                    systemImage: "calendar.badge.plus",
                    description: Text("把生日、结婚纪念日或其他重要日子记下来。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedAnniversaryItems) { item in
                        AnniversaryRow(
                            item: item,
                            dateText: anniversaryDateText(for: item),
                            nextText: nextAnniversaryText(for: item)
                        ) {
                            deleteAnniversaryItem(item)
                        }

                        if item.id != sortedAnniversaryItems.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var anniversaryAddSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("生日、结婚纪念日或其他重要日子，阴历阳历都可以记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("纪念日类型", selection: $anniversaryKind) {
                    ForEach(AnniversaryKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.icon)
                            .tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                Picker("日期类型", selection: $anniversaryCalendarKind) {
                    ForEach(AnniversaryCalendarKind.allCases) { kind in
                        Text(kind.title)
                            .tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                ModernInputField(
                    placeholder: anniversaryKind == .other ? "例如：第一次旅行" : "例如：妈妈生日",
                    text: $anniversaryTitleInput,
                    icon: anniversaryKind.icon,
                    tint: .orange
                )

                DatePicker("日期", selection: $anniversaryDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "zh_CN"))

                Button {
                    addAnniversaryItem()
                } label: {
                    Label("添加纪念日", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(canAddAnniversary ? .white : Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canAddAnniversary ? Color.orange : Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canAddAnniversary)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingAnniversarySheet = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var todoTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODO")
                        .font(.title3.bold())
                    Text("想到什么先记下来，做完就打勾。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(activeTodoTasks.count) 件待做")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }

            AddEntryBar(
                placeholder: "例如：周末整理房间",
                text: $todoInput,
                icon: "checklist",
                tint: .blue,
                action: addTodoTask
            )

            if activeTodoTasks.isEmpty && completedTodoTasks.isEmpty {
                ContentUnavailableView(
                    "还没有待办",
                    systemImage: "checklist",
                    description: Text("把要做的事情写在这里，避免之后忘记。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !activeTodoTasks.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(activeTodoTasks) { task in
                            TodoTaskRow(task: task) {
                                toggleTodoTask(task)
                            } onDelete: {
                                deleteTodoTask(task)
                            }

                            if task.id != activeTodoTasks.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                if !completedTodoTasks.isEmpty {
                    Divider()

                    DisclosureGroup {
                        VStack(spacing: 10) {
                            ForEach(completedTodoTasks.prefix(8)) { task in
                                TodoTaskRow(task: task) {
                                    toggleTodoTask(task)
                                } onDelete: {
                                    deleteTodoTask(task)
                                }

                                if task.id != completedTodoTasks.prefix(8).last?.id {
                                    Divider()
                                }
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

    private var wishlistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("愿望清单")
                    .font(.title3.bold())
                Text("想去哪玩、吃什么、喝什么，先收集起来，后面一个个去实现。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("类型", selection: $wishlistCategory) {
                ForEach(WishlistCategory.allCases) { category in
                    Label(category.title, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)

            AddEntryBar(
                placeholder: "例如：去海边看日落",
                text: $wishlistInput,
                icon: wishlistCategory.icon,
                tint: .purple,
                action: addWishlistItem
            )

            if openWishlistItems.isEmpty && completedWishlistItems.isEmpty {
                ContentUnavailableView(
                    "还没有愿望",
                    systemImage: "sparkles",
                    description: Text("把想玩的、想吃的、想喝的都放进来。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if !openWishlistItems.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(openWishlistItems) { item in
                            WishlistRow(item: item) {
                                toggleWishlistItem(item)
                            } onDelete: {
                                deleteWishlistItem(item)
                            }

                            if item.id != openWishlistItems.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                if !completedWishlistItems.isEmpty {
                    Divider()

                    DisclosureGroup("已经实现 \(completedWishlistItems.count) 个") {
                        VStack(spacing: 10) {
                            ForEach(completedWishlistItems.prefix(8)) { item in
                                WishlistRow(item: item) {
                                    toggleWishlistItem(item)
                                } onDelete: {
                                    deleteWishlistItem(item)
                                }

                                if item.id != completedWishlistItems.prefix(8).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var financeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("总资产")
                        .font(.title3.bold())
                    Text("当前记录的所有资产合计")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(currencyText(totalFinanceAmount))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            }

            HStack(spacing: 14) {
                SummaryPill(title: "资产项", value: "\(financeAssets.count)", color: .blue)
                SummaryPill(title: "历史记录", value: "\(financeSnapshots.count)", color: .blue)
                SummaryPill(title: "月变化", value: financeMonthChangeText ?? "--", color: .orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var financeAddAssetSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("银行卡可以添加多张；股票、期权、支付宝、微信和其他资产也可以分别记录。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("资产类型", selection: $financeAssetKind) {
                    ForEach(FinanceAssetKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.icon)
                            .tag(kind)
                    }
                }
                .pickerStyle(.menu)

                ModernInputField(
                    placeholder: financeAssetKind == .custom ? "自定义类目名称" : "名称，例如：招商银行卡",
                    text: $financeAssetNameInput,
                    icon: financeAssetKind.icon,
                    tint: .blue
                )

                AddEntryBar(
                    placeholder: "金额，例如：12000",
                    text: $financeAssetAmountInput,
                    icon: "yensign.circle",
                    tint: .blue,
                    keyboardType: .decimalPad,
                    buttonTitle: "添加",
                    action: addFinanceAsset
                )

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingFinanceAssetSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var financeTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("资产趋势")
                        .font(.title3.bold())
                    Text("按每个月最后一次记录作为当月数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let financeMonthChangeText {
                    Text(financeMonthChangeText)
                        .font(.caption.bold())
                        .foregroundStyle(financeMonthChangeText.hasPrefix("-") ? .red : .blue)
                }
            }

            if monthlyFinanceTrendPoints.count >= 2 {
                FinanceTrendView(points: monthlyFinanceTrendPoints, amountText: currencyText)
                    .frame(height: 150)
            } else {
                ContentUnavailableView(
                    "还没有趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("至少跨 2 个月保存资产记录后，会显示月度变化。")
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var financeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("资产分布")
                    .font(.title3.bold())
                Text("按资产类型汇总，快速看出钱主要放在哪里。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if financeDistributionPoints.isEmpty {
                ContentUnavailableView(
                    "还没有分布",
                    systemImage: "chart.pie",
                    description: Text("添加资产后，会显示各类资产占比。")
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                FinanceDistributionView(
                    points: financeDistributionPoints,
                    amountText: currencyText
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var financeAssetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("资产明细")
                        .font(.title3.bold())
                    Text("\(financeAssets.count) 项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingFinanceAssetSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 30, height: 30)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if financeAssets.isEmpty {
                ContentUnavailableView(
                    "还没有资产",
                    systemImage: "yensign.circle",
                    description: Text("先添加银行卡、股票、期权、支付宝、微信或自定义资产。")
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedFinanceAssets) { asset in
                        FinanceAssetRow(
                            asset: asset,
                            amountText: currencyText(asset.amount),
                            updatedText: chineseDateTime(asset.updatedAt)
                        ) {
                            editingFinanceAsset = asset
                        } onDelete: {
                            deleteFinanceAsset(asset)
                        }

                        if asset.id != sortedFinanceAssets.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var stockResearchAddCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("新增股票")
                    .font(.title3.bold())
                Text("先用股票名称建档，后面可以持续补充你的理解。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            AddEntryBar(
                placeholder: "例如：腾讯控股、贵州茅台",
                text: $stockNameInput,
                icon: "chart.line.text.clipboard",
                tint: .blue,
                buttonTitle: "添加",
                action: addStockResearchItem
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var stockResearchListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("股票研究")
                        .font(.title3.bold())
                    Text("搜索股票名称，点开后编辑长文本研究笔记。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(stockResearchItems.count) 只")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SearchInputBar(placeholder: "搜索股票名称", text: $stockSearchText)

            if stockResearchItems.isEmpty {
                ContentUnavailableView(
                    "还没有股票研究",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("先添加一只股票，再记录你的理解。")
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else if filteredStockResearchItems.isEmpty {
                ContentUnavailableView(
                    "没有匹配结果",
                    systemImage: "magnifyingglass",
                    description: Text("换个股票名称试试看。")
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredStockResearchItems) { item in
                        StockResearchRow(
                            item: item,
                            updatedText: chineseDateTime(item.updatedAt),
                            onOpen: {
                            editingStockResearchItem = item
                        }, onDelete: {
                            deleteStockResearchItem(item)
                        })

                        if item.id != filteredStockResearchItems.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日减脂目标")
                .font(.title3.bold())

            TextEditor(text: $dailyGoal)
                .frame(minHeight: 90)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var startTimeText: String {
        "开始 \(relativeTimeText(for: fastingStartDate))"
    }

    private var endTimeText: String {
        "结束 \(relativeTimeText(for: phaseEndDate))"
    }

    private var primaryActionTitle: String {
        if isFasting {
            return hasReachedCurrentGoal ? "已达标，可以吃饭了" : "还没到点，先忍一忍"
        }

        return "吃完了，开始 \(fastingGoalHours) 小时计划"
    }

    private var primaryActionTint: Color {
        if isFasting {
            return hasReachedCurrentGoal ? .green : .orange
        }

        return .blue
    }

    private var planSelection: Binding<Int> {
        Binding(
            get: { fastingGoalHours },
            set: { newFastingHours in
                if let option = planOptions.first(where: { $0.fasting == newFastingHours }) {
                    fastingGoalHours = option.fasting
                    eatingGoalHours = option.eating
                }
            }
        )
    }

    private var weightPlaceholder: String {
        if let latestWeightLog {
            return "上次 \(weightText(latestWeightLog.weight)) kg"
        }

        return latestWeight.isEmpty ? "输入今天体重" : latestWeight
    }

    private var changeText: String? {
        guard let firstPoint = trendPoints.first,
              let lastPoint = trendPoints.last,
              firstPoint.id != lastPoint.id else {
            return nil
        }

        let change = lastPoint.weight - firstPoint.weight
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(weightText(change)) kg"
    }

    private func averagedTrendPoints(
        groupedBy keyForLog: (FastingLog) -> Date,
        labelFor: (Date) -> (String, String)
    ) -> [WeightTrendPoint] {
        let groupedLogs = Dictionary(grouping: weightLogs, by: keyForLog)

        let points = groupedLogs.map { date, logs in
            let averageWeight = logs.map(\.weight).reduce(0, +) / Double(logs.count)
            let labels = labelFor(date)

            return WeightTrendPoint(
                date: date,
                weight: averageWeight,
                topLabel: labels.0,
                bottomLabel: labels.1
            )
        }

        return Array(points.sorted { $0.date < $1.date }.suffix(30))
    }

    private func bmiColor(for bmi: Double) -> Color {
        switch bmi {
        case ..<18.5:
            return .blue
        case 18.5..<24:
            return .green
        case 24..<28:
            return .orange
        default:
            return .red
        }
    }

    private func chineseDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    private func chineseMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func chineseMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }

    private func chineseDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "d日"
        return formatter.string(from: date)
    }

    private func chineseYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年"
        return formatter.string(from: date)
    }

    private func chineseYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    private func anniversaryDateText(for item: AnniversaryItem) -> String {
        let calendar = item.calendarKind == .lunar ? Calendar(identifier: .chinese) : Calendar.current
        let components = calendar.dateComponents([.month, .day], from: item.date)
        let prefix = item.calendarKind.title

        return "\(prefix) \(components.month ?? 1)月\(components.day ?? 1)日"
    }

    private func nextAnniversaryText(for item: AnniversaryItem) -> String {
        guard let nextDate = nextAnniversaryDate(for: item) else {
            return "待计算"
        }

        if Calendar.current.isDateInToday(nextDate) {
            return "就是今天"
        }

        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: nextDate)
        ).day ?? 0

        return days == 0 ? "就是今天" : "还有 \(max(0, days)) 天"
    }

    private func nextAnniversaryDate(for item: AnniversaryItem) -> Date? {
        let sourceCalendar = item.calendarKind == .lunar ? Calendar(identifier: .chinese) : Calendar.current
        let targetComponents = sourceCalendar.dateComponents([.month, .day], from: item.date)
        let today = Date()

        for yearOffset in 0...3 {
            let candidateBaseDate = Calendar.current.date(byAdding: .year, value: yearOffset, to: today) ?? today
            let candidateYear = sourceCalendar.component(.year, from: candidateBaseDate)
            var components = DateComponents()
            components.calendar = sourceCalendar
            components.year = candidateYear
            components.month = targetComponents.month
            components.day = targetComponents.day

            if let candidateDate = sourceCalendar.date(from: components),
               Calendar.current.startOfDay(for: candidateDate) >= Calendar.current.startOfDay(for: today) {
                return candidateDate
            }
        }

        return nil
    }

    private func switchPhase() {
        if isFasting {
            recordCurrentFastingSession(endDate: Date())
        }

        isFasting.toggle()
        fastingStartTime = Date().timeIntervalSince1970
        persistSettingsToICloud()
    }

    private func resetCurrentPhase() {
        fastingStartTime = Date().timeIntervalSince1970
        persistSettingsToICloud()
    }

    private func prepareWeightSheet() {
        weightInput = ""
        noteInput = ""
    }

    private func saveWeight() {
        let trimmedWeight = weightInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWeight = trimmedWeight.replacingOccurrences(of: ",", with: ".")

        guard let weight = Double(normalizedWeight) else { return }

        let trimmedNote = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let log = FastingLog(date: Date(), weight: weight, note: trimmedNote)

        weightLogs.insert(log, at: 0)
        latestWeight = weightText(weight)
        persistWeightLogs()
        weightInput = ""
        noteInput = ""
        isShowingWeightSheet = false
    }

    private func seedMockWeightLogs() {
        let calendar = Calendar.current

        weightLogs = (0..<30).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()),
                  let date = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: day) else {
                return nil
            }

            let fluctuation = sin(Double(dayOffset) * 0.7) * 1.4 + sin(Double(dayOffset) * 0.23) * 0.8
            let weight = min(70, max(65, 67.5 + fluctuation))

            return FastingLog(date: date, weight: weight, note: "示例数据")
        }

        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? ""
        visibleWeightHistoryDays = 10
        persistWeightLogs()
    }

    private func loadMainTabPreferences() {
        guard !mainTabPreferencesData.isEmpty,
              let preferences = try? JSONDecoder().decode(MainTabPreferences.self, from: mainTabPreferencesData) else {
            return
        }

        applyMainTabPreferences(preferences)
    }

    private func persistMainTabPreferences() {
        let preferences = MainTabPreferences(order: mainTabOrder, visibleTabs: Array(visibleMainTabSet))

        if let encodedPreferences = try? JSONEncoder().encode(preferences) {
            mainTabPreferencesData = encodedPreferences
            cloudStore.set(encodedPreferences, forKey: mainTabPreferencesCloudKey)
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func applyMainTabPreferences(_ preferences: MainTabPreferences) {
        let validOrder = preferences.order.filter { MainAppTab.allCases.contains($0) }
        let missingTabs = MainAppTab.allCases.filter { !validOrder.contains($0) }
        mainTabOrder = validOrder + missingTabs

        let validVisibleTabs = Set(preferences.visibleTabs.filter { MainAppTab.allCases.contains($0) })
        visibleMainTabSet = validVisibleTabs.isEmpty ? Set(MainAppTab.allCases) : validVisibleTabs

        if let encodedPreferences = try? JSONEncoder().encode(
            MainTabPreferences(order: mainTabOrder, visibleTabs: Array(visibleMainTabSet))
        ) {
            mainTabPreferencesData = encodedPreferences
        }
    }

    private func mainTabVisibilityBinding(for tab: MainAppTab) -> Binding<Bool> {
        Binding(
            get: {
                visibleMainTabSet.contains(tab)
            },
            set: { isVisible in
                setMainTab(tab, isVisible: isVisible)
            }
        )
    }

    private func setMainTab(_ tab: MainAppTab, isVisible: Bool) {
        if isVisible {
            visibleMainTabSet.insert(tab)
        } else if !isOnlyVisibleMainTab(tab) {
            visibleMainTabSet.remove(tab)
        }

        persistMainTabPreferences()
    }

    private func isOnlyVisibleMainTab(_ tab: MainAppTab) -> Bool {
        visibleMainTabSet.contains(tab) && visibleMainTabSet.count == 1
    }

    private func moveMainTabs(from source: IndexSet, to destination: Int) {
        mainTabOrder.move(fromOffsets: source, toOffset: destination)
        persistMainTabPreferences()
    }

    private func toggleTabEditMode() {
        withAnimation {
            editMode?.wrappedValue = isEditingTabs ? .inactive : .active
        }
    }

    private func loadAppData() {
        loadMainTabPreferences()
        loadWeightLogs()
        loadFastingSessions()
        loadTodoTasks()
        loadWishlistItems()
        loadAnniversaryItems()
        loadFinanceAssets()
        loadFinanceSnapshots()
        loadStockResearchItems()
        pullFromICloud()
        pushAllToICloud()
    }

    private func loadWeightLogs() {
        guard !weightLogsData.isEmpty else {
            migrateLatestWeightIfNeeded()
            return
        }

        if let decodedLogs = try? JSONDecoder().decode([FastingLog].self, from: weightLogsData) {
            weightLogs = decodedLogs
            latestWeight = latestWeightLog.map { weightText($0.weight) } ?? latestWeight
        }
    }

    private func migrateLatestWeightIfNeeded() {
        let normalizedWeight = latestWeight.replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(normalizedWeight), weightLogs.isEmpty else { return }

        weightLogs = [FastingLog(date: Date(), weight: weight, note: "历史最近记录")]
        persistWeightLogs()
    }

    private func persistWeightLogs() {
        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            weightLogsData = encodedLogs
            cloudStore.set(encodedLogs, forKey: weightLogsCloudKey)
            persistSettingsToICloud()
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func deleteWeightLog(_ log: FastingLog) {
        weightLogs.removeAll { $0.id == log.id }
        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? ""
        persistWeightLogs()
    }

    private func loadTodoTasks() {
        guard !todoTasksData.isEmpty else { return }

        if let decodedTasks = try? JSONDecoder().decode([TodoTask].self, from: todoTasksData) {
            todoTasks = decodedTasks
        }
    }

    private func addTodoTask() {
        let trimmedTitle = todoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        todoTasks.insert(TodoTask(title: trimmedTitle, createdAt: Date()), at: 0)
        todoInput = ""
        persistTodoTasks()
    }

    private func toggleTodoTask(_ task: TodoTask) {
        guard let index = todoTasks.firstIndex(where: { $0.id == task.id }) else { return }

        todoTasks[index].completedAt = todoTasks[index].isCompleted ? nil : Date()
        persistTodoTasks()
    }

    private func deleteTodoTask(_ task: TodoTask) {
        todoTasks.removeAll { $0.id == task.id }
        persistTodoTasks()
    }

    private func persistTodoTasks() {
        if let encodedTasks = try? JSONEncoder().encode(todoTasks) {
            todoTasksData = encodedTasks
            cloudStore.set(encodedTasks, forKey: todoTasksCloudKey)
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func loadWishlistItems() {
        guard !wishlistItemsData.isEmpty else { return }

        if let decodedItems = try? JSONDecoder().decode([WishlistItem].self, from: wishlistItemsData) {
            wishlistItems = decodedItems
        }
    }

    private func addWishlistItem() {
        let trimmedTitle = wishlistInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        wishlistItems.insert(
            WishlistItem(title: trimmedTitle, category: wishlistCategory, createdAt: Date()),
            at: 0
        )
        wishlistInput = ""
        persistWishlistItems()
    }

    private func toggleWishlistItem(_ item: WishlistItem) {
        guard let index = wishlistItems.firstIndex(where: { $0.id == item.id }) else { return }

        wishlistItems[index].completedAt = wishlistItems[index].isCompleted ? nil : Date()
        persistWishlistItems()
    }

    private func deleteWishlistItem(_ item: WishlistItem) {
        wishlistItems.removeAll { $0.id == item.id }
        persistWishlistItems()
    }

    private func persistWishlistItems() {
        if let encodedItems = try? JSONEncoder().encode(wishlistItems) {
            wishlistItemsData = encodedItems
            cloudStore.set(encodedItems, forKey: wishlistItemsCloudKey)
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func loadAnniversaryItems() {
        guard !anniversaryItemsData.isEmpty else { return }

        if let decodedItems = try? JSONDecoder().decode([AnniversaryItem].self, from: anniversaryItemsData) {
            anniversaryItems = decodedItems
        }
    }

    private func addAnniversaryItem() {
        let trimmedTitle = anniversaryTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        anniversaryItems.insert(
            AnniversaryItem(
                title: trimmedTitle,
                kind: anniversaryKind,
                calendarKind: anniversaryCalendarKind,
                date: anniversaryDate,
                createdAt: Date()
            ),
            at: 0
        )
        anniversaryTitleInput = ""
        anniversaryDate = Date()
        persistAnniversaryItems()
        isShowingAnniversarySheet = false
    }

    private func deleteAnniversaryItem(_ item: AnniversaryItem) {
        anniversaryItems.removeAll { $0.id == item.id }
        persistAnniversaryItems()
    }

    private func persistAnniversaryItems() {
        if let encodedItems = try? JSONEncoder().encode(anniversaryItems) {
            anniversaryItemsData = encodedItems
            cloudStore.set(encodedItems, forKey: anniversaryItemsCloudKey)
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func loadFinanceAssets() {
        guard !financeAssetsData.isEmpty else { return }

        if let decodedAssets = try? JSONDecoder().decode([FinanceAsset].self, from: financeAssetsData) {
            financeAssets = decodedAssets
        }
    }

    private func loadFinanceSnapshots() {
        guard !financeSnapshotsData.isEmpty else { return }

        if let decodedSnapshots = try? JSONDecoder().decode([FinanceSnapshot].self, from: financeSnapshotsData) {
            financeSnapshots = decodedSnapshots
        }
    }

    private func addFinanceAsset() {
        let trimmedAmount = financeAssetAmountInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = trimmedAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalizedAmount) else { return }

        let trimmedName = financeAssetNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let assetName = trimmedName.isEmpty ? financeAssetKind.title : trimmedName

        financeAssets.insert(
            FinanceAsset(name: assetName, kind: financeAssetKind, amount: amount, updatedAt: Date()),
            at: 0
        )
        financeAssetNameInput = ""
        financeAssetAmountInput = ""
        persistFinanceAssets(recordSnapshot: true)
        isShowingFinanceAssetSheet = false
    }

    private func updateFinanceAsset(_ asset: FinanceAsset, amount: Double) {
        guard let index = financeAssets.firstIndex(where: { $0.id == asset.id }) else { return }

        financeAssets[index].amount = amount
        financeAssets[index].updatedAt = Date()
        persistFinanceAssets(recordSnapshot: true)
    }

    private func deleteFinanceAsset(_ asset: FinanceAsset) {
        financeAssets.removeAll { $0.id == asset.id }
        persistFinanceAssets(recordSnapshot: true)
    }

    private func persistFinanceAssets(recordSnapshot: Bool) {
        if recordSnapshot {
            recordFinanceSnapshot()
        }

        if let encodedAssets = try? JSONEncoder().encode(financeAssets) {
            financeAssetsData = encodedAssets
            cloudStore.set(encodedAssets, forKey: financeAssetsCloudKey)
        }

        persistFinanceSnapshots()
    }

    private func recordFinanceSnapshot() {
        let snapshot = FinanceSnapshot(date: Date(), totalAmount: totalFinanceAmount, assets: financeAssets)
        financeSnapshots.insert(snapshot, at: 0)
        financeSnapshots = Array(financeSnapshots.sorted { $0.date > $1.date }.prefix(240))
    }

    private func persistFinanceSnapshots() {
        if let encodedSnapshots = try? JSONEncoder().encode(financeSnapshots) {
            financeSnapshotsData = encodedSnapshots
            cloudStore.set(encodedSnapshots, forKey: financeSnapshotsCloudKey)
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func loadStockResearchItems() {
        guard !stockResearchItemsData.isEmpty else { return }

        if let decodedItems = try? JSONDecoder().decode([StockResearchItem].self, from: stockResearchItemsData) {
            stockResearchItems = decodedItems
        }
    }

    private func addStockResearchItem() {
        let trimmedName = stockNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if stockResearchItems.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) {
            stockSearchText = trimmedName
            stockNameInput = ""
            return
        }

        stockResearchItems.insert(
            StockResearchItem(name: trimmedName, thesis: "", createdAt: Date(), updatedAt: Date()),
            at: 0
        )
        stockNameInput = ""
        stockSearchText = ""
        persistStockResearchItems()
    }

    private func stockResearchThesisBinding(for item: StockResearchItem) -> Binding<String> {
        Binding(
            get: {
                stockResearchItems.first(where: { $0.id == item.id })?.thesis ?? item.thesis
            },
            set: { newThesis in
                updateStockResearchItem(item, thesis: newThesis)
            }
        )
    }

    private func updateStockResearchItem(_ item: StockResearchItem, thesis: String) {
        guard let index = stockResearchItems.firstIndex(where: { $0.id == item.id }) else { return }

        stockResearchItems[index].thesis = thesis
        stockResearchItems[index].updatedAt = Date()
        persistStockResearchItems()
    }

    private func deleteStockResearchItem(_ item: StockResearchItem) {
        stockResearchItems.removeAll { $0.id == item.id }
        persistStockResearchItems()
    }

    private func persistStockResearchItems() {
        if let encodedItems = try? JSONEncoder().encode(stockResearchItems) {
            stockResearchItemsData = encodedItems
            cloudStore.set(encodedItems, forKey: stockResearchItemsCloudKey)
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func loadFastingSessions() {
        guard !fastingSessionsData.isEmpty else { return }

        if let decodedSessions = try? JSONDecoder().decode([FastingSession].self, from: fastingSessionsData) {
            fastingSessions = decodedSessions
        }
    }

    private func recordCurrentFastingSession(endDate: Date) {
        let session = FastingSession(
            startDate: fastingStartDate,
            endDate: endDate,
            targetHours: fastingGoalHours,
            breakHours: eatingGoalHours,
            completed: endDate.timeIntervalSince(fastingStartDate) >= TimeInterval(fastingGoalHours * 60 * 60)
        )

        fastingSessions.insert(session, at: 0)
        persistFastingSessions()
    }

    private func persistFastingSessions() {
        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            fastingSessionsData = encodedSessions
            cloudStore.set(encodedSessions, forKey: fastingSessionsCloudKey)
            persistSettingsToICloud()
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func pullFromICloud() {
        cloudStore.synchronize()

        if let cloudLogsData = cloudStore.data(forKey: weightLogsCloudKey),
           let cloudLogs = try? JSONDecoder().decode([FastingLog].self, from: cloudLogsData) {
            mergeWeightLogs(cloudLogs)
        }

        if let cloudSessionsData = cloudStore.data(forKey: fastingSessionsCloudKey),
           let cloudSessions = try? JSONDecoder().decode([FastingSession].self, from: cloudSessionsData) {
            mergeFastingSessions(cloudSessions)
        }

        if let cloudTodoTasksData = cloudStore.data(forKey: todoTasksCloudKey),
           let cloudTodoTasks = try? JSONDecoder().decode([TodoTask].self, from: cloudTodoTasksData) {
            mergeTodoTasks(cloudTodoTasks)
        }

        if let cloudWishlistItemsData = cloudStore.data(forKey: wishlistItemsCloudKey),
           let cloudWishlistItems = try? JSONDecoder().decode([WishlistItem].self, from: cloudWishlistItemsData) {
            mergeWishlistItems(cloudWishlistItems)
        }

        if let cloudAnniversaryItemsData = cloudStore.data(forKey: anniversaryItemsCloudKey),
           let cloudAnniversaryItems = try? JSONDecoder().decode([AnniversaryItem].self, from: cloudAnniversaryItemsData) {
            mergeAnniversaryItems(cloudAnniversaryItems)
        }

        if let cloudFinanceAssetsData = cloudStore.data(forKey: financeAssetsCloudKey),
           let cloudFinanceAssets = try? JSONDecoder().decode([FinanceAsset].self, from: cloudFinanceAssetsData) {
            mergeFinanceAssets(cloudFinanceAssets)
        }

        if let cloudFinanceSnapshotsData = cloudStore.data(forKey: financeSnapshotsCloudKey),
           let cloudFinanceSnapshots = try? JSONDecoder().decode([FinanceSnapshot].self, from: cloudFinanceSnapshotsData) {
            mergeFinanceSnapshots(cloudFinanceSnapshots)
        }

        if let cloudStockResearchItemsData = cloudStore.data(forKey: stockResearchItemsCloudKey),
           let cloudStockResearchItems = try? JSONDecoder().decode([StockResearchItem].self, from: cloudStockResearchItemsData) {
            mergeStockResearchItems(cloudStockResearchItems)
        }

        if let cloudMainTabPreferencesData = cloudStore.data(forKey: mainTabPreferencesCloudKey),
           let cloudMainTabPreferences = try? JSONDecoder().decode(MainTabPreferences.self, from: cloudMainTabPreferencesData) {
            applyMainTabPreferences(cloudMainTabPreferences)
        }

        if cloudStore.object(forKey: fastingStartTimeCloudKey) != nil {
            fastingStartTime = cloudStore.double(forKey: fastingStartTimeCloudKey)
        }

        if cloudStore.object(forKey: isFastingCloudKey) != nil {
            isFasting = cloudStore.bool(forKey: isFastingCloudKey)
        }

        if cloudStore.object(forKey: fastingGoalHoursCloudKey) != nil {
            fastingGoalHours = Int(cloudStore.longLong(forKey: fastingGoalHoursCloudKey))
        }

        if cloudStore.object(forKey: eatingGoalHoursCloudKey) != nil {
            eatingGoalHours = Int(cloudStore.longLong(forKey: eatingGoalHoursCloudKey))
        }

        if cloudStore.object(forKey: latestWeightCloudKey) != nil {
            latestWeight = cloudStore.string(forKey: latestWeightCloudKey) ?? ""
        }

        if cloudStore.object(forKey: dailyGoalCloudKey) != nil {
            dailyGoal = cloudStore.string(forKey: dailyGoalCloudKey) ?? ""
        }

        if cloudStore.object(forKey: heightCmCloudKey) != nil {
            heightCm = cloudStore.string(forKey: heightCmCloudKey) ?? ""
        }

        if cloudStore.object(forKey: targetWeightCloudKey) != nil {
            targetWeight = cloudStore.string(forKey: targetWeightCloudKey) ?? ""
        }

        syncStatus = "已从 iCloud 检查更新"
    }

    private func pushAllToICloud() {
        persistSettingsToICloud()

        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            cloudStore.set(encodedLogs, forKey: weightLogsCloudKey)
        }

        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            cloudStore.set(encodedSessions, forKey: fastingSessionsCloudKey)
        }

        if let encodedTodoTasks = try? JSONEncoder().encode(todoTasks) {
            cloudStore.set(encodedTodoTasks, forKey: todoTasksCloudKey)
        }

        if let encodedWishlistItems = try? JSONEncoder().encode(wishlistItems) {
            cloudStore.set(encodedWishlistItems, forKey: wishlistItemsCloudKey)
        }

        if let encodedAnniversaryItems = try? JSONEncoder().encode(anniversaryItems) {
            cloudStore.set(encodedAnniversaryItems, forKey: anniversaryItemsCloudKey)
        }

        if let encodedFinanceAssets = try? JSONEncoder().encode(financeAssets) {
            cloudStore.set(encodedFinanceAssets, forKey: financeAssetsCloudKey)
        }

        if let encodedFinanceSnapshots = try? JSONEncoder().encode(financeSnapshots) {
            cloudStore.set(encodedFinanceSnapshots, forKey: financeSnapshotsCloudKey)
        }

        if let encodedStockResearchItems = try? JSONEncoder().encode(stockResearchItems) {
            cloudStore.set(encodedStockResearchItems, forKey: stockResearchItemsCloudKey)
        }

        if let encodedMainTabPreferences = try? JSONEncoder().encode(
            MainTabPreferences(order: mainTabOrder, visibleTabs: Array(visibleMainTabSet))
        ) {
            mainTabPreferencesData = encodedMainTabPreferences
            cloudStore.set(encodedMainTabPreferences, forKey: mainTabPreferencesCloudKey)
        }

        syncStatus = cloudStore.synchronize() ? "已请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
    }

    private func persistSettingsToICloud() {
        cloudStore.set(fastingStartTime, forKey: fastingStartTimeCloudKey)
        cloudStore.set(isFasting, forKey: isFastingCloudKey)
        cloudStore.set(Int64(fastingGoalHours), forKey: fastingGoalHoursCloudKey)
        cloudStore.set(Int64(eatingGoalHours), forKey: eatingGoalHoursCloudKey)
        cloudStore.set(latestWeight, forKey: latestWeightCloudKey)
        cloudStore.set(dailyGoal, forKey: dailyGoalCloudKey)
        cloudStore.set(heightCm, forKey: heightCmCloudKey)
        cloudStore.set(targetWeight, forKey: targetWeightCloudKey)
    }

    private func mergeWeightLogs(_ cloudLogs: [FastingLog]) {
        var mergedLogsByID = Dictionary(uniqueKeysWithValues: weightLogs.map { ($0.id, $0) })

        for log in cloudLogs {
            mergedLogsByID[log.id] = log
        }

        weightLogs = mergedLogsByID.values.sorted { $0.date > $1.date }

        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            weightLogsData = encodedLogs
        }

        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? latestWeight
    }

    private func mergeFastingSessions(_ cloudSessions: [FastingSession]) {
        var mergedSessionsByID = Dictionary(uniqueKeysWithValues: fastingSessions.map { ($0.id, $0) })

        for session in cloudSessions {
            mergedSessionsByID[session.id] = session
        }

        fastingSessions = mergedSessionsByID.values.sorted { $0.endDate > $1.endDate }

        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            fastingSessionsData = encodedSessions
        }
    }

    private func mergeTodoTasks(_ cloudTasks: [TodoTask]) {
        var mergedTasksByID = Dictionary(uniqueKeysWithValues: todoTasks.map { ($0.id, $0) })

        for task in cloudTasks {
            mergedTasksByID[task.id] = task
        }

        todoTasks = mergedTasksByID.values.sorted { $0.createdAt > $1.createdAt }

        if let encodedTasks = try? JSONEncoder().encode(todoTasks) {
            todoTasksData = encodedTasks
        }
    }

    private func mergeWishlistItems(_ cloudItems: [WishlistItem]) {
        var mergedItemsByID = Dictionary(uniqueKeysWithValues: wishlistItems.map { ($0.id, $0) })

        for item in cloudItems {
            mergedItemsByID[item.id] = item
        }

        wishlistItems = mergedItemsByID.values.sorted { $0.createdAt > $1.createdAt }

        if let encodedItems = try? JSONEncoder().encode(wishlistItems) {
            wishlistItemsData = encodedItems
        }
    }

    private func mergeAnniversaryItems(_ cloudItems: [AnniversaryItem]) {
        var mergedItemsByID = Dictionary(uniqueKeysWithValues: anniversaryItems.map { ($0.id, $0) })

        for item in cloudItems {
            mergedItemsByID[item.id] = item
        }

        anniversaryItems = mergedItemsByID.values.sorted {
            (nextAnniversaryDate(for: $0) ?? $0.date) < (nextAnniversaryDate(for: $1) ?? $1.date)
        }

        if let encodedItems = try? JSONEncoder().encode(anniversaryItems) {
            anniversaryItemsData = encodedItems
        }
    }

    private func mergeFinanceAssets(_ cloudAssets: [FinanceAsset]) {
        var mergedAssetsByID = Dictionary(uniqueKeysWithValues: financeAssets.map { ($0.id, $0) })

        for asset in cloudAssets {
            if let localAsset = mergedAssetsByID[asset.id] {
                mergedAssetsByID[asset.id] = asset.updatedAt >= localAsset.updatedAt ? asset : localAsset
            } else {
                mergedAssetsByID[asset.id] = asset
            }
        }

        financeAssets = mergedAssetsByID.values.sorted { $0.updatedAt > $1.updatedAt }

        if let encodedAssets = try? JSONEncoder().encode(financeAssets) {
            financeAssetsData = encodedAssets
        }
    }

    private func mergeFinanceSnapshots(_ cloudSnapshots: [FinanceSnapshot]) {
        var mergedSnapshotsByID = Dictionary(uniqueKeysWithValues: financeSnapshots.map { ($0.id, $0) })

        for snapshot in cloudSnapshots {
            mergedSnapshotsByID[snapshot.id] = snapshot
        }

        financeSnapshots = Array(mergedSnapshotsByID.values.sorted { $0.date > $1.date }.prefix(240))

        if let encodedSnapshots = try? JSONEncoder().encode(financeSnapshots) {
            financeSnapshotsData = encodedSnapshots
        }
    }

    private func mergeStockResearchItems(_ cloudItems: [StockResearchItem]) {
        var mergedItemsByID = Dictionary(uniqueKeysWithValues: stockResearchItems.map { ($0.id, $0) })

        for item in cloudItems {
            if let localItem = mergedItemsByID[item.id] {
                mergedItemsByID[item.id] = item.updatedAt >= localItem.updatedAt ? item : localItem
            } else {
                mergedItemsByID[item.id] = item
            }
        }

        stockResearchItems = mergedItemsByID.values.sorted { $0.updatedAt > $1.updatedAt }

        if let encodedItems = try? JSONEncoder().encode(stockResearchItems) {
            stockResearchItemsData = encodedItems
        }
    }

    private func relativeTimeText(for date: Date) -> String {
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

    private func durationText(from startDate: Date, to endDate: Date) -> String {
        let totalMinutes = max(0, Int(endDate.timeIntervalSince(startDate) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours) 小时"
        }

        return "\(hours) 小时 \(minutes) 分钟"
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func weightText(_ weight: Double) -> String {
        String(format: "%.1f", weight)
    }

    private func currencyText(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "¥%.0f", amount)
    }

    private func financeDistributionColor(at index: Int) -> Color {
        let colors: [Color] = [
            .blue,
            Color(red: 0.24, green: 0.51, blue: 0.96),
            Color(red: 0.42, green: 0.64, blue: 1.0),
            Color(red: 0.37, green: 0.72, blue: 0.95),
            Color(red: 0.55, green: 0.76, blue: 1.0),
            Color(red: 0.28, green: 0.42, blue: 0.82)
        ]
        return colors[index % colors.count]
    }
}

private struct TipRow: View {
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

private struct SummaryPill: View {
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

private struct AppSegmentedControl<Option: Identifiable & Hashable>: View {
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

private struct ModernInputField: View {
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

private struct AddEntryBar: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let tint: Color
    var keyboardType: UIKeyboardType = .default
    var buttonTitle: String?
    let action: () -> Void

    private var canSubmit: Bool {
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

private struct SearchInputBar: View {
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

private struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    private let actionWidth: CGFloat = 78

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                        offset = 0
                        onDelete()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.headline)
                        Text("删除")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .offset(x: offset)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 18)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }

                            if value.translation.width < 0 {
                                offset = max(-actionWidth, value.translation.width)
                            } else if offset < 0 {
                                offset = min(0, -actionWidth + value.translation.width)
                            }
                        }
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }

                            withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                                offset = value.translation.width < -actionWidth / 2 ? -actionWidth : 0
                            }
                        }
                )
        }
        .clipShape(Rectangle())
    }
}

private struct TodoTaskRow: View {
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

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct WishlistRow: View {
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

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct AnniversaryRow: View {
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

private struct StockResearchRow: View {
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

    private var stockResearchSummary: String {
        item.thesis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "还没有研究笔记 · 更新于 \(updatedText)"
            : "已有研究笔记 · 更新于 \(updatedText)"
    }
}

private struct StockResearchEditorSheet: View {
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

private struct FinanceAssetEditorSheet: View {
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

    private var canSaveAmount: Bool {
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

    private func saveAmount() {
        let normalizedAmount = amountInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Double(normalizedAmount) else { return }
        onSave(amount)
        dismiss()
    }
}

private struct FinanceAssetRow: View {
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

private struct FinanceTrendView: View {
    let points: [FinanceTrendPoint]
    let amountText: (Double) -> String

    private let chartHeight: CGFloat = 92
    private let pointWidth: CGFloat = 52
    private let pointSpacing: CGFloat = 10

    private var amounts: [Double] {
        points.map(\.amount)
    }

    private var minAmount: Double {
        amounts.min() ?? 0
    }

    private var maxAmount: Double {
        amounts.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let lastPoint = points.last {
                Text("\(lastPoint.topLabel)\(lastPoint.bottomLabel) \(amountText(lastPoint.amount))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: pointSpacing) {
                    ForEach(points) { point in
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                Color.clear
                                    .frame(height: chartHeight)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.gradient)
                                    .frame(height: barHeight(for: point.amount))

                                Text(compactAmountText(point.amount))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, barHeight(for: point.amount) + 6)
                            }

                            Text(point.bottomLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: pointWidth)
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private func barHeight(for amount: Double) -> CGFloat {
        guard maxAmount > minAmount else { return chartHeight * 0.7 }

        let ratio = (amount - minAmount) / (maxAmount - minAmount)
        return CGFloat(26 + ratio * Double(chartHeight - 26))
    }

    private func compactAmountText(_ amount: Double) -> String {
        if abs(amount) >= 10_000 {
            return String(format: "%.0f万", amount / 10_000)
        }

        return String(format: "%.0f", amount)
    }
}

private struct FinanceDistributionView: View {
    let points: [FinanceDistributionPoint]
    let amountText: (Double) -> String

    private var totalAmount: Double {
        points.map(\.amount).reduce(0, +)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    PieSliceShape(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index)
                    )
                    .fill(point.color)
                }

                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 72, height: 72)

                VStack(spacing: 2) {
                    Text("总计")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(amountText(totalAmount))
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(points.prefix(5)) { point in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(point.color)
                            .frame(width: 9, height: 9)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.title)
                                .font(.caption.bold())
                            Text("\(amountText(point.amount)) · \(percentageText(for: point.amount))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousAmount = points.prefix(index).map(\.amount).reduce(0, +)
        return .degrees(-90 + 360 * previousAmount / max(totalAmount, 1))
    }

    private func endAngle(for index: Int) -> Angle {
        let amount = points.prefix(index + 1).map(\.amount).reduce(0, +)
        return .degrees(-90 + 360 * amount / max(totalAmount, 1))
    }

    private func percentageText(for amount: Double) -> String {
        String(format: "%.0f%%", amount / max(totalAmount, 1) * 100)
    }
}

private struct PieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private struct WeightLogRow: View {
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

private struct FastingSessionRow: View {
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

    private func relativeTimeText(for date: Date) -> String {
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

    private func durationText(from startDate: Date, to endDate: Date) -> String {
        let totalMinutes = max(0, Int(endDate.timeIntervalSince(startDate) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours) 小时"
        }

        return "\(hours) 小时 \(minutes) 分钟"
    }
}

private struct MeasurementField: View {
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

private struct BMIRangeBar: View {
    let bmi: Double?

    private let minBMI = 15.0
    private let maxBMI = 32.0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Color.blue.opacity(0.7)
                    Color.green.opacity(0.8)
                    Color.orange.opacity(0.8)
                    Color.red.opacity(0.75)
                }
                .clipShape(Capsule())

                if let bmi {
                    Circle()
                        .fill(.primary)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                        }
                        .offset(x: markerOffset(for: bmi, width: proxy.size.width))
                }
            }
        }
        .frame(height: 14)
    }

    private func markerOffset(for bmi: Double, width: CGFloat) -> CGFloat {
        let clampedBMI = min(maxBMI, max(minBMI, bmi))
        let ratio = (clampedBMI - minBMI) / (maxBMI - minBMI)
        return max(0, min(width - 14, CGFloat(ratio) * width - 7))
    }
}

private struct VisibleTrendPointInfo: Equatable {
    let id: String
    let minX: CGFloat
    let maxX: CGFloat
    let topLabel: String
}

private struct VisibleTrendPointPreferenceKey: PreferenceKey {
    static var defaultValue: [VisibleTrendPointInfo] = []

    static func reduce(value: inout [VisibleTrendPointInfo], nextValue: () -> [VisibleTrendPointInfo]) {
        value.append(contentsOf: nextValue())
    }
}

private struct WeightTrendView: View {
    let points: [WeightTrendPoint]
    let targetWeight: Double?

    private let chartHeight: CGFloat = 78
    private let valueLabelHeight: CGFloat = 20
    private let pointWidth: CGFloat = 42
    private let pointSpacing: CGFloat = 8
    @State private var visibleLeadingLabel: String?

    private var weights: [Double] {
        if let targetWeight {
            return points.map(\.weight) + [targetWeight]
        }

        return points.map(\.weight)
    }

    private var minWeight: Double {
        weights.min() ?? 0
    }

    private var maxWeight: Double {
        weights.max() ?? 1
    }

    private var leadingTopLabel: String? {
        visibleLeadingLabel ?? points.first?.topLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let leadingTopLabel {
                Text(leadingTopLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                    .padding(.top, 18)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .bottom, spacing: pointSpacing) {
                        ForEach(points) { point in
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottom) {
                                    Color.clear
                                        .frame(height: chartHeight + valueLabelHeight)

                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue.gradient)
                                        .frame(height: barHeight(for: point.weight))

                                    Text(String(format: "%.1f", point.weight))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, barHeight(for: point.weight) + 6)
                                }

                                Text(point.bottomLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: pointWidth)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: VisibleTrendPointPreferenceKey.self,
                                        value: [
                                            VisibleTrendPointInfo(
                                                id: point.id,
                                                minX: proxy.frame(in: .named("weightTrendScroll")).minX,
                                                maxX: proxy.frame(in: .named("weightTrendScroll")).maxX,
                                                topLabel: point.topLabel
                                            )
                                        ]
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 8)

                    if let targetWeight {
                        targetLine(for: targetWeight)
                            .offset(y: targetLineOffset(for: targetWeight))
                    }
                }
            }
            .coordinateSpace(name: "weightTrendScroll")
            .onPreferenceChange(VisibleTrendPointPreferenceKey.self) { infos in
                let visibleInfos = infos
                    .filter { $0.maxX > 0 }
                    .sorted { $0.minX < $1.minX }

                visibleLeadingLabel = visibleInfos.first?.topLabel ?? points.first?.topLabel
            }
        }
    }

    private func barHeight(for weight: Double) -> CGFloat {
        guard maxWeight > minWeight else { return chartHeight * 0.7 }

        let ratio = (weight - minWeight) / (maxWeight - minWeight)
        return CGFloat(24 + ratio * Double(chartHeight - 24))
    }

    private func targetLineOffset(for targetWeight: Double) -> CGFloat {
        8 + valueLabelHeight + chartHeight - barHeight(for: targetWeight)
    }

    private func targetLine(for targetWeight: Double) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(.orange)
                .frame(width: max(0, CGFloat(points.count) * (pointWidth + pointSpacing) - pointSpacing), height: 1)

            Text("目标 \(String(format: "%.1f", targetWeight))")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
