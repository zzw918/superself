import SwiftUI

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
        case .wishlist:
            wishlistCard
        case .anniversary:
            anniversaryCard
        }
    }

    var memoSectionPicker: some View {
        AppUnderlineTabs(
            options: visibleMemoSections,
            selection: $memoSection,
            title: \.title
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
                            description: section.description,
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
                            description: section.description,
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
                            description: section.description,
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
        description: String,
        tint: Color,
        isOnlyVisible: Bool,
        visibility: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            profileIcon(icon, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
                        Button {
                            beginTabEditMode()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: 30)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                ForEach(mainTabOrder) { tab in
                    profileTabCard(tab)
                        .profileCardRow()
                }
                .onMove(perform: moveMainTabs)

                profileFixedTabCard
                    .profileCardRow()

                sectionManagementEntryRow
                    .profileCardRow()

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
        }
    }

    @ViewBuilder
    var weatherCard: some View {
        HStack(spacing: 16) {
            switch weatherStore.state {
            case .loaded(let info):
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: weatherGradient(for: info.weatherCode),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: info.symbolName)
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text(info.cityName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(info.temperatureText)
                            .font(.system(size: 34, weight: .bold))
                        Text(info.conditionText)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 4) {
                    weatherMetricRow(title: "体感", value: "\(Int(info.apparentTemperature.rounded()))°")
                    weatherMetricRow(title: "湿度", value: "\(info.humidity)%")
                    weatherMetricRow(title: "风速", value: "\(Int(info.windSpeed.rounded())) km/h")
                }

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
        .contentShape(Rectangle())
        .onTapGesture {
            weatherStore.refresh()
        }
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

    var profileFixedTabCard: some View {
        HStack(spacing: 14) {
            profileIcon("person.crop.circle", tint: .gray)

            VStack(alignment: .leading, spacing: 3) {
                Text("我的")
                    .font(.headline)
                Text("固定在最右侧")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text("固定")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.tertiarySystemFill), in: Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var sectionManagementEntryRow: some View {
        Button {
            isShowingSectionManagement = true
        } label: {
            HStack(spacing: 14) {
                profileIcon("square.grid.2x2", tint: .blue)

                VStack(alignment: .leading, spacing: 3) {
                    Text("模块管理")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("调整各功能模块的顺序与显隐")
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
        }
        .buttonStyle(.plain)
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
                notificationSettingsPage
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
                securitySettingsPage
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
                appearanceSettingsPage
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
