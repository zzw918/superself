import SwiftUI

enum WeightSheetField: Hashable {
    case weight
    case note
}

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
    let wishlistCategoriesCloudKey = "wishlistCategories"
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
    @AppStorage("wishlistCategories") var wishlistCategoriesData = Data()
    @AppStorage("anniversaryItems") var anniversaryItemsData = Data()
    @AppStorage("financeAssets") var financeAssetsData = Data()
    @AppStorage("financeSnapshots") var financeSnapshotsData = Data()
    @AppStorage("stockResearchItems") var stockResearchItemsData = Data()
    @AppStorage("mainTabPreferences") var mainTabPreferencesData = Data()
    @AppStorage("dailyGoal") var dailyGoal = "多喝水，优先吃蛋白质，散步 20 分钟"
    @AppStorage("heightCm") var heightCm = ""
    @AppStorage("targetWeight") var targetWeight = ""
    @AppStorage("appearanceMode") var appearanceModeRaw = AppearanceMode.system.rawValue

    @State var now = Date()
    @State var weightInput = ""
    @State var noteInput = ""
    @State var weightLogs: [FastingLog] = []
    @State var fastingSessions: [FastingSession] = []
    @State var todoTasks: [TodoTask] = []
    @State var wishlistItems: [WishlistItem] = []
    @State var wishlistCategories: [WishlistCategory] = WishlistCategory.defaultCategories
    @State var anniversaryItems: [AnniversaryItem] = []
    @State var todoInput = ""
    @State var wishlistInput = ""
    @State var wishlistCategoryID = WishlistCategory.defaultCategories[0].id
    @State var wishlistFilter: WishlistFilter = .all
    @State var isShowingWishlistCategorySheet = false
    @State var anniversaryTitleInput = ""
    @State var anniversaryCalendarKind: AnniversaryCalendarKind = .solar
    @State var anniversaryDate = Date()
    @State var anniversaryShowsElapsedDays = false
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
    @State var editingTodoTask: TodoTask?
    @State var editingWishlistItem: WishlistItem?
    @State var editingAnniversaryItem: AnniversaryItem?
    @State var mainTabOrder = MainAppTab.allCases
    @State var visibleMainTabSet = Set(MainAppTab.allCases)
    @State var syncStatus = "iCloud 同步准备中"
    @State var isShowingWeightSheet = false
    @State var isShowingBodySettings = false
    @State var isShowingFinanceAssetSheet = false
    @State var isShowingAnniversarySheet = false
    @State var isShowingStartTimeSheet = false
    @State var startTimeDraft = Date()
    @State var isShowingPlanSheet = false
    @State var isShowingStockAddAlert = false
    @State var trendGranularity: WeightTrendGranularity = .day
    @State var visibleWeightHistoryDays = 10
    @State var didShowWeightSaveFeedback = false
    @FocusState var focusedWeightSheetField: WeightSheetField?

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var appearanceMode: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

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
        .preferredColorScheme(appearanceMode.wrappedValue.colorScheme)
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
        .sheet(isPresented: $isShowingStartTimeSheet) {
            startTimeSheet
        }
        .sheet(isPresented: $isShowingPlanSheet) {
            planSheet
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
                updatedText: chineseDateTime(item.updatedAt),
                onRename: { newName in
                    renameStockResearchItem(item, name: newName)
                }
            )
        }
        .sheet(isPresented: $isShowingStockAddAlert) {
            StockResearchAddSheet(name: $stockNameInput) {
                addStockResearchItem()
            } onCancel: {
                stockNameInput = ""
                isShowingStockAddAlert = false
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingTodoTask) { task in
            TodoEditorSheet(task: task) { newTitle in
                updateTodoTask(task, title: newTitle)
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingWishlistItem) { item in
            WishlistEditorSheet(item: item, categories: wishlistCategories) { newTitle, newCategoryID in
                updateWishlistItem(item, title: newTitle, categoryID: newCategoryID)
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingWishlistCategorySheet) {
            WishlistCategoryManagerSheet(
                categories: wishlistCategories,
                onAdd: { title, icon in
                    addWishlistCategory(title: title, icon: icon)
                },
                onUpdate: { category, title, icon in
                    updateWishlistCategory(category, title: title, icon: icon)
                },
                onDelete: { category in
                    deleteWishlistCategory(category)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingAnniversaryItem) { item in
            AnniversaryEditorSheet(
                item: item,
                solarPreview: { date, kind in
                    anniversarySolarPreviewText(date: date, calendarKind: kind)
                },
                onSave: { title, kind, date, showsElapsed in
                    updateAnniversaryItem(
                        item,
                        title: title,
                        calendarKind: kind,
                        date: date,
                        showsElapsedDays: showsElapsed
                    )
                }
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
