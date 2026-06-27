import SwiftUI

extension ContentView {
    /// 每次写入后调用：请求 iCloud 同步并刷新可见的同步时间/状态。
    @discardableResult
    func flushToICloud() -> Bool {
        let didSync = cloudStore.synchronize()
        if didSync && isICloudAvailable {
            lastICloudSyncAt = Date().timeIntervalSince1970
            syncStatus = "已同步到 iCloud"
        } else {
            syncStatus = "已本地保存，iCloud 暂不可用"
        }
        return didSync
    }

    func loadMainTabPreferences() {
        guard !mainTabPreferencesData.isEmpty,
              let preferences = try? JSONDecoder().decode(MainTabPreferences.self, from: mainTabPreferencesData) else {
            return
        }

        applyMainTabPreferences(preferences)
    }

    func persistMainTabPreferences() {
        let preferences = MainTabPreferences(order: mainTabOrder, visibleTabs: Array(visibleMainTabSet))

        if let encodedPreferences = try? JSONEncoder().encode(preferences) {
            mainTabPreferencesData = encodedPreferences
            cloudStore.set(encodedPreferences, forKey: mainTabPreferencesCloudKey)
            flushToICloud()
        }
    }

    func applyMainTabPreferences(_ preferences: MainTabPreferences) {
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

    func mainTabVisibilityBinding(for tab: MainAppTab) -> Binding<Bool> {
        Binding(
            get: {
                visibleMainTabSet.contains(tab)
            },
            set: { isVisible in
                setMainTab(tab, isVisible: isVisible)
            }
        )
    }

    func setMainTab(_ tab: MainAppTab, isVisible: Bool) {
        if isVisible {
            visibleMainTabSet.insert(tab)
        } else if !isOnlyVisibleMainTab(tab) {
            visibleMainTabSet.remove(tab)
        }

        persistMainTabPreferences()
    }

    func isOnlyVisibleMainTab(_ tab: MainAppTab) -> Bool {
        visibleMainTabSet.contains(tab) && visibleMainTabSet.count == 1
    }

    func moveMainTabs(from source: IndexSet, to destination: Int) {
        mainTabOrder.move(fromOffsets: source, toOffset: destination)
        if !isEditingTabs {
            persistMainTabPreferences()
        }
    }

    func toggleTabEditMode() {
        if isEditingTabs {
            commitTabEditMode()
        } else {
            beginTabEditMode()
        }
    }

    func beginTabEditMode() {
        tabEditOriginalOrder = mainTabOrder
        tabEditOriginalVisibleSet = visibleMainTabSet
        withAnimation {
            editMode?.wrappedValue = .active
        }
    }

    func commitTabEditMode() {
        withAnimation {
            editMode?.wrappedValue = .inactive
        }
        persistMainTabPreferences()
    }

    func cancelTabEditMode() {
        mainTabOrder = tabEditOriginalOrder
        visibleMainTabSet = tabEditOriginalVisibleSet
        withAnimation {
            editMode?.wrappedValue = .inactive
        }
        persistMainTabPreferences()
    }

    // MARK: - 各 tab 内分区偏好（顺序 / 显示隐藏）

    func loadSectionPreferences() {
        if let prefs = decodeSectionPreferences(HealthSection.self, from: healthSectionPreferencesData) {
            healthSectionPrefs = migrateHealthSectionPreferences(prefs)
        }
        if let prefs = decodeSectionPreferences(MemoSection.self, from: memoSectionPreferencesData) {
            memoSectionPrefs = migrateMemoSectionPreferences(prefs)
        }
        if let prefs = decodeSectionPreferences(FinanceSection.self, from: financeSectionPreferencesData) {
            financeSectionPrefs = migrateFinanceSectionPreferences(prefs)
        }
        clampSectionSelections()
    }

    func decodeSectionPreferences<S>(_ type: S.Type, from data: Data) -> SectionPreferences<S>? {
        guard !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(SectionPreferences<S>.self, from: data)
    }

    func migrateHealthSectionPreferences(_ prefs: SectionPreferences<HealthSection>) -> SectionPreferences<HealthSection> {
        var order = prefs.order
        var visibleSections = prefs.visibleSections

        if !order.contains(.exercise) {
            if let moodIndex = order.firstIndex(of: .mood) {
                order.insert(.exercise, at: moodIndex)
            } else {
                order.append(.exercise)
            }
        }

        if !visibleSections.contains(.exercise) {
            visibleSections.append(.exercise)
        }

        if !order.contains(.mood) {
            order.append(.mood)
            visibleSections.append(.mood)
        } else if !visibleSections.contains(.mood) && !UserDefaults.standard.bool(forKey: "hasMigratedMoodVisibilityFix") {
            visibleSections.append(.mood)
            UserDefaults.standard.set(true, forKey: "hasMigratedMoodVisibilityFix")
        }

        return SectionPreferences(order: order, visibleSections: visibleSections).normalized
    }

    func migrateMemoSectionPreferences(_ prefs: SectionPreferences<MemoSection>) -> SectionPreferences<MemoSection> {
        var order = prefs.order
        var visibleSections = prefs.visibleSections

        if !order.contains(.note) {
            if let todoIndex = order.firstIndex(of: .todo) {
                order.insert(.note, at: todoIndex + 1)
            } else {
                order.insert(.note, at: min(1, order.count))
            }
        }

        if !visibleSections.contains(.note) {
            visibleSections.append(.note)
        }

        if !order.contains(.calendar) {
            if let anniversaryIndex = order.firstIndex(of: .anniversary) {
                order.insert(.calendar, at: anniversaryIndex + 1)
            } else {
                order.append(.calendar)
            }
        }

        if !visibleSections.contains(.calendar) {
            visibleSections.append(.calendar)
        }

        return SectionPreferences(order: order, visibleSections: visibleSections).normalized
    }

    func migrateFinanceSectionPreferences(_ prefs: SectionPreferences<FinanceSection>) -> SectionPreferences<FinanceSection> {
        var order = prefs.order
        var visibleSections = prefs.visibleSections

        if !order.contains(.expenseBook) {
            order.insert(.expenseBook, at: 0)
        } else if let expenseIndex = order.firstIndex(of: .expenseBook), expenseIndex != 0 {
            order.remove(at: expenseIndex)
            order.insert(.expenseBook, at: 0)
        }

        if !visibleSections.contains(.expenseBook) {
            visibleSections.append(.expenseBook)
        }

        return SectionPreferences(order: order, visibleSections: visibleSections).normalized
    }

    /// 选中的分区如果被隐藏了，回退到第一个可见分区。
    func clampSectionSelections() {
        let healthVisible = healthSectionPrefs.orderedVisible
        if !healthVisible.contains(healthSection), let first = healthVisible.first {
            healthSection = first
        }
        let memoVisible = memoSectionPrefs.orderedVisible
        if !memoVisible.contains(memoSection), let first = memoVisible.first {
            memoSection = first
        }
        let financeVisible = financeSectionPrefs.orderedVisible
        if !financeVisible.contains(financeSection), let first = financeVisible.first {
            financeSection = first
        }
    }

    func persistHealthSectionPreferences() {
        if let encoded = try? JSONEncoder().encode(healthSectionPrefs) {
            healthSectionPreferencesData = encoded
            cloudStore.set(encoded, forKey: healthSectionPreferencesCloudKey)
            flushToICloud()
        }
    }

    func persistMemoSectionPreferences() {
        if let encoded = try? JSONEncoder().encode(memoSectionPrefs) {
            memoSectionPreferencesData = encoded
            cloudStore.set(encoded, forKey: memoSectionPreferencesCloudKey)
            flushToICloud()
        }
    }

    func persistFinanceSectionPreferences() {
        if let encoded = try? JSONEncoder().encode(financeSectionPrefs) {
            financeSectionPreferencesData = encoded
            cloudStore.set(encoded, forKey: financeSectionPreferencesCloudKey)
            flushToICloud()
        }
    }

    func moveHealthSections(from source: IndexSet, to destination: Int) {
        healthSectionPrefs.order.move(fromOffsets: source, toOffset: destination)
        clampSectionSelections()
        persistHealthSectionPreferences()
    }

    func moveMemoSections(from source: IndexSet, to destination: Int) {
        memoSectionPrefs.order.move(fromOffsets: source, toOffset: destination)
        clampSectionSelections()
        persistMemoSectionPreferences()
    }

    func moveFinanceSections(from source: IndexSet, to destination: Int) {
        financeSectionPrefs.order.move(fromOffsets: source, toOffset: destination)
        clampSectionSelections()
        persistFinanceSectionPreferences()
    }

    func resetSectionPreferences() {
        healthSectionPrefs = SectionPreferences<HealthSection>()
        memoSectionPrefs = SectionPreferences<MemoSection>()
        financeSectionPrefs = SectionPreferences<FinanceSection>()
        clampSectionSelections()
        persistHealthSectionPreferences()
        persistMemoSectionPreferences()
        persistFinanceSectionPreferences()
    }

    func healthSectionVisibilityBinding(for section: HealthSection) -> Binding<Bool> {
        Binding(
            get: { healthSectionPrefs.visibleSections.contains(section) },
            set: { isVisible in setHealthSection(section, isVisible: isVisible) }
        )
    }

    func memoSectionVisibilityBinding(for section: MemoSection) -> Binding<Bool> {
        Binding(
            get: { memoSectionPrefs.visibleSections.contains(section) },
            set: { isVisible in setMemoSection(section, isVisible: isVisible) }
        )
    }

    func financeSectionVisibilityBinding(for section: FinanceSection) -> Binding<Bool> {
        Binding(
            get: { financeSectionPrefs.visibleSections.contains(section) },
            set: { isVisible in setFinanceSection(section, isVisible: isVisible) }
        )
    }

    func setHealthSection(_ section: HealthSection, isVisible: Bool) {
        if isVisible {
            if !healthSectionPrefs.visibleSections.contains(section) {
                healthSectionPrefs.visibleSections.append(section)
            }
        } else if healthSectionPrefs.visibleSections.count > 1 {
            healthSectionPrefs.visibleSections.removeAll { $0 == section }
        }
        clampSectionSelections()
        persistHealthSectionPreferences()
    }

    func setMemoSection(_ section: MemoSection, isVisible: Bool) {
        if isVisible {
            if !memoSectionPrefs.visibleSections.contains(section) {
                memoSectionPrefs.visibleSections.append(section)
            }
        } else if memoSectionPrefs.visibleSections.count > 1 {
            memoSectionPrefs.visibleSections.removeAll { $0 == section }
        }
        clampSectionSelections()
        persistMemoSectionPreferences()
    }

    func setFinanceSection(_ section: FinanceSection, isVisible: Bool) {
        if isVisible {
            if !financeSectionPrefs.visibleSections.contains(section) {
                financeSectionPrefs.visibleSections.append(section)
            }
        } else if financeSectionPrefs.visibleSections.count > 1 {
            financeSectionPrefs.visibleSections.removeAll { $0 == section }
        }
        clampSectionSelections()
        persistFinanceSectionPreferences()
    }

    func isOnlyVisibleHealthSection(_ section: HealthSection) -> Bool {
        healthSectionPrefs.visibleSections == [section]
    }

    func isOnlyVisibleMemoSection(_ section: MemoSection) -> Bool {
        memoSectionPrefs.visibleSections == [section]
    }

    func isOnlyVisibleFinanceSection(_ section: FinanceSection) -> Bool {
        financeSectionPrefs.visibleSections == [section]
    }

    func loadAppData() {
        loadMainTabPreferences()
        loadSectionPreferences()
        loadWeightLogs()
        loadFastingSessions()
        loadExerciseGoals()
        loadExerciseRecords()
        loadCalculatorHistory()
        loadTodoTasks()
        loadMemoNotes()
        loadWishlistCategories()
        loadWishlistItems()
        loadAnniversaryItems()
        loadFinanceAssets()
        loadFinanceSnapshots()
        recoverFinanceAssetsFromSnapshotsIfNeeded()
        loadExpenseCategories()
        loadExpenseRecords()
        loadStockResearchItems()
        pullFromICloud()
        recoverFinanceAssetsFromSnapshotsIfNeeded()
        pushAllToICloud()
        applyColdStartSelectionIfNeeded()
        rescheduleFastingNotifications()
    }

    /// 冷启动（新进程首次加载）时，按用户自定义顺序定位到第一个 tab 与各模块的第一个分区。
    /// 进程存活期间不再重置，由 `@State` 自然记忆用户切换过的位置。
    func applyColdStartSelectionIfNeeded() {
        guard !didApplyColdStartSelection else { return }
        didApplyColdStartSelection = true

        if let firstTab = visibleMainTabs.first {
            selectedTabID = firstTab.rawValue
        }
        if let firstHealth = visibleHealthSections.first {
            healthSection = firstHealth
        }
        if let firstMemo = visibleMemoSections.first {
            memoSection = firstMemo
        }
        if let firstFinance = visibleFinanceSections.first {
            financeSection = firstFinance
        }
    }

    /// 旧版本因新增字段导致资产解码失败而清空时，从最近一次非空快照里恢复资产。
    func recoverFinanceAssetsFromSnapshotsIfNeeded() {
        guard financeAssets.isEmpty else { return }
        guard let snapshot = financeSnapshots
            .sorted(by: { $0.date > $1.date })
            .first(where: { !$0.assets.isEmpty }) else { return }

        financeAssets = snapshot.assets
        if let encodedAssets = try? JSONEncoder().encode(financeAssets) {
            financeAssetsData = encodedAssets
            cloudStore.set(encodedAssets, forKey: financeAssetsCloudKey)
        }
    }

    func loadWeightLogs() {
        guard !weightLogsData.isEmpty else {
            migrateLatestWeightIfNeeded()
            return
        }

        if let decodedLogs = try? JSONDecoder().decode([FastingLog].self, from: weightLogsData) {
            weightLogs = decodedLogs
            latestWeight = latestWeightLog.map { weightText($0.weight) } ?? latestWeight
        }
    }

    func migrateLatestWeightIfNeeded() {
        let normalizedWeight = latestWeight.replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(normalizedWeight), weightLogs.isEmpty else { return }

        weightLogs = [FastingLog(date: Date(), weight: weight, note: "历史最近记录")]
        persistWeightLogs()
    }

    func persistWeightLogs() {
        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            weightLogsData = encodedLogs
            cloudStore.set(encodedLogs, forKey: weightLogsCloudKey)
            persistSettingsToICloud()
            flushToICloud()
        }
    }

    func deleteWeightLog(_ log: FastingLog) {
        weightLogs.removeAll { $0.id == log.id }
        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? ""
        persistWeightLogs()
    }

    func updateWeightLog(_ log: FastingLog, weight: Double, note: String) {
        guard let index = weightLogs.firstIndex(where: { $0.id == log.id }) else { return }
        weightLogs[index].weight = weight
        weightLogs[index].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        weightLogs[index].updatedAt = Date()
        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? ""
        persistWeightLogs()
    }

    func loadTodoTasks() {
        guard !todoTasksData.isEmpty else { return }

        if let decodedTasks = try? JSONDecoder().decode([TodoTask].self, from: todoTasksData) {
            todoTasks = decodedTasks
        }
    }

    func loadCalculatorHistory() {
        guard !calculatorHistoryData.isEmpty else { return }

        if let decodedHistory = try? JSONDecoder().decode([CalculatorHistoryItem].self, from: calculatorHistoryData) {
            calculatorHistory = decodedHistory.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func loadMemoNotes() {
        guard !memoNotesData.isEmpty else { return }

        if let decodedNotes = try? JSONDecoder().decode([MemoNote].self, from: memoNotesData) {
            memoNotes = decodedNotes
            normalizeMemoNoteTagFilter()
        }
    }

    func addTodoTask() {
        let trimmedTitle = todoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        todoTasks.insert(TodoTask(title: trimmedTitle, createdAt: Date(), priority: todoPriorityInput), at: 0)
        todoInput = ""
        persistTodoTasks()
    }

    func toggleTodoTask(_ task: TodoTask) {
        setTodoTaskStatus(task, status: task.isCompleted ? .pending : .completed)
    }

    func setTodoTaskStatus(_ task: TodoTask, status: TodoTaskStatus) {
        guard let index = todoTasks.firstIndex(where: { $0.id == task.id }) else { return }

        guard todoTasks[index].status != status else { return }

        todoTasks[index].status = status
        todoTasks[index].completedAt = status == .completed ? Date() : nil
        todoTasks[index].updatedAt = Date()
        persistTodoTasks()
    }

    func deleteTodoTask(_ task: TodoTask) {
        todoTasks.removeAll { $0.id == task.id }
        persistTodoTasks()
    }

    func updateTodoTask(_ task: TodoTask, title: String, priority: TodoPriority, dueDate: Date?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = todoTasks.firstIndex(where: { $0.id == task.id }) else { return }

        guard todoTasks[index].title != trimmed
                || todoTasks[index].priority != priority
                || todoTasks[index].dueDate != dueDate else { return }

        todoTasks[index].title = trimmed
        todoTasks[index].priority = priority
        todoTasks[index].dueDate = dueDate
        todoTasks[index].updatedAt = Date()
        persistTodoTasks()
    }

    func toggleTodoTaskPin(_ task: TodoTask) {
        guard let index = todoTasks.firstIndex(where: { $0.id == task.id }) else { return }
        todoTasks[index].isPinned.toggle()
        todoTasks[index].updatedAt = Date()
        persistTodoTasks()
    }

    func persistTodoTasks() {
        if let encodedTasks = try? JSONEncoder().encode(todoTasks) {
            todoTasksData = encodedTasks
            cloudStore.set(encodedTasks, forKey: todoTasksCloudKey)
            flushToICloud()
        }
    }

    func persistCalculatorHistory() {
        calculatorHistory = Array(calculatorHistory.sorted { $0.createdAt > $1.createdAt }.prefix(200))

        if let encodedHistory = try? JSONEncoder().encode(calculatorHistory) {
            calculatorHistoryData = encodedHistory
            cloudStore.set(encodedHistory, forKey: calculatorHistoryCloudKey)
            flushToICloud()
        }
    }

    func clearCalculatorHistory() {
        calculatorHistory.removeAll()
        persistCalculatorHistory()
    }

    func addMemoNote(content: String, tags: [String], imageDatas: [Data]) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTags = MemoNote.sanitizedTags(tags)
        guard !trimmedContent.isEmpty || !imageDatas.isEmpty || !normalizedTags.isEmpty,
              let imageFileNames = storeMemoNoteImages(imageDatas) else { return }

        memoNotes.insert(
            MemoNote(content: trimmedContent, tags: normalizedTags, createdAt: Date(), imageFileNames: imageFileNames),
            at: 0
        )
        normalizeMemoNoteTagFilter()
        persistMemoNotes()
    }

    func updateMemoNote(_ note: MemoNote, content: String, tags: [String], imageDatas: [Data]) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTags = MemoNote.sanitizedTags(tags)
        guard !trimmedContent.isEmpty || !imageDatas.isEmpty || !normalizedTags.isEmpty,
              let index = memoNotes.firstIndex(where: { $0.id == note.id }),
              let imageFileNames = storeMemoNoteImages(imageDatas) else { return }

        let oldImageFileNames = memoNotes[index].imageFileNames
        memoNotes[index].content = trimmedContent
        memoNotes[index].tags = normalizedTags
        memoNotes[index].updatedAt = Date()
        memoNotes[index].imageFileNames = imageFileNames
        normalizeMemoNoteTagFilter()
        persistMemoNotes()
        deleteMemoNoteImages(fileNames: oldImageFileNames)
    }

    func deleteMemoNote(_ note: MemoNote) {
        let fileNames = memoNotes.first(where: { $0.id == note.id })?.imageFileNames ?? []
        memoNotes.removeAll { $0.id == note.id }
        normalizeMemoNoteTagFilter()
        persistMemoNotes()
        deleteMemoNoteImages(fileNames: fileNames)
    }

    func toggleMemoNotePin(_ note: MemoNote) {
        guard let index = memoNotes.firstIndex(where: { $0.id == note.id }) else { return }
        memoNotes[index].isPinned.toggle()
        memoNotes[index].updatedAt = Date()
        persistMemoNotes()
    }

    func persistMemoNotes() {
        if let encodedNotes = try? JSONEncoder().encode(memoNotes) {
            memoNotesData = encodedNotes
        }
    }

    func normalizeMemoNoteTagFilter() {
        if let noteTagFilter, !allMemoNoteTags.contains(noteTagFilter) {
            self.noteTagFilter = nil
        }
    }

    func memoNoteImagesDirectoryURL() -> URL? {
        guard let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directoryURL = baseURL.appendingPathComponent("MemoNoteImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }
        return directoryURL
    }

    func storeMemoNoteImages(_ imageDatas: [Data]) -> [String]? {
        guard let directoryURL = memoNoteImagesDirectoryURL() else { return nil }

        var fileNames: [String] = []

        for imageData in imageDatas {
            let fileName = "\(UUID().uuidString).img"
            let fileURL = directoryURL.appendingPathComponent(fileName)

            do {
                try imageData.write(to: fileURL, options: .atomic)
                fileNames.append(fileName)
            } catch {
                deleteMemoNoteImages(fileNames: fileNames)
                return nil
            }
        }

        return fileNames
    }

    func loadMemoNoteImageData(fileName: String) -> Data? {
        guard let directoryURL = memoNoteImagesDirectoryURL() else { return nil }
        return try? Data(contentsOf: directoryURL.appendingPathComponent(fileName))
    }

    func deleteMemoNoteImages(fileNames: [String]) {
        guard let directoryURL = memoNoteImagesDirectoryURL() else { return }

        for fileName in fileNames {
            let fileURL = directoryURL.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func loadWishlistItems() {
        guard !wishlistItemsData.isEmpty else { return }

        if let decodedItems = try? JSONDecoder().decode([WishlistItem].self, from: wishlistItemsData) {
            wishlistItems = decodedItems
        }
    }

    func loadWishlistCategories() {
        guard !wishlistCategoriesData.isEmpty else {
            wishlistCategories = WishlistCategory.defaultCategories
            return
        }

        if let decodedCategories = try? JSONDecoder().decode([WishlistCategory].self, from: wishlistCategoriesData),
           !decodedCategories.isEmpty {
            wishlistCategories = decodedCategories
            if !wishlistCategories.contains(where: { $0.id == "music" }),
               let musicCategory = WishlistCategory.defaultCategories.first(where: { $0.id == "music" }) {
                let insertIndex = wishlistCategories.firstIndex(where: { $0.id == "experience" }) ?? wishlistCategories.endIndex
                wishlistCategories.insert(musicCategory, at: insertIndex)
                persistWishlistCategories()
            }
            if !wishlistCategories.contains(where: { $0.id == "other" }),
               let otherCategory = WishlistCategory.defaultCategories.first(where: { $0.id == "other" }) {
                wishlistCategories.append(otherCategory)
                persistWishlistCategories()
            }
            if !wishlistCategories.contains(where: { $0.id == wishlistCategoryID }) {
                wishlistCategoryID = wishlistCategories.first?.id ?? WishlistCategory.fallback.id
            }
        }
    }

    func addWishlistItem() {
        let trimmedTitle = wishlistInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let categoryID = wishlistFilter.categoryID {
            insertWishlistItem(title: trimmedTitle, note: wishlistNoteInput, categoryID: categoryID)
        } else {
            isShowingWishlistCategoryPicker = true
        }
    }

    func insertWishlistItem(title: String, note: String = "", categoryID: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        wishlistItems.insert(
            WishlistItem(title: trimmedTitle, note: trimmedNote, categoryID: categoryID, createdAt: Date()),
            at: 0
        )
        wishlistCategoryID = categoryID
        wishlistInput = ""
        wishlistNoteInput = ""
        persistWishlistItems()
    }

    func toggleWishlistItem(_ item: WishlistItem) {
        guard let index = wishlistItems.firstIndex(where: { $0.id == item.id }) else { return }

        wishlistItems[index].completedAt = wishlistItems[index].isCompleted ? nil : Date()
        persistWishlistItems()
    }

    func deleteWishlistItem(_ item: WishlistItem) {
        wishlistItems.removeAll { $0.id == item.id }
        persistWishlistItems()
    }

    func updateWishlistItem(_ item: WishlistItem, title: String, note: String, categoryID: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = wishlistItems.firstIndex(where: { $0.id == item.id }) else { return }

        wishlistItems[index].title = trimmed
        wishlistItems[index].note = trimmedNote
        wishlistItems[index].categoryID = categoryID
        wishlistItems[index].updatedAt = Date()
        persistWishlistItems()
    }

    func toggleWishlistItemPin(_ item: WishlistItem) {
        guard let index = wishlistItems.firstIndex(where: { $0.id == item.id }) else { return }
        wishlistItems[index].isPinned.toggle()
        wishlistItems[index].updatedAt = Date()
        persistWishlistItems()
    }

    func addWishlistCategory(title: String, icon: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let baseID = trimmed.lowercased()
        var id = baseID.isEmpty ? UUID().uuidString : baseID
        var suffix = 2
        while wishlistCategories.contains(where: { $0.id == id }) {
            id = "\(baseID)-\(suffix)"
            suffix += 1
        }

        let category = WishlistCategory(id: id, title: trimmed, icon: icon)
        wishlistCategories.append(category)
        wishlistCategoryID = category.id
        wishlistFilter = WishlistFilter(category: category)
        persistWishlistCategories()
    }

    func updateWishlistCategory(_ category: WishlistCategory, title: String, icon: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = wishlistCategories.firstIndex(where: { $0.id == category.id }) else { return }

        wishlistCategories[index].title = trimmed
        wishlistCategories[index].icon = icon
        if wishlistFilter.categoryID == category.id {
            wishlistFilter = WishlistFilter(category: wishlistCategories[index])
        }
        persistWishlistCategories()
    }

    func deleteWishlistCategory(_ category: WishlistCategory) {
        guard wishlistCategories.count > 1 else { return }

        let fallbackID = wishlistCategories.first(where: { $0.id != category.id })?.id ?? WishlistCategory.fallback.id
        wishlistCategories.removeAll { $0.id == category.id }
        for index in wishlistItems.indices where wishlistItems[index].categoryID == category.id {
            wishlistItems[index].categoryID = fallbackID
        }

        if wishlistCategoryID == category.id {
            wishlistCategoryID = fallbackID
        }
        if wishlistFilter.categoryID == category.id {
            wishlistFilter = .all
        }

        persistWishlistCategories()
        persistWishlistItems()
    }

    func persistWishlistCategories() {
        if let encodedCategories = try? JSONEncoder().encode(wishlistCategories) {
            wishlistCategoriesData = encodedCategories
            cloudStore.set(encodedCategories, forKey: wishlistCategoriesCloudKey)
            flushToICloud()
        }
    }

    func persistWishlistItems() {
        if let encodedItems = try? JSONEncoder().encode(wishlistItems) {
            wishlistItemsData = encodedItems
            cloudStore.set(encodedItems, forKey: wishlistItemsCloudKey)
            flushToICloud()
        }
    }

    func loadAnniversaryItems() {
        guard !anniversaryItemsData.isEmpty else { return }

        if let decodedItems = try? JSONDecoder().decode([AnniversaryItem].self, from: anniversaryItemsData) {
            anniversaryItems = decodedItems
        }
    }

    func addAnniversaryItem() {
        let trimmedTitle = anniversaryTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        anniversaryItems.insert(
            AnniversaryItem(
                title: trimmedTitle,
                kind: .other,
                calendarKind: anniversaryCalendarKind,
                date: anniversaryDate,
                createdAt: Date(),
                showsElapsedDays: anniversaryShowsElapsedDays
            ),
            at: 0
        )
        anniversaryTitleInput = ""
        anniversaryDate = Date()
        anniversaryShowsElapsedDays = false
        persistAnniversaryItems()
        isShowingAnniversarySheet = false
    }

    func deleteAnniversaryItem(_ item: AnniversaryItem) {
        anniversaryItems.removeAll { $0.id == item.id }
        persistAnniversaryItems()
    }

    func updateAnniversaryItem(
        _ item: AnniversaryItem,
        title: String,
        calendarKind: AnniversaryCalendarKind,
        date: Date,
        showsElapsedDays: Bool
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = anniversaryItems.firstIndex(where: { $0.id == item.id }) else { return }

        anniversaryItems[index].title = trimmed
        anniversaryItems[index].calendarKind = calendarKind
        anniversaryItems[index].date = date
        anniversaryItems[index].showsElapsedDays = showsElapsedDays
        anniversaryItems[index].updatedAt = Date()
        persistAnniversaryItems()
    }

    func toggleAnniversaryItemPin(_ item: AnniversaryItem) {
        guard let index = anniversaryItems.firstIndex(where: { $0.id == item.id }) else { return }
        anniversaryItems[index].isPinned.toggle()
        anniversaryItems[index].updatedAt = Date()
        persistAnniversaryItems()
    }

    func persistAnniversaryItems() {
        if let encodedItems = try? JSONEncoder().encode(anniversaryItems) {
            anniversaryItemsData = encodedItems
            cloudStore.set(encodedItems, forKey: anniversaryItemsCloudKey)
            flushToICloud()
        }
    }

    func loadFinanceAssets() {
        guard !financeAssetsData.isEmpty else { return }

        if let decodedAssets = try? JSONDecoder().decode([FinanceAsset].self, from: financeAssetsData) {
            financeAssets = decodedAssets
        }
    }

    func loadFinanceSnapshots() {
        guard !financeSnapshotsData.isEmpty else { return }

        if let decodedSnapshots = try? JSONDecoder().decode([FinanceSnapshot].self, from: financeSnapshotsData) {
            financeSnapshots = decodedSnapshots
        }
    }

    func loadExpenseCategories() {
        guard !expenseCategoriesData.isEmpty else { return }

        if let decodedCategories = try? JSONDecoder().decode([ExpenseCategory].self, from: expenseCategoriesData) {
            expenseCategories = normalizedExpenseCategories(decodedCategories)
        }
    }

    func loadExpenseRecords() {
        guard !expenseRecordsData.isEmpty else { return }

        if let decodedRecords = try? JSONDecoder().decode([ExpenseRecord].self, from: expenseRecordsData) {
            expenseRecords = decodedRecords
        }
    }

    func addFinanceAsset() {
        let trimmedAmount = financeAssetAmountInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = trimmedAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalizedAmount) else { return }

        let trimmedName = financeAssetNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let assetName = trimmedName.isEmpty ? financeAssetKind.title : trimmedName
        let trimmedNote = financeAssetNoteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        financeAssets.insert(
            FinanceAsset(name: assetName, kind: financeAssetKind, amount: amount, createdAt: now, updatedAt: now, note: trimmedNote),
            at: 0
        )
        financeAssetNameInput = ""
        financeAssetAmountInput = ""
        financeAssetNoteInput = ""
        persistFinanceAssets(recordSnapshot: true)
        isShowingFinanceAssetSheet = false
    }

    func updateFinanceAsset(_ asset: FinanceAsset, name: String, kind: FinanceAssetKind, amount: Double, note: String) {
        guard let index = financeAssets.firstIndex(where: { $0.id == asset.id }) else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            financeAssets[index].name = trimmedName
        }
        financeAssets[index].kind = kind
        financeAssets[index].amount = amount
        financeAssets[index].note = note
        financeAssets[index].updatedAt = Date()
        persistFinanceAssets(recordSnapshot: true)
    }

    func deleteFinanceAsset(_ asset: FinanceAsset) {
        financeAssets.removeAll { $0.id == asset.id }
        persistFinanceAssets(recordSnapshot: true)
    }

    func persistFinanceAssets(recordSnapshot: Bool) {
        if recordSnapshot {
            recordFinanceSnapshot()
        }

        if let encodedAssets = try? JSONEncoder().encode(financeAssets) {
            financeAssetsData = encodedAssets
            cloudStore.set(encodedAssets, forKey: financeAssetsCloudKey)
        }

        persistFinanceSnapshots()
    }

    func recordFinanceSnapshot() {
        let snapshot = FinanceSnapshot(date: Date(), totalAmount: totalFinanceAmount, assets: financeAssets)
        financeSnapshots.insert(snapshot, at: 0)
        financeSnapshots = Array(financeSnapshots.sorted { $0.date > $1.date }.prefix(240))
    }

    func persistFinanceSnapshots() {
        if let encodedSnapshots = try? JSONEncoder().encode(financeSnapshots) {
            financeSnapshotsData = encodedSnapshots
            cloudStore.set(encodedSnapshots, forKey: financeSnapshotsCloudKey)
            flushToICloud()
        }
    }

    @discardableResult
    func upsertExpenseCategory(title: String) -> ExpenseCategory? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        if let existingCategory = expenseCategories.first(where: { $0.title.localizedCaseInsensitiveCompare(trimmedTitle) == .orderedSame }) {
            return existingCategory
        }

        let category = ExpenseCategory(
            id: "custom-\(UUID().uuidString.lowercased())",
            title: trimmedTitle,
            icon: "tag.fill",
            isDefault: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        expenseCategories.append(category)
        expenseCategories = normalizedExpenseCategories(expenseCategories)
        persistExpenseCategories()
        return category
    }

    func addExpenseRecord(amount: Double, categoryID: String, date: Date, note: String) {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        expenseRecords.insert(
            ExpenseRecord(
                amount: amount,
                categoryID: categoryID,
                date: date,
                note: trimmedNote,
                createdAt: now,
                updatedAt: now
            ),
            at: 0
        )
        persistExpenseRecords()
        isShowingExpenseRecordSheet = false
    }

    func updateExpenseRecord(_ record: ExpenseRecord, amount: Double, categoryID: String, date: Date, note: String) {
        guard let index = expenseRecords.firstIndex(where: { $0.id == record.id }) else { return }

        expenseRecords[index].amount = amount
        expenseRecords[index].categoryID = categoryID
        expenseRecords[index].date = date
        expenseRecords[index].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        expenseRecords[index].updatedAt = Date()
        persistExpenseRecords()
    }

    func deleteExpenseRecord(_ record: ExpenseRecord) {
        expenseRecords.removeAll { $0.id == record.id }
        persistExpenseRecords()
    }

    func persistExpenseCategories() {
        expenseCategories = normalizedExpenseCategories(expenseCategories)

        if let encodedCategories = try? JSONEncoder().encode(expenseCategories) {
            expenseCategoriesData = encodedCategories
            cloudStore.set(encodedCategories, forKey: expenseCategoriesCloudKey)
            flushToICloud()
        }
    }

    func persistExpenseRecords() {
        if let encodedRecords = try? JSONEncoder().encode(expenseRecords) {
            expenseRecordsData = encodedRecords
            cloudStore.set(encodedRecords, forKey: expenseRecordsCloudKey)
            flushToICloud()
        }
    }

    func normalizedExpenseCategories(_ categories: [ExpenseCategory]) -> [ExpenseCategory] {
        var mergedByID = Dictionary(uniqueKeysWithValues: ExpenseCategory.defaultCategories.map { ($0.id, $0) })

        for category in categories {
            if let local = mergedByID[category.id] {
                let localUpdatedAt = local.updatedAt ?? local.createdAt
                let categoryUpdatedAt = category.updatedAt ?? category.createdAt
                mergedByID[category.id] = categoryUpdatedAt >= localUpdatedAt ? category : local
            } else {
                mergedByID[category.id] = category
            }
        }

        return mergedByID.values.sorted { lhs, rhs in
            if lhs.isDefault != rhs.isDefault {
                return lhs.isDefault
            }
            return (lhs.updatedAt ?? lhs.createdAt) > (rhs.updatedAt ?? rhs.createdAt)
        }
    }

    func loadStockResearchItems() {
        guard !stockResearchItemsData.isEmpty else { return }

        if let decodedItems = try? JSONDecoder().decode([StockResearchItem].self, from: stockResearchItemsData) {
            stockResearchItems = decodedItems
        }
    }

    func addStockResearchItem() {
        let trimmedName = stockNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if stockResearchItems.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) {
            stockSearchText = trimmedName
            stockNameInput = ""
            isShowingStockAddAlert = false
            return
        }

        stockResearchItems.insert(
            StockResearchItem(name: trimmedName, thesis: "", createdAt: Date(), updatedAt: Date()),
            at: 0
        )
        stockNameInput = ""
        stockSearchText = ""
        isShowingStockAddAlert = false
        persistStockResearchItems()
    }

    func stockResearchThesisBinding(for item: StockResearchItem) -> Binding<String> {
        Binding(
            get: {
                stockResearchItems.first(where: { $0.id == item.id })?.thesis ?? item.thesis
            },
            set: { newThesis in
                updateStockResearchItem(item, thesis: newThesis)
            }
        )
    }

    func updateStockResearchItem(_ item: StockResearchItem, thesis: String) {
        guard let index = stockResearchItems.firstIndex(where: { $0.id == item.id }) else { return }

        stockResearchItems[index].thesis = thesis
        stockResearchItems[index].updatedAt = Date()
        persistStockResearchItems()
    }

    func renameStockResearchItem(_ item: StockResearchItem, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let index = stockResearchItems.firstIndex(where: { $0.id == item.id }) else { return }

        stockResearchItems[index].name = trimmedName
        stockResearchItems[index].updatedAt = Date()
        persistStockResearchItems()
    }

    func updateStockResearchRatings(
        _ item: StockResearchItem,
        certainty: StockRating?,
        growth: StockRating?,
        attention: StockRating?
    ) {
        guard let index = stockResearchItems.firstIndex(where: { $0.id == item.id }) else { return }

        stockResearchItems[index].certainty = certainty
        stockResearchItems[index].growth = growth
        stockResearchItems[index].attention = attention
        stockResearchItems[index].updatedAt = Date()
        persistStockResearchItems()
    }

    func toggleStockResearchPinned(_ item: StockResearchItem) {
        guard let index = stockResearchItems.firstIndex(where: { $0.id == item.id }) else { return }

        stockResearchItems[index].isPinned.toggle()
        persistStockResearchItems()
    }

    func deleteStockResearchItem(_ item: StockResearchItem) {
        stockResearchItems.removeAll { $0.id == item.id }
        persistStockResearchItems()
    }

    func persistStockResearchItems() {
        if let encodedItems = try? JSONEncoder().encode(stockResearchItems) {
            stockResearchItemsData = encodedItems
            cloudStore.set(encodedItems, forKey: stockResearchItemsCloudKey)
            flushToICloud()
        }
    }

    func loadFastingSessions() {
        guard !fastingSessionsData.isEmpty else { return }

        if let decodedSessions = try? JSONDecoder().decode([FastingSession].self, from: fastingSessionsData) {
            fastingSessions = decodedSessions
        }
    }

    func recordCurrentFastingSession(endDate: Date) {
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

    func persistFastingSessions() {
        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            fastingSessionsData = encodedSessions
            cloudStore.set(encodedSessions, forKey: fastingSessionsCloudKey)
            persistSettingsToICloud()
            flushToICloud()
        }
    }

    func loadExerciseGoals() {
        guard !exerciseGoalsData.isEmpty else {
            exerciseGoals = ExerciseGoal.defaultGoals
            return
        }

        if let decodedGoals = try? JSONDecoder().decode([ExerciseGoal].self, from: exerciseGoalsData) {
            exerciseGoals = decodedGoals.isEmpty ? ExerciseGoal.defaultGoals : decodedGoals
        }
    }

    func loadExerciseRecords() {
        guard !exerciseRecordsData.isEmpty else { return }

        if let decodedRecords = try? JSONDecoder().decode([ExerciseRecord].self, from: exerciseRecordsData) {
            exerciseRecords = normalizedExerciseRecords(decodedRecords)
        }
    }

    func persistExerciseGoals() {
        if let encodedGoals = try? JSONEncoder().encode(exerciseGoals) {
            exerciseGoalsData = encodedGoals
            cloudStore.set(encodedGoals, forKey: exerciseGoalsCloudKey)
            flushToICloud()
        }
    }

    func persistExerciseRecords() {
        exerciseRecords = normalizedExerciseRecords(exerciseRecords)
        if let encodedRecords = try? JSONEncoder().encode(exerciseRecords) {
            exerciseRecordsData = encodedRecords
            cloudStore.set(encodedRecords, forKey: exerciseRecordsCloudKey)
            flushToICloud()
        }
    }

    func pullFromICloud() {
        cloudStore.synchronize()

        if let cloudLogsData = cloudStore.data(forKey: weightLogsCloudKey),
           let cloudLogs = try? JSONDecoder().decode([FastingLog].self, from: cloudLogsData) {
            mergeWeightLogs(cloudLogs)
        }

        if let cloudSessionsData = cloudStore.data(forKey: fastingSessionsCloudKey),
           let cloudSessions = try? JSONDecoder().decode([FastingSession].self, from: cloudSessionsData) {
            mergeFastingSessions(cloudSessions)
        }

        if let cloudExerciseGoalsData = cloudStore.data(forKey: exerciseGoalsCloudKey),
           let cloudExerciseGoals = try? JSONDecoder().decode([ExerciseGoal].self, from: cloudExerciseGoalsData) {
            mergeExerciseGoals(cloudExerciseGoals)
        }

        if let cloudExerciseRecordsData = cloudStore.data(forKey: exerciseRecordsCloudKey),
           let cloudExerciseRecords = try? JSONDecoder().decode([ExerciseRecord].self, from: cloudExerciseRecordsData) {
            mergeExerciseRecords(cloudExerciseRecords)
        }

        if let cloudTodoTasksData = cloudStore.data(forKey: todoTasksCloudKey),
           let cloudTodoTasks = try? JSONDecoder().decode([TodoTask].self, from: cloudTodoTasksData) {
            mergeTodoTasks(cloudTodoTasks)
        }

        if let cloudCalculatorHistoryData = cloudStore.data(forKey: calculatorHistoryCloudKey),
           let cloudCalculatorHistory = try? JSONDecoder().decode([CalculatorHistoryItem].self, from: cloudCalculatorHistoryData) {
            mergeCalculatorHistory(cloudCalculatorHistory)
        }

        if let cloudWishlistItemsData = cloudStore.data(forKey: wishlistItemsCloudKey),
           let cloudWishlistItems = try? JSONDecoder().decode([WishlistItem].self, from: cloudWishlistItemsData) {
            mergeWishlistItems(cloudWishlistItems)
        }

        if let cloudWishlistCategoriesData = cloudStore.data(forKey: wishlistCategoriesCloudKey),
           let cloudWishlistCategories = try? JSONDecoder().decode([WishlistCategory].self, from: cloudWishlistCategoriesData) {
            mergeWishlistCategories(cloudWishlistCategories)
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

        if let cloudExpenseCategoriesData = cloudStore.data(forKey: expenseCategoriesCloudKey),
           let cloudExpenseCategories = try? JSONDecoder().decode([ExpenseCategory].self, from: cloudExpenseCategoriesData) {
            mergeExpenseCategories(cloudExpenseCategories)
        }

        if let cloudExpenseRecordsData = cloudStore.data(forKey: expenseRecordsCloudKey),
           let cloudExpenseRecords = try? JSONDecoder().decode([ExpenseRecord].self, from: cloudExpenseRecordsData) {
            mergeExpenseRecords(cloudExpenseRecords)
        }

        if let cloudStockResearchItemsData = cloudStore.data(forKey: stockResearchItemsCloudKey),
           let cloudStockResearchItems = try? JSONDecoder().decode([StockResearchItem].self, from: cloudStockResearchItemsData) {
            mergeStockResearchItems(cloudStockResearchItems)
        }

        if let cloudMainTabPreferencesData = cloudStore.data(forKey: mainTabPreferencesCloudKey),
           let cloudMainTabPreferences = try? JSONDecoder().decode(MainTabPreferences.self, from: cloudMainTabPreferencesData) {
            applyMainTabPreferences(cloudMainTabPreferences)
        }

        if let data = cloudStore.data(forKey: healthSectionPreferencesCloudKey),
           let prefs = try? JSONDecoder().decode(SectionPreferences<HealthSection>.self, from: data) {
            healthSectionPrefs = migrateHealthSectionPreferences(prefs)
            healthSectionPreferencesData = (try? JSONEncoder().encode(healthSectionPrefs)) ?? healthSectionPreferencesData
        }

        if let data = cloudStore.data(forKey: memoSectionPreferencesCloudKey),
           let prefs = try? JSONDecoder().decode(SectionPreferences<MemoSection>.self, from: data) {
            memoSectionPrefs = migrateMemoSectionPreferences(prefs)
            memoSectionPreferencesData = (try? JSONEncoder().encode(memoSectionPrefs)) ?? memoSectionPreferencesData
        }

        if let data = cloudStore.data(forKey: financeSectionPreferencesCloudKey),
           let prefs = try? JSONDecoder().decode(SectionPreferences<FinanceSection>.self, from: data) {
            financeSectionPrefs = migrateFinanceSectionPreferences(prefs)
            financeSectionPreferencesData = (try? JSONEncoder().encode(financeSectionPrefs)) ?? financeSectionPreferencesData
        }

        clampSectionSelections()

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

        if cloudStore.object(forKey: roundStartWeightCloudKey) != nil {
            roundStartWeight = cloudStore.string(forKey: roundStartWeightCloudKey) ?? ""
        }

        syncStatus = "已从 iCloud 检查更新"
    }

    func pushAllToICloud() {
        persistSettingsToICloud()

        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            cloudStore.set(encodedLogs, forKey: weightLogsCloudKey)
        }

        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            cloudStore.set(encodedSessions, forKey: fastingSessionsCloudKey)
        }

        if let encodedExerciseGoals = try? JSONEncoder().encode(exerciseGoals) {
            exerciseGoalsData = encodedExerciseGoals
            cloudStore.set(encodedExerciseGoals, forKey: exerciseGoalsCloudKey)
        }

        if let encodedExerciseRecords = try? JSONEncoder().encode(exerciseRecords) {
            exerciseRecordsData = encodedExerciseRecords
            cloudStore.set(encodedExerciseRecords, forKey: exerciseRecordsCloudKey)
        }

        if let encodedTodoTasks = try? JSONEncoder().encode(todoTasks) {
            cloudStore.set(encodedTodoTasks, forKey: todoTasksCloudKey)
        }

        if let encodedCalculatorHistory = try? JSONEncoder().encode(calculatorHistory) {
            cloudStore.set(encodedCalculatorHistory, forKey: calculatorHistoryCloudKey)
        }

        if let encodedWishlistItems = try? JSONEncoder().encode(wishlistItems) {
            cloudStore.set(encodedWishlistItems, forKey: wishlistItemsCloudKey)
        }

        if let encodedWishlistCategories = try? JSONEncoder().encode(wishlistCategories) {
            cloudStore.set(encodedWishlistCategories, forKey: wishlistCategoriesCloudKey)
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

        if let encodedExpenseCategories = try? JSONEncoder().encode(expenseCategories) {
            cloudStore.set(encodedExpenseCategories, forKey: expenseCategoriesCloudKey)
        }

        if let encodedExpenseRecords = try? JSONEncoder().encode(expenseRecords) {
            cloudStore.set(encodedExpenseRecords, forKey: expenseRecordsCloudKey)
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

        if let encoded = try? JSONEncoder().encode(healthSectionPrefs) {
            healthSectionPreferencesData = encoded
            cloudStore.set(encoded, forKey: healthSectionPreferencesCloudKey)
        }

        if let encoded = try? JSONEncoder().encode(memoSectionPrefs) {
            memoSectionPreferencesData = encoded
            cloudStore.set(encoded, forKey: memoSectionPreferencesCloudKey)
        }

        if let encoded = try? JSONEncoder().encode(financeSectionPrefs) {
            financeSectionPreferencesData = encoded
            cloudStore.set(encoded, forKey: financeSectionPreferencesCloudKey)
        }

        let didSync = cloudStore.synchronize()
        if didSync && isICloudAvailable {
            lastICloudSyncAt = Date().timeIntervalSince1970
        }
        syncStatus = didSync ? "已请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
    }

    /// iCloud 键值存储是否可用：用户已登录 iCloud 才有效。
    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var syncStatusText: String {
        if isSyncing {
            return "正在同步…"
        }
        if syncStatus != "iCloud 同步准备中" {
            return syncStatus
        }
        if !isICloudAvailable {
            return "未连接，无法同步"
        }
        if lastICloudSyncAt > 0 {
            let date = Date(timeIntervalSince1970: lastICloudSyncAt)
            return "上次同步 \(relativeTimeText(for: date))"
        }
        return "等待首次同步"
    }

    var syncLastSyncText: String {
        if isSyncing {
            return "正在同步…"
        }
        guard lastICloudSyncAt > 0 else {
            return "尚未同步"
        }
        let date = Date(timeIntervalSince1970: lastICloudSyncAt)
        return "上次同步 \(syncDateTimeText(for: date))"
    }

    var syncStatusIcon: String {
        if isSyncing {
            return "arrow.triangle.2.circlepath"
        }
        if syncStatusText.contains("完成") || syncStatusText.contains("已同步") || syncStatusText.contains("已请求") {
            return "checkmark.circle.fill"
        }
        if syncStatusText.contains("未") || syncStatusText.contains("无法") || syncStatusText.contains("失败") || syncStatusText.contains("重试") {
            return "exclamationmark.circle.fill"
        }
        return "arrow.triangle.2.circlepath"
    }

    var syncStatusTint: Color {
        if isSyncing {
            return .blue
        }
        if syncStatusText.contains("完成") || syncStatusText.contains("已同步") || syncStatusText.contains("已请求") {
            return .green
        }
        if syncStatusText.contains("未") || syncStatusText.contains("无法") || syncStatusText.contains("失败") || syncStatusText.contains("重试") {
            return .orange
        }
        return .secondary
    }

    /// 用户手动点击「立即同步」：先推送本地数据，再回拉云端，并更新可见状态。
    func syncNow() {
        guard isICloudAvailable else {
            syncStatus = "未登录 iCloud，无法同步"
            showSyncToast("未登录 iCloud，无法同步")
            return
        }

        isSyncing = true
        pushAllToICloud()
        pullFromICloud()

        let succeeded = cloudStore.synchronize()
        if succeeded {
            lastICloudSyncAt = Date().timeIntervalSince1970
        }
        syncStatus = succeeded ? "同步完成" : "同步未完成，请稍后重试"
        isSyncing = false
        showSyncToast(syncStatus)
    }

    func showSyncToast(_ message: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            syncToastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard syncToastMessage == message else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                syncToastMessage = nil
            }
        }
    }

    func syncDateTimeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "M月d日 HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    func persistSettingsToICloud() {
        cloudStore.set(fastingStartTime, forKey: fastingStartTimeCloudKey)
        cloudStore.set(isFasting, forKey: isFastingCloudKey)
        cloudStore.set(Int64(fastingGoalHours), forKey: fastingGoalHoursCloudKey)
        cloudStore.set(Int64(eatingGoalHours), forKey: eatingGoalHoursCloudKey)
        cloudStore.set(latestWeight, forKey: latestWeightCloudKey)
        cloudStore.set(dailyGoal, forKey: dailyGoalCloudKey)
        cloudStore.set(heightCm, forKey: heightCmCloudKey)
        cloudStore.set(targetWeight, forKey: targetWeightCloudKey)
        cloudStore.set(roundStartWeight, forKey: roundStartWeightCloudKey)
    }

    func mergeWeightLogs(_ cloudLogs: [FastingLog]) {
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

    func mergeFastingSessions(_ cloudSessions: [FastingSession]) {
        var mergedSessionsByID = Dictionary(uniqueKeysWithValues: fastingSessions.map { ($0.id, $0) })

        for session in cloudSessions {
            mergedSessionsByID[session.id] = session
        }

        fastingSessions = mergedSessionsByID.values.sorted { $0.endDate > $1.endDate }

        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            fastingSessionsData = encodedSessions
        }
    }

    func mergeExerciseGoals(_ cloudGoals: [ExerciseGoal]) {
        var mergedGoalsByID = Dictionary(uniqueKeysWithValues: exerciseGoals.map { ($0.id, $0) })

        for goal in cloudGoals {
            if let localGoal = mergedGoalsByID[goal.id] {
                mergedGoalsByID[goal.id] = goal.updatedAt >= localGoal.updatedAt ? goal : localGoal
            } else {
                mergedGoalsByID[goal.id] = goal
            }
        }

        exerciseGoals = mergedGoalsByID.values.sorted {
            if $0.isActive != $1.isActive {
                return $0.isActive && !$1.isActive
            }
            return $0.createdAt < $1.createdAt
        }

        if let encodedGoals = try? JSONEncoder().encode(exerciseGoals) {
            exerciseGoalsData = encodedGoals
        }
    }

    func mergeExerciseRecords(_ cloudRecords: [ExerciseRecord]) {
        exerciseRecords = normalizedExerciseRecords(exerciseRecords + cloudRecords)

        if let encodedRecords = try? JSONEncoder().encode(exerciseRecords) {
            exerciseRecordsData = encodedRecords
        }
    }

    func normalizedExerciseRecords(_ records: [ExerciseRecord]) -> [ExerciseRecord] {
        var recordsByDayAndGoal: [String: ExerciseRecord] = [:]

        for record in records {
            let day = Calendar.current.startOfDay(for: record.date)
            let key = "\(record.goalID.uuidString)-\(Int(day.timeIntervalSince1970))"
            var normalizedRecord = record
            normalizedRecord.date = day

            if let existing = recordsByDayAndGoal[key] {
                if normalizedRecord.updatedAt >= existing.updatedAt {
                    recordsByDayAndGoal[key] = normalizedRecord
                }
            } else {
                recordsByDayAndGoal[key] = normalizedRecord
            }
        }

        return recordsByDayAndGoal.values.sorted {
            if $0.date != $1.date {
                return $0.date > $1.date
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    func mergeTodoTasks(_ cloudTasks: [TodoTask]) {
        var mergedTasksByID = Dictionary(uniqueKeysWithValues: todoTasks.map { ($0.id, $0) })

        for task in cloudTasks {
            if let local = mergedTasksByID[task.id], local.lastActivityAt > task.lastActivityAt {
                continue
            }
            mergedTasksByID[task.id] = task
        }

        todoTasks = mergedTasksByID.values.sorted { $0.createdAt > $1.createdAt }

        if let encodedTasks = try? JSONEncoder().encode(todoTasks) {
            todoTasksData = encodedTasks
        }
    }

    func mergeCalculatorHistory(_ cloudHistory: [CalculatorHistoryItem]) {
        var mergedHistoryByID = Dictionary(uniqueKeysWithValues: calculatorHistory.map { ($0.id, $0) })

        for item in cloudHistory {
            if let local = mergedHistoryByID[item.id] {
                mergedHistoryByID[item.id] = item.createdAt >= local.createdAt ? item : local
            } else {
                mergedHistoryByID[item.id] = item
            }
        }

        calculatorHistory = Array(
            mergedHistoryByID.values
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(200)
        )

        if let encodedHistory = try? JSONEncoder().encode(calculatorHistory) {
            calculatorHistoryData = encodedHistory
        }
    }

    func mergeWishlistItems(_ cloudItems: [WishlistItem]) {
        var mergedItemsByID = Dictionary(uniqueKeysWithValues: wishlistItems.map { ($0.id, $0) })

        for item in cloudItems {
            if let local = mergedItemsByID[item.id] {
                let localDate = local.updatedAt ?? local.createdAt
                let cloudDate = item.updatedAt ?? item.createdAt
                mergedItemsByID[item.id] = cloudDate >= localDate ? item : local
            } else {
                mergedItemsByID[item.id] = item
            }
        }

        wishlistItems = mergedItemsByID.values.sorted { $0.createdAt > $1.createdAt }

        if let encodedItems = try? JSONEncoder().encode(wishlistItems) {
            wishlistItemsData = encodedItems
        }
    }

    func mergeWishlistCategories(_ cloudCategories: [WishlistCategory]) {
        var mergedCategoriesByID = Dictionary(uniqueKeysWithValues: wishlistCategories.map { ($0.id, $0) })

        for category in cloudCategories {
            mergedCategoriesByID[category.id] = category
        }

        wishlistCategories = mergedCategoriesByID.values.sorted { $0.title < $1.title }

        if let encodedCategories = try? JSONEncoder().encode(wishlistCategories) {
            wishlistCategoriesData = encodedCategories
        }
    }

    func mergeAnniversaryItems(_ cloudItems: [AnniversaryItem]) {
        var mergedItemsByID = Dictionary(uniqueKeysWithValues: anniversaryItems.map { ($0.id, $0) })

        for item in cloudItems {
            if let local = mergedItemsByID[item.id] {
                mergedItemsByID[item.id] = item.lastActivityAt >= local.lastActivityAt ? item : local
            } else {
                mergedItemsByID[item.id] = item
            }
        }

        anniversaryItems = mergedItemsByID.values.sorted {
            (nextAnniversaryDate(for: $0) ?? $0.date) < (nextAnniversaryDate(for: $1) ?? $1.date)
        }

        if let encodedItems = try? JSONEncoder().encode(anniversaryItems) {
            anniversaryItemsData = encodedItems
        }
    }

    func mergeFinanceAssets(_ cloudAssets: [FinanceAsset]) {
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

    func mergeFinanceSnapshots(_ cloudSnapshots: [FinanceSnapshot]) {
        var mergedSnapshotsByID = Dictionary(uniqueKeysWithValues: financeSnapshots.map { ($0.id, $0) })

        for snapshot in cloudSnapshots {
            mergedSnapshotsByID[snapshot.id] = snapshot
        }

        financeSnapshots = Array(mergedSnapshotsByID.values.sorted { $0.date > $1.date }.prefix(240))

        if let encodedSnapshots = try? JSONEncoder().encode(financeSnapshots) {
            financeSnapshotsData = encodedSnapshots
        }
    }

    func mergeExpenseCategories(_ cloudCategories: [ExpenseCategory]) {
        expenseCategories = normalizedExpenseCategories(expenseCategories + cloudCategories)

        if let encodedCategories = try? JSONEncoder().encode(expenseCategories) {
            expenseCategoriesData = encodedCategories
        }
    }

    func mergeExpenseRecords(_ cloudRecords: [ExpenseRecord]) {
        var mergedRecordsByID = Dictionary(uniqueKeysWithValues: expenseRecords.map { ($0.id, $0) })

        for record in cloudRecords {
            if let localRecord = mergedRecordsByID[record.id] {
                let localUpdatedAt = localRecord.updatedAt ?? localRecord.createdAt
                let cloudUpdatedAt = record.updatedAt ?? record.createdAt
                mergedRecordsByID[record.id] = cloudUpdatedAt >= localUpdatedAt ? record : localRecord
            } else {
                mergedRecordsByID[record.id] = record
            }
        }

        expenseRecords = mergedRecordsByID.values.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date > rhs.date
            }
            return (lhs.updatedAt ?? lhs.createdAt) > (rhs.updatedAt ?? rhs.createdAt)
        }

        if let encodedRecords = try? JSONEncoder().encode(expenseRecords) {
            expenseRecordsData = encodedRecords
        }
    }

    func mergeStockResearchItems(_ cloudItems: [StockResearchItem]) {
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
}
