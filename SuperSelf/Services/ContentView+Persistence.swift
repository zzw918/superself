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
        persistMainTabPreferences()
    }

    func toggleTabEditMode() {
        withAnimation {
            editMode?.wrappedValue = isEditingTabs ? .inactive : .active
        }
    }

    // MARK: - 各 tab 内分区偏好（顺序 / 显示隐藏）

    func loadSectionPreferences() {
        if let prefs = decodeSectionPreferences(HealthSection.self, from: healthSectionPreferencesData) {
            healthSectionPrefs = prefs.normalized
        }
        if let prefs = decodeSectionPreferences(MemoSection.self, from: memoSectionPreferencesData) {
            memoSectionPrefs = prefs.normalized
        }
        if let prefs = decodeSectionPreferences(FinanceSection.self, from: financeSectionPreferencesData) {
            financeSectionPrefs = prefs.normalized
        }
        clampSectionSelections()
    }

    func decodeSectionPreferences<S>(_ type: S.Type, from data: Data) -> SectionPreferences<S>? {
        guard !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(SectionPreferences<S>.self, from: data)
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
        loadTodoTasks()
        loadWishlistCategories()
        loadWishlistItems()
        loadAnniversaryItems()
        loadFinanceAssets()
        loadFinanceSnapshots()
        recoverFinanceAssetsFromSnapshotsIfNeeded()
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

    func addTodoTask() {
        let trimmedTitle = todoInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        todoTasks.insert(TodoTask(title: trimmedTitle, createdAt: Date(), priority: todoPriorityInput), at: 0)
        todoInput = ""
        persistTodoTasks()
    }

    func toggleTodoTask(_ task: TodoTask) {
        guard let index = todoTasks.firstIndex(where: { $0.id == task.id }) else { return }

        todoTasks[index].completedAt = todoTasks[index].isCompleted ? nil : Date()
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

    func persistTodoTasks() {
        if let encodedTasks = try? JSONEncoder().encode(todoTasks) {
            todoTasksData = encodedTasks
            cloudStore.set(encodedTasks, forKey: todoTasksCloudKey)
            flushToICloud()
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
            insertWishlistItem(title: trimmedTitle, categoryID: categoryID)
        } else {
            isShowingWishlistCategoryPicker = true
        }
    }

    func insertWishlistItem(title: String, categoryID: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        wishlistItems.insert(
            WishlistItem(title: trimmedTitle, categoryID: categoryID, createdAt: Date()),
            at: 0
        )
        wishlistCategoryID = categoryID
        wishlistInput = ""
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

    func updateWishlistItem(_ item: WishlistItem, title: String, categoryID: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = wishlistItems.firstIndex(where: { $0.id == item.id }) else { return }

        wishlistItems[index].title = trimmed
        wishlistItems[index].categoryID = categoryID
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

    func addFinanceAsset() {
        let trimmedAmount = financeAssetAmountInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = trimmedAmount.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalizedAmount) else { return }

        let trimmedName = financeAssetNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let assetName = trimmedName.isEmpty ? financeAssetKind.title : trimmedName
        let trimmedNote = financeAssetNoteInput.trimmingCharacters(in: .whitespacesAndNewlines)

        financeAssets.insert(
            FinanceAsset(name: assetName, kind: financeAssetKind, amount: amount, updatedAt: Date(), note: trimmedNote),
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

        if let cloudTodoTasksData = cloudStore.data(forKey: todoTasksCloudKey),
           let cloudTodoTasks = try? JSONDecoder().decode([TodoTask].self, from: cloudTodoTasksData) {
            mergeTodoTasks(cloudTodoTasks)
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
            healthSectionPrefs = prefs.normalized
            healthSectionPreferencesData = (try? JSONEncoder().encode(healthSectionPrefs)) ?? healthSectionPreferencesData
        }

        if let data = cloudStore.data(forKey: memoSectionPreferencesCloudKey),
           let prefs = try? JSONDecoder().decode(SectionPreferences<MemoSection>.self, from: data) {
            memoSectionPrefs = prefs.normalized
            memoSectionPreferencesData = (try? JSONEncoder().encode(memoSectionPrefs)) ?? memoSectionPreferencesData
        }

        if let data = cloudStore.data(forKey: financeSectionPreferencesCloudKey),
           let prefs = try? JSONDecoder().decode(SectionPreferences<FinanceSection>.self, from: data) {
            financeSectionPrefs = prefs.normalized
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

        if let encodedTodoTasks = try? JSONEncoder().encode(todoTasks) {
            cloudStore.set(encodedTodoTasks, forKey: todoTasksCloudKey)
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
        if !isICloudAvailable {
            return "未连接，无法同步"
        }
        if isSyncing {
            return "正在同步…"
        }
        if lastICloudSyncAt > 0 {
            let date = Date(timeIntervalSince1970: lastICloudSyncAt)
            return "上次同步 \(relativeTimeText(for: date))"
        }
        return "等待首次同步"
    }

    /// 用户手动点击「立即同步」：先推送本地数据，再回拉云端，并更新可见状态。
    func syncNow() {
        guard isICloudAvailable else {
            syncStatus = "未登录 iCloud，无法同步"
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

    func mergeWishlistItems(_ cloudItems: [WishlistItem]) {
        var mergedItemsByID = Dictionary(uniqueKeysWithValues: wishlistItems.map { ($0.id, $0) })

        for item in cloudItems {
            mergedItemsByID[item.id] = item
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
            mergedItemsByID[item.id] = item
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
