import SwiftUI

enum CalculatorOperation: String {
    case add = "+"
    case subtract = "-"
    case multiply = "×"
    case divide = "÷"
}

struct CalculatorHistoryItem: Identifiable, Equatable, Codable {
    var id: UUID
    var expression: String
    var result: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, expression, result, createdAt
    }

    init(
        id: UUID = UUID(),
        expression: String,
        result: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.expression = expression
        self.result = result
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        expression = try container.decode(String.self, forKey: .expression)
        result = try container.decode(String.self, forKey: .result)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

enum CalculatorButtonKind {
    case number
    case utility
    case destructive
    case operation
    case equals
}

struct CalculatorKeyButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color
    let pressedBackground: Color
    let pressedForeground: Color
    var borderColor: Color = .clear
    var shadowColor: Color = .clear
    var forcePressed: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed || forcePressed
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        configuration.label
            .foregroundStyle(isPressed ? pressedForeground : foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                shape
                    .fill(isPressed ? pressedBackground : background)
            )
            .overlay {
                shape
                    .fill(.black.opacity(isPressed ? 0.04 : 0))
            }
            .overlay {
                shape
                    .fill(.white.opacity(isPressed ? 0 : 0.06))
            }
            .overlay {
                shape
                    .stroke(borderColor.opacity(isPressed ? 0.4 : 1), lineWidth: borderColor == .clear ? 0 : 1)
            }
            .overlay {
                shape
                    .stroke(.white.opacity(isPressed ? 0.08 : 0.24), lineWidth: 0.8)
                    .blur(radius: isPressed ? 0 : 0.2)
                    .mask(shape)
            }
            .shadow(color: shadowColor.opacity(isPressed ? 0.01 : 0.2), radius: isPressed ? 0.8 : 10, y: isPressed ? 0 : 5)
            .shadow(color: .black.opacity(isPressed ? 0.12 : 0), radius: isPressed ? 1.2 : 0, y: isPressed ? 0.6 : 0)
            .scaleEffect(isPressed ? 0.88 : 1)
            .offset(y: isPressed ? 2.8 : 0)
            .saturation(isPressed ? 1.08 : 1)
            .animation(.spring(response: 0.12, dampingFraction: 0.62), value: isPressed)
    }
}

extension ContentView {
    var healthPage: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if visibleHealthSections.count > 1 {
                    healthSectionPicker
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 14)
                }

                TabView(selection: $healthSection) {
                    ForEach(visibleHealthSections) { section in
                        sectionScroll { healthSectionContent(section) }
                            .tag(section)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, visibleHealthSections.count > 1 ? 0 : 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("健康")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: healthSection) { _, newSection in
                if newSection != .weight {
                    visibleWeightHistoryDays = 10
                }
            }
        }
    }

    @ViewBuilder
    func healthSectionContent(_ section: HealthSection) -> some View {
        switch section {
        case .fasting:
            fastingSection
        case .weight:
            weightSection
        }
    }

    @ViewBuilder
    func sectionScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
                .padding(.horizontal)
                .padding(.bottom)
        }
    }

    var healthSectionPicker: some View {
        AppUnderlineTabs(
            options: visibleHealthSections,
            selection: $healthSection,
            title: \.title
        )
    }

    var fastingSection: some View {
        VStack(spacing: 20) {
            statusCard
            actionCard
        }
    }

    var weightSection: some View {
        VStack(spacing: 20) {
            weightOverviewCard
            trendCard
            historyCard
        }
    }

    var memoPage: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if visibleMemoSections.count > 1 {
                    memoSectionPicker
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 14)
                }

                TabView(selection: $memoSection) {
                    ForEach(visibleMemoSections) { section in
                        sectionScroll { memoSectionContent(section) }
                            .tag(section)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, visibleMemoSections.count > 1 ? 0 : 8)
                .overlay(alignment: .bottomTrailing) {
                    if memoSection != .calendar {
                        Button {
                            switch memoSection {
                            case .todo:
                                todoAddInitialPriority = todoFilter ?? .notImportantNotUrgent
                                isShowingTodoAddSheet = true
                            case .note:
                                isShowingNoteAddSheet = true
                            case .wishlist:
                                wishlistInput = ""
                                if let categoryID = wishlistFilter.categoryID {
                                    wishlistCategoryID = categoryID
                                }
                                isShowingWishlistAddSheet = true
                            case .anniversary:
                                isShowingAnniversarySheet = true
                            case .calendar:
                                break
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.blue, in: Circle())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("备忘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    func memoSectionContent(_ section: MemoSection) -> some View {
        switch section {
        case .todo:
            todoTasksCard
        case .note:
            memoNotesCard
        case .wishlist:
            wishlistCard
        case .anniversary:
            anniversaryCard
        case .calendar:
            memoCalendarSection
        }
    }

    var memoSectionPicker: some View {
        AppUnderlineTabs(
            options: visibleMemoSections,
            selection: $memoSection,
            title: \.title,
            spacing: 14
        )
    }

    var financePage: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if visibleFinanceSections.count > 1 {
                    financeSectionPicker
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 14)
                }

                TabView(selection: $financeSection) {
                    ForEach(visibleFinanceSections) { section in
                        sectionScroll { financeSectionContent(section) }
                            .tag(section)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, visibleFinanceSections.count > 1 ? 0 : 8)
                .overlay(alignment: .bottomTrailing) {
                    if financeSection == .stockResearch {
                        Button {
                            stockNameInput = ""
                            isShowingStockAddAlert = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.blue, in: Circle())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("理财")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    func financeSectionContent(_ section: FinanceSection) -> some View {
        switch section {
        case .assetRecord:
            financeAssetRecordSection
        case .expenseBook:
            expenseBookSection
        case .stockResearch:
            stockResearchSection
        }
    }

    var financeSectionPicker: some View {
        AppUnderlineTabs(
            options: visibleFinanceSections,
            selection: $financeSection,
            title: \.title
        )
    }

    @ViewBuilder
    var sectionManagementSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(healthSectionPrefs.order) { section in
                        sectionManageRow(
                            icon: section.icon,
                            title: section.title,
                            tint: profileTabTint(.health),
                            isOnlyVisible: isOnlyVisibleHealthSection(section),
                            visibility: healthSectionVisibilityBinding(for: section)
                        )
                    }
                    .onMove(perform: moveHealthSections)
                } header: {
                    Text("健康")
                }

                Section {
                    ForEach(memoSectionPrefs.order) { section in
                        sectionManageRow(
                            icon: section.icon,
                            title: section.title,
                            tint: profileTabTint(.todo),
                            isOnlyVisible: isOnlyVisibleMemoSection(section),
                            visibility: memoSectionVisibilityBinding(for: section)
                        )
                    }
                    .onMove(perform: moveMemoSections)
                } header: {
                    Text("备忘")
                }

                Section {
                    ForEach(financeSectionPrefs.order) { section in
                        sectionManageRow(
                            icon: section.icon,
                            title: section.title,
                            tint: profileTabTint(.finance),
                            isOnlyVisible: isOnlyVisibleFinanceSection(section),
                            visibility: financeSectionVisibilityBinding(for: section)
                        )
                    }
                    .onMove(perform: moveFinanceSections)
                } header: {
                    Text("理财")
                } footer: {
                    Text("拖动调整顺序，关闭开关可隐藏模块，每个分类至少保留一个。")
                }

                Section {
                    Button(role: .destructive) {
                        withAnimation {
                            resetSectionPreferences()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("重置为默认", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("模块管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isShowingSectionManagement = false }
                        .font(.subheadline)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { isShowingSectionManagement = false }
                        .font(.subheadline.bold())
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    func sectionManageRow(
        icon: String,
        title: String,
        tint: Color,
        isOnlyVisible: Bool,
        visibility: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 8)

            Toggle("", isOn: visibility)
                .labelsHidden()
                .disabled(isOnlyVisible)
        }
        .padding(.vertical, 4)
    }

    var financeAssetRecordSection: some View {
        VStack(spacing: 20) {
            financeSummaryCard
            financeDistributionCard
            financeTrendCard
            financeAssetsCard
        }
    }

    var stockResearchSection: some View {
        VStack(spacing: 20) {
            stockResearchListCard
        }
    }

    var profilePage: some View {
        NavigationStack {
            List {
                profileSectionTitleRow("天气")

                weatherCard
                    .profileCardRow()

                profileSectionTitleRow("小工具")

                calculatorRow
                    .profileCardRow()

                exchangeRateRow
                    .profileCardRow()

                profileSectionTitleRow("功能管理") {
                    if isEditingTabs {
                        HStack(spacing: 8) {
                            Button {
                                cancelTabEditMode()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, height: 30)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button {
                                commitTabEditMode()
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.blue)
                                    .frame(width: 30, height: 30)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Button {
                                isShowingSectionManagement = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, height: 30)
                                    .background(Color(.secondarySystemFill).opacity(0.55))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .stroke(Color(.separator).opacity(0.08), lineWidth: 1)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button {
                                beginTabEditMode()
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, height: 30)
                                    .background(Color(.secondarySystemFill).opacity(0.55))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .stroke(Color(.separator).opacity(0.08), lineWidth: 1)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ForEach(mainTabOrder) { tab in
                    profileTabCard(tab)
                        .profileCardRow()
                }
                .onMove(perform: moveMainTabs)

                profileSectionTitleRow("外观")

                appearanceRow
                    .profileCardRow()

                profileSectionTitleRow("安全")

                securitySettingsRow
                    .profileCardRow()

                profileSectionTitleRow("通知")

                notificationSettingsRow
                    .profileCardRow()

                profileSectionTitleRow("数据同步")

                syncCard
                    .profileCardRow()

                profileSectionNoteRow("数据保存在本地，并在 iCloud 可用时同步。", topInset: 0)
            }
            .listStyle(.plain)
            .refreshable {
                weatherStore.refresh()
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if case .idle = weatherStore.state {
                    weatherStore.refresh()
                }
            }
            .onChange(of: selectedTabID) { oldValue, newValue in
                guard oldValue == "profile", newValue != "profile" else { return }
                profileNavigationResetID = UUID()
            }
        }
        .id(profileNavigationResetID)
    }

    @ViewBuilder
    var weatherCard: some View {
        HStack(spacing: 12) {
            switch weatherStore.state {
            case .loaded(let info):
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: weatherGradient(for: info.weatherCode),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: info.symbolName)
                        .font(.system(size: 26))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.cityName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(alignment: .center, spacing: 6) {
                        Text(info.temperatureText)
                            .font(.system(size: 30, weight: .bold))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .fixedSize(horizontal: true, vertical: false)

                        Text(info.conditionText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    weatherMetricRow(title: "体感", value: "\(Int(info.apparentTemperature.rounded()))°")
                    weatherMetricRow(title: "湿度", value: "\(info.humidity)%")
                    weatherMetricRow(title: "风速", value: "\(Int(info.windSpeed.rounded())) km/h")
                }
                .layoutPriority(1)
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)

            case .loading, .idle:
                ProgressView()
                    .frame(width: 48)
                Text("正在获取本地天气…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)

            case .denied:
                profileIcon("location.slash", tint: .gray)
                VStack(alignment: .leading, spacing: 3) {
                    Text("未开启定位")
                        .font(.headline)
                    Text("在系统「设置」允许定位后可查看本地天气")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)

            case .failed:
                profileIcon("arrow.clockwise", tint: .blue)
                VStack(alignment: .leading, spacing: 3) {
                    Text("天气获取失败")
                        .font(.headline)
                    Text("点击重试")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            NavigationLink {
                AnyView(WeatherForecastPage(weatherStore: weatherStore))
            } label: {
                EmptyView()
            }
            .opacity(0)
        }
    }

    var exchangeRateRow: some View {
        HStack(spacing: 14) {
            profileIcon("dollarsign.circle", tint: .orange)

            VStack(alignment: .leading, spacing: 3) {
                Text("汇率转换")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("实时获取最新汇率，支持多币种转换")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            NavigationLink {
                AnyView(ExchangeRatePage())
            } label: {
                EmptyView()
            }
            .opacity(0)
        }
    }

    var calculatorRow: some View {
        HStack(spacing: 14) {
            profileIcon("plus.forwardslash.minus", tint: .green)

            VStack(alignment: .leading, spacing: 3) {
                Text("计算器")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("简单四则计算，随手算一下就够用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            NavigationLink {
                AnyView(calculatorPage)
            } label: {
                EmptyView()
            }
            .opacity(0)
        }
    }

    var calculatorPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                calculatorCard

                if !calculatorHistory.isEmpty {
                    calculatorHistoryCard
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("计算器")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculatorResetSession()
        }
    }

    var calculatorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                if calculatorShowsResolvedExpression {
                    Text(calculatorStatusText)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Text(calculatorPrimaryDisplayText)
                    .font(.system(size: calculatorShowsResolvedExpression ? 34 : 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .animation(.spring(response: 0.26, dampingFraction: 0.88), value: calculatorPrimaryDisplayText)

            Spacer(minLength: 24)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    calculatorButton("C", kind: .destructive) {
                        calculatorClear()
                    }
                    calculatorButton("⌫", kind: .utility) {
                        calculatorBackspace()
                    }
                    calculatorButton("%", kind: .utility) {
                        calculatorApplyPercent()
                    }
                    calculatorButton(
                        CalculatorOperation.divide.rawValue,
                        kind: .operation,
                        isSelected: isCalculatorOperationSelected(.divide)
                    ) {
                        calculatorPerformOperation(.divide)
                    }
                }

                HStack(spacing: 10) {
                    calculatorButton("7", kind: .number) { calculatorTapDigit("7") }
                    calculatorButton("8", kind: .number) { calculatorTapDigit("8") }
                    calculatorButton("9", kind: .number) { calculatorTapDigit("9") }
                    calculatorButton(
                        CalculatorOperation.multiply.rawValue,
                        kind: .operation,
                        isSelected: isCalculatorOperationSelected(.multiply)
                    ) {
                        calculatorPerformOperation(.multiply)
                    }
                }

                HStack(spacing: 10) {
                    calculatorButton("4", kind: .number) { calculatorTapDigit("4") }
                    calculatorButton("5", kind: .number) { calculatorTapDigit("5") }
                    calculatorButton("6", kind: .number) { calculatorTapDigit("6") }
                    calculatorButton(
                        CalculatorOperation.subtract.rawValue,
                        kind: .operation,
                        isSelected: isCalculatorOperationSelected(.subtract)
                    ) {
                        calculatorPerformOperation(.subtract)
                    }
                }

                HStack(spacing: 10) {
                    calculatorButton("1", kind: .number) { calculatorTapDigit("1") }
                    calculatorButton("2", kind: .number) { calculatorTapDigit("2") }
                    calculatorButton("3", kind: .number) { calculatorTapDigit("3") }
                    calculatorButton(
                        CalculatorOperation.add.rawValue,
                        kind: .operation,
                        isSelected: isCalculatorOperationSelected(.add)
                    ) {
                        calculatorPerformOperation(.add)
                    }
                }

                HStack(spacing: 10) {
                    calculatorButton("±", kind: .utility) {
                        calculatorToggleSign()
                    }
                    calculatorButton("0", kind: .number) { calculatorTapDigit("0") }
                    calculatorButton(".", kind: .number) { calculatorTapDecimal() }
                    calculatorButton("=", kind: .equals) {
                        calculatorCalculateResult()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 540, alignment: .bottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var calculatorHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("历史计算")
                    .font(.headline)

                Spacer(minLength: 8)

                Button("清空") {
                    clearCalculatorHistory()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(Array(calculatorHistory.prefix(10).enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(item.expression)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(item.result)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                            .frame(width: 72, alignment: .trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.vertical, 14)

                    if index < min(calculatorHistory.count, 10) - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func weatherMetricRow(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .frame(width: 28, alignment: .leading)
            Text(value)
                .monospacedDigit()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    func weatherGradient(for code: Int) -> [Color] {
        switch code {
        case 0:
            return [Color(red: 1.0, green: 0.75, blue: 0.28), Color(red: 1.0, green: 0.55, blue: 0.0)]
        case 1, 2:
            return [Color(red: 0.43, green: 0.70, blue: 0.95), Color(red: 0.29, green: 0.56, blue: 0.89)]
        case 45, 48:
            return [Color(red: 0.74, green: 0.76, blue: 0.78), Color(red: 0.56, green: 0.61, blue: 0.65)]
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return [Color(red: 0.36, green: 0.42, blue: 0.75), Color(red: 0.22, green: 0.29, blue: 0.67)]
        case 71, 73, 75, 77, 85, 86:
            return [Color(red: 0.61, green: 0.83, blue: 0.94), Color(red: 0.36, green: 0.68, blue: 0.89)]
        case 95, 96, 99:
            return [Color(red: 0.38, green: 0.41, blue: 0.44), Color(red: 0.22, green: 0.28, blue: 0.31)]
        default:
            return [Color(red: 0.64, green: 0.69, blue: 0.73), Color(red: 0.45, green: 0.49, blue: 0.53)]
        }
    }

    func calculatorButton(
        _ title: String,
        kind: CalculatorButtonKind = .number,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let background: Color
        let foreground: Color
        let pressedBackground: Color
        let pressedForeground: Color
        let borderColor: Color
        let shadowColor: Color

        switch kind {
        case .number:
            background = Color(.systemBackground)
            foreground = .primary
            pressedBackground = Color.blue.opacity(0.18)
            pressedForeground = .blue
            borderColor = Color(.separator).opacity(0.16)
            shadowColor = Color.black.opacity(0.08)
        case .utility:
            background = Color(.tertiarySystemFill)
            foreground = .primary
            pressedBackground = Color(.systemGray4)
            pressedForeground = .primary
            borderColor = .clear
            shadowColor = Color.black.opacity(0.05)
        case .destructive:
            background = Color.red.opacity(0.14)
            foreground = .red
            pressedBackground = Color.red.opacity(0.28)
            pressedForeground = .red
            borderColor = .clear
            shadowColor = Color.red.opacity(0.08)
        case .operation:
            background = isSelected ? Color.blue.opacity(0.18) : Color.blue
            foreground = isSelected ? .blue : .white
            pressedBackground = isSelected ? Color.blue.opacity(0.28) : Color.blue.opacity(0.78)
            pressedForeground = isSelected ? .blue : .white
            borderColor = isSelected ? Color.blue.opacity(0.28) : .clear
            shadowColor = Color.blue.opacity(isSelected ? 0.10 : 0.20)
        case .equals:
            background = Color.green
            foreground = .white
            pressedBackground = Color.green.opacity(0.78)
            pressedForeground = .white
            borderColor = .clear
            shadowColor = Color.green.opacity(0.20)
        }

        return Button {
            calculatorFlashKey(title)
            action()
        } label: {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
        }
        .buttonStyle(
            CalculatorKeyButtonStyle(
                background: background,
                foreground: foreground,
                pressedBackground: pressedBackground,
                pressedForeground: pressedForeground,
                borderColor: borderColor,
                shadowColor: shadowColor,
                forcePressed: calculatorFlashedKey == title
            )
        )
    }

    func calculatorFlashKey(_ key: String) {
        calculatorFlashToken += 1
        let token = calculatorFlashToken
        if calculatorFlashedKey != nil {
            calculatorFlashedKey = nil
        }
        calculatorFlashedKey = key
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            if calculatorFlashToken == token {
                calculatorFlashedKey = nil
            }
        }
    }

    func calculatorTapDigit(_ digit: String) {
        if calculatorDisplay == "错误" {
            calculatorClear()
        }

        if calculatorShouldStartFreshInput {
            calculatorDisplay = "0"
            calculatorStatusText = ""
        }

        if calculatorIsEnteringNewNumber || calculatorDisplay == "0" {
            calculatorDisplay = digit
            calculatorIsEnteringNewNumber = false
            calculatorSyncExpression()
            return
        }

        calculatorDisplay.append(digit)
        calculatorSyncExpression()
    }

    func calculatorTapDecimal() {
        if calculatorDisplay == "错误" {
            calculatorClear()
        }

        if calculatorShouldStartFreshInput {
            calculatorDisplay = "0"
            calculatorStatusText = ""
        }

        if calculatorIsEnteringNewNumber {
            calculatorDisplay = "0."
            calculatorIsEnteringNewNumber = false
            calculatorSyncExpression()
            return
        }

        if !calculatorDisplay.contains(".") {
            calculatorDisplay.append(".")
            calculatorSyncExpression()
        }
    }

    func calculatorToggleSign() {
        guard let value = calculatorCurrentValue else {
            calculatorClear()
            return
        }

        calculatorDisplay = calculatorFormattedValue(-value)
        calculatorSyncExpression()
    }

    func calculatorApplyPercent() {
        guard let value = calculatorCurrentValue else {
            calculatorClear()
            return
        }

        let originalDisplay = calculatorDisplay
        calculatorDisplay = calculatorFormattedValue(value / 100)

        if let storedValue = calculatorStoredValue, let pendingOperation = calculatorPendingOperation {
            calculatorStatusText = "\(calculatorFormattedValue(storedValue))\(pendingOperation.rawValue)\(originalDisplay)%"
        } else {
            calculatorStatusText = "\(originalDisplay)%"
        }
    }

    func calculatorBackspace() {
        if calculatorDisplay == "错误" {
            calculatorClear()
            return
        }

        if calculatorIsEnteringNewNumber {
            calculatorDisplay = "0"
            calculatorIsEnteringNewNumber = false
            return
        }

        guard !calculatorDisplay.isEmpty else {
            calculatorDisplay = "0"
            return
        }

        calculatorDisplay.removeLast()
        if calculatorDisplay.isEmpty || calculatorDisplay == "-" {
            calculatorDisplay = "0"
        }
        calculatorSyncExpression()
    }

    func calculatorClear() {
        calculatorDisplay = "0"
        calculatorStoredValue = nil
        calculatorPendingOperation = nil
        calculatorIsEnteringNewNumber = false
        calculatorStatusText = ""
    }

    func calculatorResetSession() {
        calculatorClear()
    }

    func calculatorPerformOperation(_ operation: CalculatorOperation) {
        guard let currentValue = calculatorCurrentValue else {
            calculatorClear()
            return
        }

        if let storedValue = calculatorStoredValue, let pendingOperation = calculatorPendingOperation {
            if calculatorIsEnteringNewNumber {
                calculatorPendingOperation = operation
                calculatorStatusText = "\(calculatorFormattedValue(storedValue))\(operation.rawValue)"
                return
            }

            guard let result = calculatorEvaluate(lhs: storedValue, rhs: currentValue, operation: pendingOperation) else {
                calculatorShowError("除数不能为 0")
                return
            }

            calculatorDisplay = calculatorFormattedValue(result)
            calculatorStoredValue = result
        } else {
            calculatorStoredValue = currentValue
        }

        let baseValue = calculatorStoredValue ?? currentValue
        calculatorPendingOperation = operation
        calculatorIsEnteringNewNumber = true
        calculatorStatusText = "\(calculatorFormattedValue(baseValue))\(operation.rawValue)"
    }

    func calculatorCalculateResult() {
        guard let pendingOperation = calculatorPendingOperation,
              let storedValue = calculatorStoredValue,
              let currentValue = calculatorCurrentValue else {
            return
        }

        let rhsText = calculatorIsEnteringNewNumber ? calculatorFormattedValue(storedValue) : calculatorDisplay
        let rhs = calculatorIsEnteringNewNumber ? storedValue : currentValue
        guard let result = calculatorEvaluate(lhs: storedValue, rhs: rhs, operation: pendingOperation) else {
            calculatorShowError("除数不能为 0")
            return
        }

        let expression = "\(calculatorFormattedValue(storedValue))\(pendingOperation.rawValue)\(rhsText)="
        let resultText = calculatorFormattedValue(result)
        calculatorStatusText = expression
        calculatorDisplay = resultText
        calculatorHistory.insert(
            CalculatorHistoryItem(expression: expression, result: resultText),
            at: 0
        )
        persistCalculatorHistory()
        calculatorStoredValue = nil
        calculatorPendingOperation = nil
        calculatorIsEnteringNewNumber = false
    }

    func calculatorEvaluate(lhs: Double, rhs: Double, operation: CalculatorOperation) -> Double? {
        switch operation {
        case .add:
            return lhs + rhs
        case .subtract:
            return lhs - rhs
        case .multiply:
            return lhs * rhs
        case .divide:
            guard rhs != 0 else { return nil }
            return lhs / rhs
        }
    }

    func calculatorShowError(_ text: String) {
        calculatorDisplay = "错误"
        calculatorStoredValue = nil
        calculatorPendingOperation = nil
        calculatorIsEnteringNewNumber = true
        calculatorStatusText = text
    }

    var calculatorCurrentValue: Double? {
        Double(calculatorDisplay)
    }

    var calculatorShouldStartFreshInput: Bool {
        calculatorStoredValue == nil
            && calculatorPendingOperation == nil
            && calculatorStatusText.hasSuffix("=")
    }

    var calculatorShowsResolvedExpression: Bool {
        calculatorStatusText.hasSuffix("=")
    }

    var calculatorPrimaryDisplayText: String {
        if calculatorShowsResolvedExpression || calculatorStatusText.isEmpty {
            return calculatorDisplay
        }
        return calculatorStatusText
    }

    func calculatorSyncExpression() {
        guard let storedValue = calculatorStoredValue,
              let pendingOperation = calculatorPendingOperation else {
            if calculatorDisplay != "错误", !calculatorStatusText.hasSuffix("=") {
                calculatorStatusText = ""
            }
            return
        }

        if calculatorIsEnteringNewNumber {
            calculatorStatusText = "\(calculatorFormattedValue(storedValue))\(pendingOperation.rawValue)"
        } else {
            calculatorStatusText = "\(calculatorFormattedValue(storedValue))\(pendingOperation.rawValue)\(calculatorDisplay)"
        }
    }

    func isCalculatorOperationSelected(_ operation: CalculatorOperation) -> Bool {
        calculatorPendingOperation == operation && !calculatorShowsResolvedExpression
    }

    func calculatorFormattedValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    func profileTabCard(_ tab: MainAppTab) -> some View {
        HStack(spacing: 14) {
            if isEditingTabs {
                Image(systemName: "line.3.horizontal")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            profileIcon(tab.icon, tint: profileTabTint(tab))

            VStack(alignment: .leading, spacing: 3) {
                Text(tab.title)
                    .font(.headline)
                Text(tab.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if isEditingTabs {
                Text("拖动排序")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .transition(.opacity)
            } else {
                Toggle("", isOn: mainTabVisibilityBinding(for: tab))
                    .labelsHidden()
                    .disabled(isOnlyVisibleMainTab(tab))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            if isEditingTabs {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.blue.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
        }
    }

    var notificationSettingsRow: some View {
        HStack(spacing: 14) {
            profileIcon("bell.badge", tint: .red)

            VStack(alignment: .leading, spacing: 3) {
                Text("通知设置")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("管理各类提醒通知")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(anyFastingNotificationEnabled ? "已开启" : "未开启")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            NavigationLink {
                AnyView(notificationSettingsPage)
            } label: {
                EmptyView()
            }
            .opacity(0)
        }
    }

    var securitySettingsRow: some View {
        HStack(spacing: 14) {
            profileIcon("lock.shield", tint: .blue)

            VStack(alignment: .leading, spacing: 3) {
                Text("安全设置")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("设置理财资产隐私")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(isFinanceAssetDefaultHidden ? "默认隐藏" : "直接显示")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            NavigationLink {
                AnyView(securitySettingsPage)
            } label: {
                EmptyView()
            }
            .opacity(0)
        }
    }

    var securitySettingsPage: some View {
        List {
            financePrivacyDefaultCard
                .profileCardRow()

            securityPasswordCard
                .profileCardRow()

            profileSectionNoteRow("默认密码是 111111。开启默认隐藏后，每次进入资产记录都需要验证密码或本机生物识别才能查看。")
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("安全设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    var financePrivacyDefaultCard: some View {
        HStack(spacing: 14) {
            profileIcon("eye.slash", tint: .blue)

            VStack(alignment: .leading, spacing: 3) {
                Text("默认隐藏资产记录")
                    .font(.headline)
                Text(isFinanceAssetDefaultHidden ? "进入资产记录时默认显示为 ***" : "进入资产记录时直接显示真实数字")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Toggle(
                "",
                isOn: Binding(
                    get: { isFinanceAssetDefaultHidden },
                    set: { updateFinanceAssetDefaultHidden($0) }
                )
            )
            .labelsHidden()
            .tint(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var securityPasswordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                profileIcon("lock.shield", tint: .blue)

                VStack(alignment: .leading, spacing: 3) {
                    Text("资产查看密码")
                        .font(.headline)
                    Text("用于解锁理财资产记录里的真实数字")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
            }

            if let financeSecurityPasswordMessage {
                Text(financeSecurityPasswordMessage)
                    .font(.caption)
                    .foregroundStyle(financeSecurityPasswordMessage.contains("已更新") ? .green : .red)
            }

            Button {
                isShowingFinancePasswordChangeSheet = true
            } label: {
                Text("修改密码")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppSecondaryButtonStyle(tint: .blue))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var notificationSettingsPage: some View {
        List {
            profileSectionTitleRow("16 + 8 断食")

            notificationCard
                .profileCardRow()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    var notificationCard: some View {
        VStack(spacing: 0) {
            notificationToggleRow(
                icon: "fork.knife",
                tint: .green,
                title: "进食前 1 小时",
                subtitle: "断食快结束时提醒",
                isOn: $notifyEatingSoon
            )

            Divider().padding(.leading, 64)

            notificationToggleRow(
                icon: "fork.knife.circle.fill",
                tint: .green,
                title: "进食时间到",
                subtitle: "断食达标可以开吃",
                isOn: $notifyEatingStart
            )

            Divider().padding(.leading, 64)

            notificationToggleRow(
                icon: "timer",
                tint: .blue,
                title: "断食前 1 小时",
                subtitle: "进食窗口快结束时提醒",
                isOn: $notifyFastingSoon
            )

            Divider().padding(.leading, 64)

            notificationToggleRow(
                icon: "moon.stars.fill",
                tint: .blue,
                title: "断食时间到",
                subtitle: "开始新一轮断食",
                isOn: $notifyFastingStart
            )
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func notificationToggleRow(icon: String, tint: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            profileIcon(icon, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) {
                    handleNotificationToggleChange()
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    var appearanceRow: some View {
        HStack(spacing: 14) {
            profileIcon("circle.lefthalf.filled", tint: .indigo)

            VStack(alignment: .leading, spacing: 3) {
                Text("外观")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("浅色、深色或跟随系统")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(appearanceMode.wrappedValue.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            NavigationLink {
                AnyView(appearanceSettingsPage)
            } label: {
                EmptyView()
            }
            .opacity(0)
        }
    }

    var appearanceSettingsPage: some View {
        List {
            appearanceCard
                .profileCardRow()

            profileSectionNoteRow("选择“浅色”或“深色”可固定使用某种外观；选择“跟随系统”则随系统设置自动切换。")
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("外观")
        .navigationBarTitleDisplayMode(.inline)
    }

    var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                profileIcon("circle.lefthalf.filled", tint: .indigo)

                VStack(alignment: .leading, spacing: 3) {
                    Text("外观")
                        .font(.headline)
                    Text("浅色、深色或跟随系统")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
            }

            AppSegmentedControl(
                options: AppearanceMode.allCases,
                selection: appearanceMode,
                title: \.title
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func profileIcon(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(tint, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    func profileTabTint(_ tab: MainAppTab) -> Color {
        switch tab {
        case .health:
            return .pink
        case .todo:
            return .orange
        case .finance:
            return .green
        }
    }

    @ViewBuilder
    func profileSectionTitleRow<Trailing: View>(_ title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            trailing()
        }
        .listRowInsets(EdgeInsets(top: 32, leading: 20, bottom: 6, trailing: 20))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    func profileSectionNoteRow(_ text: String, topInset: CGFloat = 6) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineSpacing(2)
            .listRowInsets(EdgeInsets(top: topInset, leading: 20, bottom: 2, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

extension View {
    func profileCardRow() -> some View {
        self
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
