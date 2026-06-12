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

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 96), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(FinanceAssetKind.allCases) { kind in
                                financeKindChip(kind)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        financeFieldLabel("名称")
                        ModernInputField(
                            placeholder: financeAssetKind == .custom ? "自定义类目名称" : "名称，例如：招商银行卡",
                            text: $financeAssetNameInput,
                            icon: financeAssetKind.icon,
                            tint: financeKindTint(financeAssetKind)
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        financeFieldLabel("金额")
                        ModernInputField(
                            placeholder: "金额，例如：12000",
                            text: $financeAssetAmountInput,
                            icon: "yensign.circle",
                            tint: financeKindTint(financeAssetKind),
                            keyboardType: .decimalPad
                        )
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
            VStack(spacing: 8) {
                Image(systemName: kind.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : tint)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.12)), in: Circle())

                Text(kind.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint : Color(.separator).opacity(0.18), lineWidth: isSelected ? 2 : 1)
            }
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

            if monthlyFinanceTrendPoints.count >= 2 {
                FinanceTrendView(points: monthlyFinanceTrendPoints, amountText: currencyText)
                    .frame(height: 150)
            } else {
                AppEmptyState(
                    title: "还没有趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: "至少跨 2 个月保存资产记录后，会显示月度变化。"
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
            VStack(alignment: .leading, spacing: 4) {
                Text("资产分布")
                    .font(.title3.bold())
                Text("按资产类型汇总，快速看出钱主要放在哪里。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
                VStack(spacing: 10) {
                    ForEach(sortedFinanceAssets) { asset in
                        FinanceAssetRow(
                            asset: asset,
                            amountText: currencyText(asset.amount),
                            updatedText: chineseDateTime(asset.updatedAt),
                            tint: financeKindTint(asset.kind)
                        ) {
                            editingFinanceAsset = asset
                        } onDelete: {
                            deleteFinanceAsset(asset)
                        }

                        if asset.id != sortedFinanceAssets.last?.id {
                            Divider()
                        }
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("股票研究")
                        .font(.title3.bold())
                    Text("搜索股票名称，点开后编辑长文本研究笔记。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    stockNameInput = ""
                    isShowingStockAddAlert = true
                } label: {
                    AppIconCircleButton(icon: "plus", tint: .blue, size: 40, iconFont: .subheadline.weight(.bold))
                }
                .buttonStyle(.plain)
            }

            SearchInputBar(placeholder: "搜索股票名称", text: $stockSearchText)

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
                    description: "换个股票名称试试看。"
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredStockResearchItems) { item in
                        StockResearchRow(
                            item: item,
                            updatedText: chineseDateTime(item.updatedAt),
                            onOpen: {
                            editingStockResearchItem = item
                        }, onDelete: {
                            deleteStockResearchItem(item)
                        }, onTogglePin: {
                            toggleStockResearchPinned(item)
                        })

                        if item.id != filteredStockResearchItems.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
