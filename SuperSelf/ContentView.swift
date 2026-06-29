import SwiftUI

enum WeightSheetField: Hashable {
    case weight
    case note
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase

    let cloudStore = NSUbiquitousKeyValueStore.default
    let fastingStartTimeCloudKey = "fastingStartTime"
    let isFastingCloudKey = "isFasting"
    let latestWeightCloudKey = "latestWeight"
    let weightLogsCloudKey = "weightLogs"
    let fastingSessionsCloudKey = "fastingSessions"
    let exerciseGoalsCloudKey = "exerciseGoals"
    let exerciseRecordsCloudKey = "exerciseRecords"
    let fastingGoalHoursCloudKey = "fastingGoalHours"
    let eatingGoalHoursCloudKey = "eatingGoalHours"
    let dailyGoalCloudKey = "dailyGoal"
    let moodEntriesCloudKey = "moodEntries"
    let todoTasksCloudKey = "todoTasks"
    let wishlistItemsCloudKey = "wishlistItems"
    let wishlistCategoriesCloudKey = "wishlistCategories"
    let anniversaryItemsCloudKey = "anniversaryItems"
    let financeAssetsCloudKey = "financeAssets"
    let financeSnapshotsCloudKey = "financeSnapshots"
    let expenseRecordsCloudKey = "expenseRecords"
    let expenseCategoriesCloudKey = "expenseCategories"
    let stockResearchItemsCloudKey = "stockResearchItems"
    let calculatorHistoryCloudKey = "calculatorHistory"
    let mainTabPreferencesCloudKey = "mainTabPreferences"
    let healthSectionPreferencesCloudKey = "healthSectionPreferences"
    let memoSectionPreferencesCloudKey = "memoSectionPreferences"
    let financeSectionPreferencesCloudKey = "financeSectionPreferences"
    let heightCmCloudKey = "heightCm"
    let targetWeightCloudKey = "targetWeight"
    let roundStartWeightCloudKey = "roundStartWeight"
    let planOptions = [(fasting: 14, eating: 10), (fasting: 16, eating: 8), (fasting: 18, eating: 6), (fasting: 20, eating: 4)]
    let isoCalendar = Calendar(identifier: .iso8601)

    @AppStorage("fastingStartTime") var fastingStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("isFasting") var isFasting = true
    @AppStorage("fastingGoalHours") var fastingGoalHours = 16
    @AppStorage("eatingGoalHours") var eatingGoalHours = 8
    @AppStorage("latestWeight") var latestWeight = ""
    @AppStorage("weightLogs") var weightLogsData = Data()
    @AppStorage("fastingSessions") var fastingSessionsData = Data()
    @AppStorage("exerciseGoals") var exerciseGoalsData = Data()
    @AppStorage("exerciseRecords") var exerciseRecordsData = Data()
    @AppStorage("moodEntries") var moodEntriesData = Data()
    @AppStorage("todoTasks") var todoTasksData = Data()
    @AppStorage("memoNotes") var memoNotesData = Data()
    @AppStorage("wishlistItems") var wishlistItemsData = Data()
    @AppStorage("wishlistCategories") var wishlistCategoriesData = Data()
    @AppStorage("anniversaryItems") var anniversaryItemsData = Data()
    @AppStorage("financeAssets") var financeAssetsData = Data()
    @AppStorage("financeSnapshots") var financeSnapshotsData = Data()
    @AppStorage("expenseRecords") var expenseRecordsData = Data()
    @AppStorage("expenseCategories") var expenseCategoriesData = Data()
    @AppStorage("stockResearchItems") var stockResearchItemsData = Data()
    @AppStorage("calculatorHistory") var calculatorHistoryData = Data()
    @AppStorage("mainTabPreferences") var mainTabPreferencesData = Data()
    @AppStorage("healthSectionPreferences") var healthSectionPreferencesData = Data()
    @AppStorage("memoSectionPreferences") var memoSectionPreferencesData = Data()
    @AppStorage("financeSectionPreferences") var financeSectionPreferencesData = Data()
    @AppStorage("dailyGoal") var dailyGoal = "多喝水，优先吃蛋白质，散步 20 分钟"
    @AppStorage("heightCm") var heightCm = ""
    @AppStorage("targetWeight") var targetWeight = ""
    @AppStorage("roundStartWeight") var roundStartWeight = ""
    @AppStorage("appearanceMode") var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage("companionAnimal") var companionAnimalRaw = CompanionAnimal.default.rawValue
    @AppStorage("isCompanionAnimalEnabled") var isCompanionAnimalEnabled = true
    @AppStorage("notifyEatingSoon") var notifyEatingSoon = false
    @AppStorage("notifyEatingStart") var notifyEatingStart = false
    @AppStorage("notifyFastingSoon") var notifyFastingSoon = false
    @AppStorage("notifyFastingStart") var notifyFastingStart = false
    @AppStorage("financePrivacyPassword") var financePrivacyPassword = "111111"
    @AppStorage("isFinanceAssetDefaultHidden") var isFinanceAssetDefaultHidden = true

    @StateObject var weatherStore = WeatherStore()
    @ObservedObject var notificationRouter = NotificationRouter.shared
    @State var selectedTabID = MainAppTab.health.rawValue
    @State var profileNavigationResetID = UUID()
    @State var now = Date()
    @State var weightInput = ""
    @State var noteInput = ""
    @State var weightLogs: [FastingLog] = []
    @State var fastingSessions: [FastingSession] = []
    @State var exerciseGoals: [ExerciseGoal] = ExerciseGoal.defaultGoals
    @State var exerciseRecords: [ExerciseRecord] = []
    @State var exerciseCalendarMonth = Date()
    @State var exerciseCalendarSelectedDate: Date? = nil
    @State var isShowingExerciseGoalSheet = false
    @State var exerciseInputGoal: ExerciseGoal?
    @State var exerciseInputDate: Date?
    @State var exerciseInputValue: String = ""
    @State var moodEntries: [MoodEntry] = []
    @State var todoTasks: [TodoTask] = []
    @State var memoNotes: [MemoNote] = []
    @State var wishlistItems: [WishlistItem] = []
    @State var wishlistCategories: [WishlistCategory] = WishlistCategory.defaultCategories
    @State var anniversaryItems: [AnniversaryItem] = []
    @State var memoCalendarMonth = Date()
    @State var memoCalendarSelectedDate = Calendar.current.startOfDay(for: Date())
    @State var memoCalendarSwipeOffset: CGFloat = 0
    @State var isMemoCalendarSwipeAnimating = false
    @State var memoCalendarPageWidth: CGFloat = 0
    @State var memoCalendarPages: [MemoCalendarMonthPage] = []
    @State var todoInput = ""
    @State var todoPriorityInput: TodoPriority = .importantNotUrgent
    @State var todoFilter: TodoPriority? = nil
    @State var todoAddInitialPriority: TodoPriority?
    @State var isShowingTodoAddSheet = false
    @State var noteTagFilter: String?
    @State var noteSearchText = ""
    @State var isNoteSearchExpanded = false
    @State var moodSearchText = ""
    @State var isMoodSearchExpanded = false
    @State var isShowingNoteAddSheet = false
    @State var wishlistInput = ""
    @State var wishlistNoteInput = ""
    @State var wishlistCategoryID = WishlistCategory.defaultCategories[0].id
    @State var wishlistFilter: WishlistFilter = .all
    @State var isShowingWishlistAddSheet = false
    @State var isShowingWishlistCategorySheet = false
    @State var isShowingWishlistCategoryPicker = false
    @State var anniversaryTitleInput = ""
    @State var anniversaryCalendarKind: AnniversaryCalendarKind = .solar
    @State var anniversaryDate = Date()
    @State var anniversaryShowsElapsedDays = false
    @State var financeAssets: [FinanceAsset] = []
    @State var financeSnapshots: [FinanceSnapshot] = []
    @State var expenseRecords: [ExpenseRecord] = []
    @State var expenseCategories: [ExpenseCategory] = ExpenseCategory.defaultCategories
    @State var financeAssetNameInput = ""
    @State var financeAssetAmountInput = ""
    @State var financeAssetNoteInput = ""
    @State var financeAssetKind: FinanceAssetKind = .bankCard
    @State var isFinanceAssetPrivacyUnlocked = false
    @State var isFinanceAssetTemporarilyHidden = false
    @State var isShowingFinancePrivacyUnlockSheet = false
    @State var isFinancePrivacyUnlockingDefaultHidden = false
    @State var pendingFinanceAssetDefaultHidden: Bool?
    @State var financePrivacyUnlockInput = ""
    @State var financePrivacyUnlockError: String?
    @State var financeSecurityCurrentPasswordInput = ""
    @State var financeSecurityPasswordInput = ""
    @State var financeSecurityPasswordConfirmInput = ""
    @State var financeSecurityPasswordMessage: String?
    @State var isShowingFinancePasswordChangeSheet = false
    @State var healthSection: HealthSection = .weight
    @State var memoSection: MemoSection = .todo
    @State var financeSection: FinanceSection = .assetRecord
    @State var healthSectionPrefs = SectionPreferences<HealthSection>()
    @State var memoSectionPrefs = SectionPreferences<MemoSection>()
    @State var financeSectionPrefs = SectionPreferences<FinanceSection>()
    @State var expenseTrendGranularity: WeightTrendGranularity = .day
    @State var financeDistributionGrouping: FinanceDistributionGrouping = .kind
    @State var stockResearchItems: [StockResearchItem] = []
    @State var stockNameInput = ""
    @State var stockSearchText = ""
    @State var isShowingStockFilterPanel = false
    @State var stockCertaintyFilter: StockRating?
    @State var stockGrowthFilter: StockRating?
    @State var stockAttentionFilter: StockRating?
    @State var editingFinanceAsset: FinanceAsset?
    @State var editingExpenseRecord: ExpenseRecord?
    @State var editingStockResearchItem: StockResearchItem?
    @State var editingMoodEntry: MoodEntry?
    @State var editingTodoTask: TodoTask?
    @State var editingMemoNote: MemoNote?
    @State var editingWishlistItem: WishlistItem?
    @State var editingAnniversaryItem: AnniversaryItem?
    @State var editingWeightLog: FastingLog?
    @State var shouldFocusWeightLogNote = false
    @State var isShowingSectionManagement = false
    @State var mainTabOrder = MainAppTab.allCases
    @State var visibleMainTabSet = Set(MainAppTab.allCases)
    @State var tabEditOriginalOrder = MainAppTab.allCases
    @State var tabEditOriginalVisibleSet = Set(MainAppTab.allCases)
    @State var tabEditMode: EditMode = .inactive
    @State var didApplyColdStartSelection = false
    @State var syncStatus = "iCloud 同步准备中"
    @State var isSyncing = false
    @State var syncToastMessage: String?
    @AppStorage("lastICloudSyncAt") var lastICloudSyncAt: Double = 0
    @State var isShowingWeightSheet = false
    @State var isShowingBodySettings = false
    @State var isShowingFinanceAssetSheet = false
    @State var isShowingExpenseRecordSheet = false
    @State var isShowingAnniversarySheet = false
    @State var isShowingStartTimeSheet = false
    @State var startTimeDraft = Date()
    @State var isShowingPlanSheet = false
    @State var isShowingStockAddAlert = false
    @State var isShowingMoodEntryAddSheet = false
    @State var calculatorDisplay = "0"
    @State var calculatorStoredValue: Double?
    @State var calculatorPendingOperation: CalculatorOperation?
    @State var calculatorIsEnteringNewNumber = false
    @State var calculatorStatusText = ""
    @State var calculatorHistory: [CalculatorHistoryItem] = []
    @State var calculatorFlashedKey: String?
    @State var calculatorFlashToken = 0
    @State var trendGranularity: WeightTrendGranularity = .day
    @State var visibleWeightHistoryDays = 10
    @State var didShowWeightSaveFeedback = false
    @State var isShowingEndFastingConfirm = false
    @State var isShowingBMIInfo = false
    @FocusState var focusedWeightSheetField: WeightSheetField?
    @FocusState var isAnniversaryTitleFocused: Bool
    @FocusState var isNoteSearchFocused: Bool
    @FocusState var isMoodSearchFocused: Bool

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var appearanceMode: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    var companionAnimal: Binding<CompanionAnimal> {
        Binding(
            get: { CompanionAnimal(rawValue: companionAnimalRaw) ?? .default },
            set: { companionAnimalRaw = $0.rawValue }
        )
    }

    var companionAnimalEnabled: Binding<Bool> {
        Binding(
            get: { isCompanionAnimalEnabled },
            set: { isCompanionAnimalEnabled = $0 }
        )
    }

    var body: some View {
        TabView(selection: $selectedTabID) {
            ForEach(visibleRootTabs) { tab in
                rootTabContent(for: tab)
                    .tag(tab.rawValue)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
            }
        }
        .preferredColorScheme(appearanceMode.wrappedValue.colorScheme)
        .onReceive(notificationRouter.$route.compactMap { $0 }) { route in
            handleAppRoute(route)
        }
        .onReceive(timer) { currentTime in
            now = currentTime
        }
        .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
            pullFromICloud()
        }
        .onAppear(perform: loadAppData)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                pullFromICloud()
            case .background, .inactive:
                if isFinanceAssetDefaultHidden {
                    isFinanceAssetPrivacyUnlocked = false
                    isFinanceAssetTemporarilyHidden = false
                }
                pushAllToICloud()
            @unknown default:
                break
            }
        }
        .onChange(of: dailyGoal) {
            persistSettingsToICloud()
        }
        .onChange(of: fastingGoalHours) {
            persistSettingsToICloud()
            rescheduleFastingNotifications()
        }
        .onChange(of: eatingGoalHours) {
            persistSettingsToICloud()
            rescheduleFastingNotifications()
        }
        .onChange(of: heightCm) {
            persistSettingsToICloud()
        }
        .onChange(of: targetWeight) {
            persistSettingsToICloud()
        }
        .onChange(of: roundStartWeight) {
            persistSettingsToICloud()
        }
        .sheet(isPresented: $isShowingWeightSheet) {
            addWeightSheet
        }
        .sheet(isPresented: $isShowingSectionManagement) {
            sectionManagementSheet
        }
        .sheet(isPresented: $isShowingExerciseGoalSheet) {
            ExerciseGoalManagerSheet(
                initialGoals: activeExerciseGoals,
                onSave: { actions in
                    for action in actions {
                        switch action {
                        case .add(let title, let targetCount, let unit):
                            addExerciseGoal(title: title, targetCount: targetCount, unit: unit)
                        case .update(let goal, let title, let targetCount, let unit):
                            updateExerciseGoal(goal, title: title, targetCount: targetCount, unit: unit)
                        case .deactivate(let goal):
                            deactivateExerciseGoal(goal)
                        }
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingMoodEntryAddSheet) {
            MoodEntryEditorSheet(entry: nil) { content in
                addMoodEntry(content: content)
            }
            .presentationDetents([.height(620)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingMoodEntry) { entry in
            MoodEntryEditorSheet(entry: entry) { content in
                updateMoodEntry(entry, content: content)
            }
            .presentationDetents([.height(620)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingWeightLog) { log in
            WeightLogEditorSheet(
                log: log,
                shouldFocusNote: shouldFocusWeightLogNote
            ) { newWeight, newNote in
                updateWeightLog(log, weight: newWeight, note: newNote)
            }
            .onDisappear {
                shouldFocusWeightLogNote = false
            }
        }
        .sheet(isPresented: $isShowingBodySettings) {
            bodySettingsSheet
        }
        .sheet(isPresented: $isShowingBMIInfo) {
            bmiInfoSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingFinanceAssetSheet) {
            financeAddAssetSheet
        }
        .sheet(isPresented: $isShowingFinancePrivacyUnlockSheet) {
            FinancePrivacyUnlockSheet(
                title: financePrivacyUnlockTitle,
                subtitle: financePrivacyUnlockSubtitle,
                actionTitle: financePrivacyUnlockActionTitle,
                biometricActionTitle: canUseFinanceBiometrics ? "使用 \(financeBiometricTypeText)" : nil,
                passwordInput: $financePrivacyUnlockInput,
                errorText: financePrivacyUnlockError,
                onCancel: {
                    resetFinancePrivacyUnlockInput()
                    isFinancePrivacyUnlockingDefaultHidden = false
                    pendingFinanceAssetDefaultHidden = nil
                    isShowingFinancePrivacyUnlockSheet = false
                },
                onBiometricUnlock: {
                    authenticateFinanceBiometrics(reason: financePrivacyUnlockSubtitle) {
                        if isFinancePrivacyUnlockingDefaultHidden, let pendingFinanceAssetDefaultHidden {
                            applyFinanceAssetDefaultHidden(pendingFinanceAssetDefaultHidden)
                            isFinancePrivacyUnlockingDefaultHidden = false
                            self.pendingFinanceAssetDefaultHidden = nil
                        } else {
                            isFinanceAssetPrivacyUnlocked = true
                            isFinanceAssetTemporarilyHidden = false
                        }
                        resetFinancePrivacyUnlockInput()
                        isShowingFinancePrivacyUnlockSheet = false
                    } onFailure: {
                        financePrivacyUnlockError = "\(financeBiometricTypeText) 验证未通过，请输入密码"
                    }
                },
                onUnlock: {
                    submitFinancePrivacyUnlock()
                }
            )
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingFinancePasswordChangeSheet) {
            FinancePasswordChangeSheet(
                currentPassword: financePrivacyPasswordValue,
                biometricActionTitle: canUseFinanceBiometrics ? "使用 \(financeBiometricTypeText) 验证" : nil,
                onCancel: {
                    isShowingFinancePasswordChangeSheet = false
                },
                onBiometricVerify: { onSuccess, onFailure in
                    authenticateFinanceBiometrics(reason: "验证后修改或重置资产查看密码", onSuccess: onSuccess, onFailure: onFailure)
                },
                onSave: { newPassword in
                    saveFinancePrivacyPassword(newPassword)
                    isShowingFinancePasswordChangeSheet = false
                }
            )
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.visible)
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
            FinanceAssetEditorSheet(asset: asset) { newName, newKind, newAmount, newNote in
                updateFinanceAsset(asset, name: newName, kind: newKind, amount: newAmount, note: newNote)
            }
        }
        .sheet(isPresented: $isShowingExpenseRecordSheet) {
            expenseRecordEditorSheet()
        }
        .sheet(item: $editingExpenseRecord) { record in
            expenseRecordEditorSheet(record: record)
        }
        .sheet(item: $editingStockResearchItem) { item in
            StockResearchEditorSheet(
                item: item,
                thesis: stockResearchThesisBinding(for: item),
                onRename: { newName in
                    renameStockResearchItem(item, name: newName)
                },
                onSaveRatings: { certainty, growth, attention in
                    updateStockResearchRatings(item, certainty: certainty, growth: growth, attention: attention)
                }
            )
        }
        .sheet(isPresented: $isShowingStockAddAlert) {
            StockResearchAddSheet(name: $stockNameInput, showsSuggestions: stockResearchItems.isEmpty) {
                addStockResearchItem()
            } onCancel: {
                stockNameInput = ""
                isShowingStockAddAlert = false
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingTodoAddSheet) {
            TodoAddSheet(initialPriority: todoAddInitialPriority) { title, detail, priority, dueDate in
                todoTasks.insert(TodoTask(title: title, detail: detail, createdAt: Date(), priority: priority, dueDate: dueDate), at: 0)
                persistTodoTasks()
            }
            .presentationDetents([.height(640)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingTodoTask) { task in
            TodoEditorSheet(task: task) { newTitle, newDetail, newPriority, newDueDate in
                updateTodoTask(task, title: newTitle, detail: newDetail, priority: newPriority, dueDate: newDueDate)
            }
            .presentationDetents([.height(640)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingNoteAddSheet) {
            MemoNoteEditorSheet(
                existingTags: allMemoNoteTags,
                initialImageDatas: []
            ) { content, tags, imageDatas in
                addMemoNote(content: content, tags: tags, imageDatas: imageDatas)
                isShowingNoteAddSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingMemoNote) { note in
            MemoNoteEditorSheet(
                note: note,
                existingTags: allMemoNoteTags,
                initialImageDatas: note.imageFileNames.compactMap(loadMemoNoteImageData)
            ) { content, tags, imageDatas in
                updateMemoNote(note, content: content, tags: tags, imageDatas: imageDatas)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingWishlistAddSheet) {
            WishlistAddSheet(title: $wishlistInput, note: $wishlistNoteInput, categoryID: $wishlistCategoryID, categories: sortedWishlistCategories) {
                insertWishlistItem(title: wishlistInput, note: wishlistNoteInput, categoryID: wishlistCategoryID)
                isShowingWishlistAddSheet = false
            } onCancel: {
                wishlistInput = ""
                wishlistNoteInput = ""
                isShowingWishlistAddSheet = false
            }
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingWishlistItem) { item in
            WishlistEditorSheet(item: item, categories: wishlistCategories) { newTitle, newNote, newCategoryID in
                updateWishlistItem(item, title: newTitle, note: newNote, categoryID: newCategoryID)
            }
            .presentationDetents([.height(560)])
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
        .confirmationDialog("选择分类", isPresented: $isShowingWishlistCategoryPicker, titleVisibility: .visible) {
            ForEach(sortedWishlistCategories) { category in
                Button(category.title) {
                    insertWishlistItem(title: wishlistInput, note: wishlistNoteInput, categoryID: category.id)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("把「\(wishlistInput.trimmingCharacters(in: .whitespacesAndNewlines))」归到哪个分类？")
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

    func mainTabContent(for tab: MainAppTab) -> AnyView {
        switch tab {
        case .health:
            return AnyView(healthPage)
        case .todo:
            return AnyView(memoPage)
        case .finance:
            return AnyView(financePage)
        }
    }

    func rootTabContent(for tab: RootAppTab) -> AnyView {
        switch tab {
        case .health:
            return mainTabContent(for: .health)
        case .todo:
            return mainTabContent(for: .todo)
        case .finance:
            return mainTabContent(for: .finance)
        case .profile:
            return AnyView(profilePage)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
