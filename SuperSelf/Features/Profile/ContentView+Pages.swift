import SwiftUI

extension ContentView {
    var healthPage: some View {
        NavigationStack {
            VStack(spacing: 0) {
                healthSectionPicker
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 14)

                TabView(selection: $healthSection) {
                    sectionScroll { fastingSection }
                        .tag(HealthSection.fasting)

                    sectionScroll { weightSection }
                        .tag(HealthSection.weight)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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
    func sectionScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            content()
                .padding(.horizontal)
                .padding(.bottom)
        }
    }

    var healthSectionPicker: some View {
        AppUnderlineTabs(
            options: HealthSection.allCases,
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
                memoSectionPicker
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 14)

                TabView(selection: $memoSection) {
                    sectionScroll { todoTasksCard }
                        .tag(MemoSection.todo)

                    sectionScroll { wishlistCard }
                        .tag(MemoSection.wishlist)

                    sectionScroll { anniversaryCard }
                        .tag(MemoSection.anniversary)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("备忘录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    var memoSectionPicker: some View {
        AppUnderlineTabs(
            options: MemoSection.allCases,
            selection: $memoSection,
            title: \.title
        )
    }

    var financePage: some View {
        NavigationStack {
            VStack(spacing: 0) {
                financeSectionPicker
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 14)

                TabView(selection: $financeSection) {
                    sectionScroll { financeAssetRecordSection }
                        .tag(FinanceSection.assetRecord)

                    sectionScroll { stockResearchSection }
                        .tag(FinanceSection.stockResearch)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("理财")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    var financeSectionPicker: some View {
        AppUnderlineTabs(
            options: FinanceSection.allCases,
            selection: $financeSection,
            title: \.title
        )
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
                    Button {
                        toggleTabEditMode()
                    } label: {
                        Text(isEditingTabs ? "完成" : "排序")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(mainTabOrder) { tab in
                    profileTabCard(tab)
                        .profileCardRow()
                }
                .onMove(perform: moveMainTabs)

                profileFixedTabCard
                    .profileCardRow()

                profileSectionTitleRow("外观")

                appearanceRow
                    .profileCardRow()

                profileSectionTitleRow("通知")

                notificationSettingsRow
                    .profileCardRow()

                profileSectionNoteRow("在关键节点收到本地通知。需要在系统「设置-通知」中允许通知权限。")

                profileSectionTitleRow("数据同步")

                syncCard
                    .profileCardRow()

                profileSectionNoteRow("数据保存在本地，并在 iCloud 可用时同步。")
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
                Image(systemName: info.symbolName)
                    .font(.system(size: 34))
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 48)

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

                VStack(alignment: .trailing, spacing: 4) {
                    Text(info.apparentText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("湿度 \(info.humidity)%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    var notificationSettingsPage: some View {
        List {
            profileSectionTitleRow("16 + 8 断食")

            notificationCard
                .profileCardRow()

            profileSectionNoteRow("在关键节点收到本地通知。需要在系统「设置-通知」中允许通知权限。")
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

    func profileSectionNoteRow(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineSpacing(2)
            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 2, trailing: 20))
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
