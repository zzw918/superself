import SwiftUI

extension ContentView {
    var financeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("总资产")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(currencyText(totalFinanceAmount))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                Spacer()

                if let financeMonthChangeText {
                    HStack(spacing: 4) {
                        Image(systemName: financeMonthChangeText.hasPrefix("-") ? "arrow.down.right" : "arrow.up.right")
                            .font(.caption.weight(.bold))
                        Text(financeMonthChangeText)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.22), in: Capsule())
                }
            }

            HStack(spacing: 12) {
                financeHeroStat(title: "资产项", value: "\(financeAssets.count)")
                Divider().frame(height: 30).overlay(Color.white.opacity(0.25))
                financeHeroStat(title: "历史记录", value: "\(financeSnapshots.count)")
                Divider().frame(height: 30).overlay(Color.white.opacity(0.25))
                financeHeroStat(title: "本月变化", value: financeMonthChangeText ?? "--")
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
            .safeAreaInset(edge: .bottom) {
                Button(action: addFinanceAsset) {
                    Text("添加资产")
                }
                .buttonStyle(AppPrimaryButtonStyle(tint: financeKindTint(financeAssetKind)))
                .disabled(financeAssetAmountInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
            }
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
                    Text("按每个月最后一次记录作为当月数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let financeMonthChangeText {
                    Text(financeMonthChangeText)
                        .font(.caption.bold())
                        .foregroundStyle(financeMonthChangeText.hasPrefix("-") ? .red : .blue)
                }
            }

            if !monthlyFinanceTrendPoints.isEmpty {
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
            Text("资产分布")
                .font(.title3.bold())

            if financeDistributionPoints.isEmpty {
                AppEmptyState(
                    title: "还没有分布",
                    systemImage: "chart.pie",
                    description: "添加资产后，会显示各类资产占比。"
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                FinanceDistributionView(
                    points: financeDistributionPoints,
                    amountText: currencyText
                )
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
                    Text("\(financeAssets.count) 项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingFinanceAssetSheet = true
                } label: {
                    AppIconCircleButton(icon: "plus", tint: .blue, size: 32, iconFont: .subheadline.weight(.bold))
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
                            amountText: currencyText(asset.amount),
                            updatedText: chineseDateTime(asset.updatedAt),
                            tint: financeKindTint(asset.kind),
                            onEdit: {
                                editingFinanceAsset = asset
                            },
                            onDelete: {
                                deleteFinanceAsset(asset)
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

    var stockResearchListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SearchInputBar(placeholder: "搜索股票名称", text: $stockSearchText)

            HStack(alignment: .top, spacing: 10) {
                if !stockResearchItems.isEmpty {
                    stockResearchFilterBar
                } else {
                    Spacer(minLength: 0)
                }

                Button {
                    stockNameInput = ""
                    isShowingStockAddAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue, in: Circle())
                }
                .buttonStyle(.plain)
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

    @State private var isExpanded = false

    private var activeCount: Int {
        [certainty, growth, attention].compactMap { $0 }.count
    }

    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(activeCount > 0 ? ".fill" : "")")
                    Text("筛选")
                    if activeCount > 0 {
                        Text("\(activeCount)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.blue, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(activeCount > 0 ? .blue : .secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
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
                .transition(.opacity.combined(with: .move(edge: .top)))
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
