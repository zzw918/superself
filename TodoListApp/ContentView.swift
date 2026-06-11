import SwiftUI

struct ContentView: View {
    @Environment(\.editMode) var editMode

    let cloudStore = NSUbiquitousKeyValueStore.default
    let fastingStartTimeCloudKey = "fastingStartTime"
    let isFastingCloudKey = "isFasting"
    let latestWeightCloudKey = "latestWeight"
    let weightLogsCloudKey = "weightLogs"
    let fastingSessionsCloudKey = "fastingSessions"
    let fastingGoalHoursCloudKey = "fastingGoalHours"
    let eatingGoalHoursCloudKey = "eatingGoalHours"
    let dailyGoalCloudKey = "dailyGoal"
    let todoTasksCloudKey = "todoTasks"
    let wishlistItemsCloudKey = "wishlistItems"
    let anniversaryItemsCloudKey = "anniversaryItems"
    let financeAssetsCloudKey = "financeAssets"
    let financeSnapshotsCloudKey = "financeSnapshots"
    let stockResearchItemsCloudKey = "stockResearchItems"
    let mainTabPreferencesCloudKey = "mainTabPreferences"
    let heightCmCloudKey = "heightCm"
    let targetWeightCloudKey = "targetWeight"
    let planOptions = [(fasting: 16, eating: 8), (fasting: 18, eating: 6), (fasting: 20, eating: 4)]
    let isoCalendar = Calendar(identifier: .iso8601)

    @AppStorage("fastingStartTime") var fastingStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("isFasting") var isFasting = true
    @AppStorage("fastingGoalHours") var fastingGoalHours = 16
    @AppStorage("eatingGoalHours") var eatingGoalHours = 8
    @AppStorage("latestWeight") var latestWeight = ""
    @AppStorage("weightLogs") var weightLogsData = Data()
    @AppStorage("fastingSessions") var fastingSessionsData = Data()
    @AppStorage("todoTasks") var todoTasksData = Data()
    @AppStorage("wishlistItems") var wishlistItemsData = Data()
    @AppStorage("anniversaryItems") var anniversaryItemsData = Data()
    @AppStorage("financeAssets") var financeAssetsData = Data()
    @AppStorage("financeSnapshots") var financeSnapshotsData = Data()
    @AppStorage("stockResearchItems") var stockResearchItemsData = Data()
    @AppStorage("mainTabPreferences") var mainTabPreferencesData = Data()
    @AppStorage("dailyGoal") var dailyGoal = "多喝水，优先吃蛋白质，散步 20 分钟"
    @AppStorage("heightCm") var heightCm = ""
    @AppStorage("targetWeight") var targetWeight = ""

    @State var now = Date()
    @State var weightInput = ""
    @State var noteInput = ""
    @State var weightLogs: [FastingLog] = []
    @State var fastingSessions: [FastingSession] = []
    @State var todoTasks: [TodoTask] = []
    @State var wishlistItems: [WishlistItem] = []
    @State var anniversaryItems: [AnniversaryItem] = []
    @State var todoInput = ""
    @State var wishlistInput = ""
    @State var wishlistCategory: WishlistCategory = .travel
    @State var anniversaryTitleInput = ""
    @State var anniversaryKind: AnniversaryKind = .birthday
    @State var anniversaryCalendarKind: AnniversaryCalendarKind = .solar
    @State var anniversaryDate = Date()
    @State var financeAssets: [FinanceAsset] = []
    @State var financeSnapshots: [FinanceSnapshot] = []
    @State var financeAssetNameInput = ""
    @State var financeAssetAmountInput = ""
    @State var financeAssetKind: FinanceAssetKind = .bankCard
    @State var healthSection: HealthSection = .fasting
    @State var memoSection: MemoSection = .todo
    @State var financeSection: FinanceSection = .assetRecord
    @State var stockResearchItems: [StockResearchItem] = []
    @State var stockNameInput = ""
    @State var stockSearchText = ""
    @State var editingFinanceAsset: FinanceAsset?
    @State var editingStockResearchItem: StockResearchItem?
    @State var mainTabOrder = MainAppTab.allCases
    @State var visibleMainTabSet = Set(MainAppTab.allCases)
    @State var syncStatus = "iCloud 同步准备中"
    @State var isShowingWeightSheet = false
    @State var isShowingBodySettings = false
    @State var isShowingFinanceAssetSheet = false
    @State var isShowingAnniversarySheet = false
    @State var trendGranularity: WeightTrendGranularity = .day
    @State var visibleWeightHistoryDays = 10

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
    func mainTabContent(for tab: MainAppTab) -> some View {
        switch tab {
        case .health:
            healthPage
        case .todo:
            memoPage
        case .finance:
            financePage
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
