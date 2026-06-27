import LocalAuthentication
import SwiftUI

extension ContentView {
    var financePrivacyPasswordValue: String {
        let trimmed = financePrivacyPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "111111" : trimmed
    }

    var isFinanceAssetRecordVisible: Bool {
        if isFinanceAssetTemporarilyHidden {
            return false
        }
        return isFinanceAssetDefaultHidden ? isFinanceAssetPrivacyUnlocked : true
    }

    var financePrivacyUnlockTitle: String {
        guard let pendingFinanceAssetDefaultHidden else {
            return "查看资产"
        }
        return pendingFinanceAssetDefaultHidden ? "开启默认隐藏" : "关闭默认隐藏"
    }

    var financePrivacyUnlockSubtitle: String {
        guard let pendingFinanceAssetDefaultHidden else {
            return "输入安全密码后显示真实资产金额。"
        }
        return pendingFinanceAssetDefaultHidden
            ? "输入安全密码后开启默认隐藏资产记录。"
            : "输入安全密码后关闭默认隐藏资产记录。"
    }

    var financePrivacyUnlockActionTitle: String {
        guard let pendingFinanceAssetDefaultHidden else {
            return "查看"
        }
        return pendingFinanceAssetDefaultHidden ? "开启" : "关闭"
    }

    var financeBiometricTypeText: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "生物识别"
        }

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "生物识别"
        }
    }

    var canUseFinanceBiometrics: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func maskedFinanceAmount(_ amount: Double) -> String {
        isFinanceAssetRecordVisible ? currencyText(amount) : "***"
    }

    func maskedFinanceText(_ text: String?) -> String {
        isFinanceAssetRecordVisible ? (text ?? "--") : "***"
    }

    func handleFinanceAssetPrivacyTap() {
        if isFinanceAssetRecordVisible {
            isFinanceAssetPrivacyUnlocked = false
            isFinanceAssetTemporarilyHidden = true
            resetFinancePrivacyUnlockInput()
        } else if !isFinanceAssetDefaultHidden {
            isFinanceAssetTemporarilyHidden = false
        } else {
            requestFinancePrivacyUnlock()
        }
    }

    func requestFinancePrivacyUnlock() {
        guard canUseFinanceBiometrics else {
            showFinancePrivacyPasswordUnlock()
            return
        }

        authenticateFinanceBiometrics(reason: "验证后查看理财资产记录里的真实数字") {
            isFinanceAssetPrivacyUnlocked = true
            isFinanceAssetTemporarilyHidden = false
            resetFinancePrivacyUnlockInput()
            isShowingFinancePrivacyUnlockSheet = false
        } onFailure: {
            showFinancePrivacyPasswordUnlock()
        }
    }

    func showFinancePrivacyPasswordUnlock() {
        resetFinancePrivacyUnlockInput()
        isShowingFinancePrivacyUnlockSheet = true
    }

    func authenticateFinanceBiometrics(reason: String, onSuccess: @escaping () -> Void, onFailure: (() -> Void)? = nil) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            onFailure?()
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                if success {
                    onSuccess()
                } else {
                    onFailure?()
                }
            }
        }
    }

    func submitFinancePrivacyUnlock() {
        if financePrivacyUnlockInput == financePrivacyPasswordValue {
            if isFinancePrivacyUnlockingDefaultHidden, let pendingFinanceAssetDefaultHidden {
                applyFinanceAssetDefaultHidden(pendingFinanceAssetDefaultHidden)
            } else {
                isFinanceAssetPrivacyUnlocked = true
                isFinanceAssetTemporarilyHidden = false
            }
            resetFinancePrivacyUnlockInput()
            isFinancePrivacyUnlockingDefaultHidden = false
            pendingFinanceAssetDefaultHidden = nil
            isShowingFinancePrivacyUnlockSheet = false
        } else {
            financePrivacyUnlockError = "密码不正确，请重新输入"
            financePrivacyUnlockInput = ""
        }
    }

    func resetFinancePrivacyUnlockInput() {
        financePrivacyUnlockInput = ""
        financePrivacyUnlockError = nil
    }

    func saveFinancePrivacyPassword(_ password: String) {
        financePrivacyPassword = password
        isFinanceAssetPrivacyUnlocked = false
        isFinanceAssetTemporarilyHidden = false
        financeSecurityCurrentPasswordInput = ""
        financeSecurityPasswordInput = ""
        financeSecurityPasswordConfirmInput = ""
        financeSecurityPasswordMessage = isFinanceAssetDefaultHidden ? "密码已更新，资产记录已重新锁定" : "密码已更新"
    }

    func updateFinanceAssetDefaultHidden(_ isHidden: Bool) {
        resetFinancePrivacyUnlockInput()
        pendingFinanceAssetDefaultHidden = isHidden
        isFinancePrivacyUnlockingDefaultHidden = true

        guard canUseFinanceBiometrics else {
            isShowingFinancePrivacyUnlockSheet = true
            return
        }

        authenticateFinanceBiometrics(reason: "验证后修改资产记录默认隐藏设置") {
            applyFinanceAssetDefaultHidden(isHidden)
            isFinancePrivacyUnlockingDefaultHidden = false
            pendingFinanceAssetDefaultHidden = nil
        } onFailure: {
            isShowingFinancePrivacyUnlockSheet = true
        }
    }

    func applyFinanceAssetDefaultHidden(_ isHidden: Bool) {
        isFinanceAssetDefaultHidden = isHidden
        isFinanceAssetPrivacyUnlocked = false
        isFinanceAssetTemporarilyHidden = false
        financeSecurityPasswordMessage = isHidden ? "已开启默认隐藏，资产记录已锁定" : "已关闭默认隐藏，资产记录将直接显示"
    }

    var financeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("总资产")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(maskedFinanceAmount(totalFinanceAmount))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                Spacer()

                financeAssetPrivacyButton
            }

            HStack(spacing: 12) {
                financeHeroStat(title: "资产项", value: isFinanceAssetRecordVisible ? "\(financeAssets.count)" : "***")
                Divider().frame(height: 30).overlay(Color.white.opacity(0.25))
                financeHeroStat(title: "历史记录", value: isFinanceAssetRecordVisible ? "\(financeSnapshots.count)" : "***")
                Divider().frame(height: 30).overlay(Color.white.opacity(0.25))
                financeHeroStat(title: "本月变化", value: maskedFinanceText(financeMonthChangeText))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [Color.blue, Color.indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.blue.opacity(0.25), radius: 16, y: 8)
    }

    func financeHeroStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var financeAddAssetSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        financeFieldLabel("资产类型")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FinanceAssetKind.allCases) { kind in
                                    financeKindChip(kind)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        financeFieldLabel("名称")
                        ModernInputField(
                            placeholder: financeAssetKind == .custom ? "自定义类目名称" : "资产名称",
                            text: $financeAssetNameInput,
                            icon: financeAssetKind.icon,
                            tint: financeKindTint(financeAssetKind)
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        financeFieldLabel("金额")
                        ModernInputField(
                            placeholder: "资产金额",
                            text: $financeAssetAmountInput,
                            icon: "yensign.circle",
                            tint: financeKindTint(financeAssetKind),
                            keyboardType: .decimalPad
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        financeFieldLabel("备注")
                        ZStack(alignment: .topLeading) {
                            if financeAssetNoteInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("可选，记一下这笔资产的详细信息")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 14)
                            }

                            TextEditor(text: $financeAssetNoteInput)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 88)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingFinanceAssetSheet = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addFinanceAsset()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(financeKindTint(financeAssetKind))
                    .disabled(financeAssetAmountInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    func financeFieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }

    func financeKindChip(_ kind: FinanceAssetKind) -> some View {
        let isSelected = financeAssetKind == kind
        let tint = financeKindTint(kind)

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                financeAssetKind = kind
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: kind.icon)
                    .font(.subheadline)

                Text(kind.title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.12)),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    func financeKindTint(_ kind: FinanceAssetKind) -> Color {
        switch kind {
        case .bankCard:
            return .blue
        case .providentFund:
            return .indigo
        case .stock:
            return .green
        case .option:
            return .orange
        case .alipay:
            return .cyan
        case .wechat:
            return .mint
        case .custom:
            return .purple
        }
    }

    var financeTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("资产趋势")
                        .font(.title3.bold())
                }

                Spacer()

                if isFinanceAssetRecordVisible, let financeMonthChangeText {
                    Text(financeMonthChangeText)
                        .font(.caption.bold())
                        .foregroundStyle(financeMonthChangeText.hasPrefix("-") ? .red : .blue)
                } else if !isFinanceAssetRecordVisible {
                    Text("***")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }

            if !isFinanceAssetRecordVisible {
                financePrivacyPlaceholder(title: "趋势已隐藏", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity, minHeight: 130)
            } else if !monthlyFinanceTrendPoints.isEmpty {
                FinanceTrendView(points: monthlyFinanceTrendPoints, amountText: currencyText)
            } else {
                AppEmptyState(
                    title: "还没有趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: "保存资产记录后，会显示月度变化。"
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var financeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Text("资产分布")
                    .font(.title3.bold())

                Spacer()

                Menu {
                    ForEach(FinanceDistributionGrouping.allCases) { option in
                        Button {
                            financeDistributionGrouping = option
                        } label: {
                            if option == financeDistributionGrouping {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(financeDistributionGrouping.title)
                            .lineLimit(1)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color(.separator).opacity(0.10), lineWidth: 1)
                    }
                }
            }

            if !isFinanceAssetRecordVisible {
                financePrivacyPlaceholder(title: "分布已隐藏", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity, minHeight: 130)
            } else if financeDistributionPoints.isEmpty {
                AppEmptyState(
                    title: "还没有分布",
                    systemImage: "chart.pie",
                    description: financeDistributionGrouping == .kind
                        ? "添加资产后，会显示各类资产占比。"
                        : "添加资产后，会显示各资产名称占比。"
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                FinanceDistributionView(
                    points: financeDistributionPoints,
                    amountText: currencyText
                )
                .id(financeDistributionGrouping)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var financeAssetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("资产明细")
                        .font(.title3.bold())
                    Text(isFinanceAssetRecordVisible ? "\(financeAssets.count) 项" : "*** 项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    if isFinanceAssetRecordVisible {
                        isShowingFinanceAssetSheet = true
                    } else {
                        handleFinanceAssetPrivacyTap()
                    }
                } label: {
                    AppIconCircleButton(
                        icon: isFinanceAssetRecordVisible ? "plus" : "lock.fill",
                        tint: isFinanceAssetRecordVisible ? .blue : .secondary,
                        size: 32,
                        iconFont: .subheadline.weight(.bold)
                    )
                }
                .buttonStyle(.plain)
            }

            if financeAssets.isEmpty {
                AppEmptyState(
                    title: "还没有资产",
                    systemImage: "yensign.circle",
                    description: "先添加银行卡、股票、期权、支付宝、微信或自定义资产。"
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedFinanceAssets) { asset in
                        FinanceAssetRow(
                            asset: asset,
                            amountText: maskedFinanceAmount(asset.amount),
                            updatedText: isFinanceAssetRecordVisible ? chineseDateTime(asset.updatedAt) : "***",
                            tint: financeKindTint(asset.kind),
                            isPrivacyLocked: !isFinanceAssetRecordVisible,
                            onEdit: {
                                if isFinanceAssetRecordVisible {
                                    editingFinanceAsset = asset
                                } else {
                                    handleFinanceAssetPrivacyTap()
                                }
                            },
                            onDelete: {
                                if isFinanceAssetRecordVisible {
                                    deleteFinanceAsset(asset)
                                }
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

    var expenseBookSection: some View {
        VStack(spacing: 20) {
            expenseSummaryCard
            expenseTrendCard
            expenseRecordsCard
        }
    }

    var expenseSummaryCard: some View {
        HStack(spacing: 10) {
            SummaryPill(title: "今日", value: fullCurrencyText(expenseTodayTotal), color: .teal)
            SummaryPill(title: "本月", value: fullCurrencyText(expenseMonthTotal), color: .cyan)
            SummaryPill(title: "本年", value: fullCurrencyText(expenseYearTotal), color: .blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var expenseTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("支出趋势")
                    .font(.title3.bold())

                Spacer()
            }

            AppSegmentedControl(
                options: WeightTrendGranularity.allCases,
                selection: $expenseTrendGranularity,
                title: \.title,
                compact: true
            )

            if expenseRecords.isEmpty {
                AppEmptyState(
                    title: "还没有支出趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: "录入支出后，会自动生成每日、每周、每月趋势。"
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ExpenseTrendView(
                    points: expenseTrendPoints,
                    amountText: currencyText,
                    granularity: expenseTrendGranularity
                )
                .frame(height: 220)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var expenseRecordsCard: some View {
        let recentMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let recentCount = expenseRecords.filter { $0.date >= recentMonthDate }.count

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("支出明细")
                    .font(.title3.bold())

                Spacer()
                
                Text("最近一个月支出 \(recentCount) 笔")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if expenseRecords.isEmpty {
                AppEmptyState(
                    title: "还没有记账",
                    systemImage: "list.bullet.clipboard",
                    description: "先记录一笔支出，住房、交通、吃饭这些分类都已经准备好了。"
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedExpenseRecords) { record in
                        ExpenseRecordRow(
                            record: record,
                            category: expenseCategory(for: record),
                            amountText: currencyText(record.amount),
                            dateText: chineseDateTime(record.date),
                            weekdayText: chineseWeekday(record.date),
                            tint: expenseCategoryTint(expenseCategory(for: record)),
                            onOpen: {
                                editingExpenseRecord = record
                            },
                            onDelete: {
                                deleteExpenseRecord(record)
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

    func expenseRecordEditorSheet(record: ExpenseRecord? = nil) -> some View {
        ExpenseRecordEditorSheet(
            record: record,
            categories: sortedExpenseCategories,
            selectedTint: expenseCategoryTint(expenseCategory(for: record ?? ExpenseRecord(
                amount: 0,
                categoryID: sortedExpenseCategories.first?.id ?? ExpenseCategory.fallback.id,
                date: Date(),
                createdAt: Date()
            ))),
            onCancel: {
                editingExpenseRecord = nil
                isShowingExpenseRecordSheet = false
            },
            onAddCategory: { title in
                upsertExpenseCategory(title: title)
            },
            onSave: { amount, categoryID, date, note in
                if let record {
                    updateExpenseRecord(record, amount: amount, categoryID: categoryID, date: date, note: note)
                    editingExpenseRecord = nil
                } else {
                    addExpenseRecord(amount: amount, categoryID: categoryID, date: date, note: note)
                }
            }
        )
        .presentationDetents([.large])
    }

    func expenseCategoryTint(_ category: ExpenseCategory) -> Color {
        switch category.id {
        case "housing":
            return .indigo
        case "transport":
            return .blue
        case "food":
            return .orange
        case "clothing":
            return .pink
        case "phone":
            return .mint
        case "travel":
            return .cyan
        case "fun":
            return .purple
        default:
            return .teal
        }
    }

    var financeAssetPrivacyButton: some View {
        Button {
            handleFinanceAssetPrivacyTap()
        } label: {
            Image(systemName: isFinanceAssetRecordVisible ? "eye" : "eye.slash")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.20), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFinanceAssetRecordVisible ? "隐藏资产金额" : "查看资产金额")
    }

    func financePrivacyPlaceholder(title: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("***")
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }
    }

    var stockResearchListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                SearchInputBar(placeholder: "搜索股票名称", text: $stockSearchText)
                    .frame(maxWidth: .infinity)

                if !stockResearchItems.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            isShowingStockFilterPanel.toggle()
                        }
                    } label: {
                        StockResearchFilterToggleButton(
                            activeCount: stockResearchFilterActiveCount,
                            isExpanded: isShowingStockFilterPanel
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if !stockResearchItems.isEmpty && isShowingStockFilterPanel {
                stockResearchFilterBar
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if stockResearchItems.isEmpty {
                AppEmptyState(
                    title: "还没有股票研究",
                    systemImage: "doc.text.magnifyingglass",
                    description: "先添加一只股票，再记录你的理解。"
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else if filteredStockResearchItems.isEmpty {
                AppEmptyState(
                    title: "没有匹配结果",
                    systemImage: "magnifyingglass",
                    description: "换个关键词或调整筛选条件试试看。"
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredStockResearchItems) { item in
                        StockResearchRow(
                            item: item,
                            updatedText: chineseDateTime(item.updatedAt),
                            onOpen: {
                                editingStockResearchItem = item
                            },
                            onDelete: {
                                deleteStockResearchItem(item)
                            },
                            onTogglePin: {
                                toggleStockResearchPinned(item)
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

    var stockResearchFilterActiveCount: Int {
        [stockCertaintyFilter, stockGrowthFilter, stockAttentionFilter].compactMap { $0 }.count
    }

    var stockResearchFilterBar: some View {
        StockResearchFilterPanel(
            certainty: $stockCertaintyFilter,
            growth: $stockGrowthFilter,
            attention: $stockAttentionFilter
        )
    }
}

struct StockResearchFilterPanel: View {
    @Binding var certainty: StockRating?
    @Binding var growth: StockRating?
    @Binding var attention: StockRating?

    private var activeCount: Int {
        [certainty, growth, attention].compactMap { $0 }.count
    }

    var body: some View {
        VStack(spacing: 8) {
            StockRatingFilterRow(title: "确定性", tint: .green, selection: $certainty)
            StockRatingFilterRow(title: "成长性", tint: .orange, selection: $growth)
            StockRatingFilterRow(title: "关注度", tint: .blue, selection: $attention)

            if activeCount > 0 {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        certainty = nil
                        growth = nil
                        attention = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("重置筛选")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemFill), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

struct StockResearchFilterToggleButton: View {
    let activeCount: Int
    let isExpanded: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "slider.horizontal.3")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(activeCount > 0 ? .blue : .secondary)
                .frame(width: 46, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            (isExpanded ? Color.blue : Color(.separator)).opacity(isExpanded ? 0.18 : 0.12),
                            lineWidth: 1
                        )
                }

            if activeCount > 0 {
                Text("\(activeCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.blue, in: Capsule())
                    .offset(x: 6, y: -4)
            }
        }
        .contentShape(Rectangle())
    }
}

struct StockRatingFilterRow: View {
    let title: String
    let tint: Color
    @Binding var selection: StockRating?

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selection == nil ? .secondary : tint)
                .frame(width: 52, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(StockRating.allCases) { rating in
                    let isSelected = selection == rating
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            selection = isSelected ? nil : rating
                        }
                    } label: {
                        Text(rating.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : Color.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(Color(.quaternarySystemFill)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ExpenseRecordRow: View {
    let record: ExpenseRecord
    let category: ExpenseCategory
    let amountText: String
    let dateText: String
    let weekdayText: String
    let tint: Color
    let onOpen: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(category.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(weekdayText)
                            .font(.caption.bold())
                            .foregroundStyle(tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.10), in: Capsule())
                    }

                    Text(dateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("-\(amountText)")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .longPressDelete(
            DeleteConfirmationContent(
                title: "删除这笔支出？",
                message: "这条支出记录会被永久删除。",
                confirmTitle: "删除"
            ),
            onDelete: onDelete
        )
    }
}

struct ExpenseRecordEditorSheet: View {
    let record: ExpenseRecord?
    let categories: [ExpenseCategory]
    let selectedTint: Color
    let onCancel: () -> Void
    let onAddCategory: (String) -> ExpenseCategory?
    let onSave: (Double, String, Date, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountInput: String
    @State private var selectedCategoryID: String
    @State private var selectedDate: Date
    @State private var noteInput: String
    @State private var customCategoryInput = ""
    @State private var isShowingCustomCategoryInput = false
    @State private var isShowingDatePicker = false

    init(
        record: ExpenseRecord? = nil,
        categories: [ExpenseCategory],
        selectedTint: Color,
        onCancel: @escaping () -> Void,
        onAddCategory: @escaping (String) -> ExpenseCategory?,
        onSave: @escaping (Double, String, Date, String) -> Void
    ) {
        self.record = record
        self.categories = categories
        self.selectedTint = selectedTint
        self.onCancel = onCancel
        self.onAddCategory = onAddCategory
        self.onSave = onSave
        _amountInput = State(initialValue: record.map { String(format: "%.0f", $0.amount) } ?? "")
        _selectedCategoryID = State(initialValue: record?.categoryID ?? categories.first?.id ?? ExpenseCategory.fallback.id)
        _selectedDate = State(initialValue: record?.date ?? Date())
        _noteInput = State(initialValue: record?.note ?? "")
    }

    var selectedCategory: ExpenseCategory {
        categories.first(where: { $0.id == selectedCategoryID }) ?? ExpenseCategory.fallback
    }

    var tint: Color {
        .blue
    }

    var chipBackgroundColor: Color {
        Color(.secondarySystemGroupedBackground)
    }

    var chipBorderColor: Color {
        Color(.separator).opacity(0.08)
    }

    var normalizedAmount: Double? {
        let trimmed = amountInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    var canSave: Bool {
        guard let normalizedAmount else { return false }
        return normalizedAmount > 0 && !selectedCategoryID.isEmpty
    }

    var selectedDateButtonText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = mondayFirstCalendar
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: selectedDate)
    }

    var quickDateOptions: [(title: String, date: Date)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [
            ("今天", today),
            ("昨天", calendar.date(byAdding: .day, value: -1, to: today) ?? today),
            ("前天", calendar.date(byAdding: .day, value: -2, to: today) ?? today)
        ]
    }

    var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("支出金额")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ModernInputField(
                            placeholder: "支出金额",
                            text: $amountInput,
                            icon: "yensign.circle.fill",
                            tint: .blue,
                            keyboardType: .decimalPad
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("支出说明")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ZStack(alignment: .topLeading) {
                            if noteInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("可选，记一下这笔支出花在了什么地方")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 14)
                            }

                            TextEditor(text: $noteInput)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 88)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("支出分类")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories) { category in
                                    let isSelected = selectedCategoryID == category.id
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                            selectedCategoryID = category.id
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: category.icon)
                                                .font(.footnote.weight(.semibold))
                                            Text(category.title)
                                                .font(.footnote.weight(.medium))
                                        }
                                        .foregroundStyle(isSelected ? .white : .primary.opacity(0.82))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(chipBackgroundColor),
                                            in: Capsule()
                                        )
                                        .overlay {
                                            Capsule()
                                                .stroke(isSelected ? tint.opacity(0.16) : chipBorderColor, lineWidth: 1)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                        isShowingCustomCategoryInput.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.footnote.weight(.semibold))
                                        Text("自定义")
                                            .font(.footnote.weight(.medium))
                                    }
                                    .foregroundStyle(isShowingCustomCategoryInput ? .white : .primary.opacity(0.82))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        isShowingCustomCategoryInput ? AnyShapeStyle(tint) : AnyShapeStyle(chipBackgroundColor),
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(isShowingCustomCategoryInput ? tint.opacity(0.16) : chipBorderColor, lineWidth: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }

                        if isShowingCustomCategoryInput {
                            HStack(spacing: 10) {
                                ModernInputField(
                                    placeholder: "新增自定义分类",
                                    text: $customCategoryInput,
                                    icon: "tag.fill",
                                    tint: tint
                                )

                                Button("添加") {
                                    guard let newCategory = onAddCategory(customCategoryInput) else { return }
                                    selectedCategoryID = newCategory.id
                                    customCategoryInput = ""
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                        isShowingCustomCategoryInput = false
                                    }
                                }
                                .buttonStyle(AppSecondaryButtonStyle(tint: tint))
                                .disabled(customCategoryInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("支出日期")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(quickDateOptions.indices, id: \.self) { index in
                                let option = quickDateOptions[index]
                                let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: option.date)

                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                        selectedDate = option.date
                                    }
                                } label: {
                                    Text(option.title)
                                        .font(.footnote.weight(.medium))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .foregroundStyle(isSelected ? .white : .secondary)
                                        .frame(minWidth: 28)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(chipBackgroundColor),
                                            in: Capsule()
                                        )
                                        .overlay {
                                            Capsule()
                                                .stroke(isSelected ? tint.opacity(0.16) : chipBorderColor, lineWidth: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer(minLength: 8)

                            Button {
                                isShowingDatePicker = true
                            } label: {
                                HStack(spacing: 5) {
                                    Text(selectedDateButtonText)
                                        .font(.footnote.weight(.medium))
                                        .lineLimit(1)

                                    Image(systemName: "chevron.down")
                                        .font(.caption2.bold())
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(chipBackgroundColor, in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(chipBorderColor, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $isShowingDatePicker, arrowEdge: .bottom) {
                                DatePicker(
                                    "",
                                    selection: $selectedDate,
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                .datePickerStyle(.graphical)
                                .environment(\.locale, Locale(identifier: "zh_CN"))
                                .environment(\.calendar, mondayFirstCalendar)
                                .padding(16)
                                .frame(width: 320)
                                .presentationCompactAdaptation(.popover)
                                .onChange(of: selectedDate) { _, _ in
                                    isShowingDatePicker = false
                                }
                            }
                        }
                    }

                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(record == nil ? "记一笔支出" : "编辑支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(record == nil ? "保存" : "更新") {
                        guard let normalizedAmount else { return }
                        onSave(normalizedAmount, selectedCategoryID, selectedDate, noteInput)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
                    .disabled(!canSave)
                }
            }
        }
    }

    func tintForCategory(_ category: ExpenseCategory) -> Color {
        tint
    }
}
