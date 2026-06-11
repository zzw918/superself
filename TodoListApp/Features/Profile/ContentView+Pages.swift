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
                Section {
                    ForEach(mainTabOrder) { tab in
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(tab.title)
                                    .font(.headline)
                                Text(tab.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: mainTabVisibilityBinding(for: tab))
                                .labelsHidden()
                                .disabled(isOnlyVisibleMainTab(tab))
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: moveMainTabs)
                } header: {
                    HStack {
                        Text("功能管理")

                        Spacer()

                        Button {
                            toggleTabEditMode()
                        } label: {
                            Image(systemName: isEditingTabs ? "checkmark.circle.fill" : "square.and.pencil")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("拖动可调整健康、备忘录、理财的顺序；关闭开关可隐藏不常用功能。“我的”固定在最右侧，不参与排序和隐藏。")
                }

                Section {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("我的")
                                .font(.headline)
                            Text("固定在最右侧")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("固定")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    syncCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("数据同步")
                } footer: {
                    Text("健康、备忘录、理财、股票研究、功能设置和个人目标都会保存到本地，并在 iCloud 可用时同步。")
                }
            }
            .navigationTitle("我的")
        }
    }
}
