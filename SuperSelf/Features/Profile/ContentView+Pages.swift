import SwiftUI

extension ContentView {
    var healthPage: some View {
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

    var healthSectionPicker: some View {
        AppSegmentedControl(
            options: HealthSection.allCases,
            selection: $healthSection,
            title: \.title
        )
    }

    var fastingSection: some View {
        VStack(spacing: 20) {
            statusCard
            actionCard
            fastingHistoryCard
            planCard
        }
    }

    var weightSection: some View {
        VStack(spacing: 20) {
            weightCard
            bmiCard
            trendCard
            historyCard
        }
    }

    var memoPage: some View {
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

    var memoSectionPicker: some View {
        AppSegmentedControl(
            options: MemoSection.allCases,
            selection: $memoSection,
            title: \.title
        )
    }

    var financePage: some View {
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

    var financeSectionPicker: some View {
        AppSegmentedControl(
            options: FinanceSection.allCases,
            selection: $financeSection,
            title: \.title
        )
    }

    var financeAssetRecordSection: some View {
        VStack(spacing: 20) {
            financeSummaryCard
            financeTrendCard
            financeDistributionCard
            financeAssetsCard
        }
    }

    var stockResearchSection: some View {
        VStack(spacing: 20) {
            stockResearchAddCard
            stockResearchListCard
        }
    }

    var profilePage: some View {
        NavigationStack {
            List {
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

                profileSectionNoteRow("拖动可调整健康、备忘录、理财的顺序；关闭开关可隐藏不常用功能。“我的”固定在最右侧，不参与排序和隐藏。")

                profileSectionTitleRow("数据同步")

                syncCard
                    .profileCardRow()

                profileSectionNoteRow("健康、备忘录、理财、股票研究、功能设置和个人目标都会保存到本地，并在 iCloud 可用时同步。")
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的")
        }
    }

    func profileTabCard(_ tab: MainAppTab) -> some View {
        HStack(spacing: 14) {
            profileIcon(tab.icon, tint: profileTabTint(tab))

            VStack(alignment: .leading, spacing: 3) {
                Text(tab.title)
                    .font(.headline)
                Text(tab.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: mainTabVisibilityBinding(for: tab))
                .labelsHidden()
                .disabled(isOnlyVisibleMainTab(tab))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
        .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 8, trailing: 20))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    func profileSectionNoteRow(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineSpacing(2)
            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 4, trailing: 20))
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
