import SwiftUI

extension ContentView {
    var financeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("总资产")
                        .font(.title3.bold())
                    Text("当前记录的所有资产合计")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(currencyText(totalFinanceAmount))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            }

            HStack(spacing: 14) {
                SummaryPill(title: "资产项", value: "\(financeAssets.count)", color: .blue)
                SummaryPill(title: "历史记录", value: "\(financeSnapshots.count)", color: .blue)
                SummaryPill(title: "月变化", value: financeMonthChangeText ?? "--", color: .orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var financeAddAssetSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("银行卡可以添加多张；股票、期权、支付宝、微信和其他资产也可以分别记录。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("资产类型", selection: $financeAssetKind) {
                    ForEach(FinanceAssetKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.icon)
                            .tag(kind)
                    }
                }
                .pickerStyle(.menu)

                ModernInputField(
                    placeholder: financeAssetKind == .custom ? "自定义类目名称" : "名称，例如：招商银行卡",
                    text: $financeAssetNameInput,
                    icon: financeAssetKind.icon,
                    tint: .blue
                )

                AddEntryBar(
                    placeholder: "金额，例如：12000",
                    text: $financeAssetAmountInput,
                    icon: "yensign.circle",
                    tint: .blue,
                    keyboardType: .decimalPad,
                    buttonTitle: "添加",
                    action: addFinanceAsset
                )

                Spacer()
            }
            .padding()
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
            }
        }
        .presentationDetents([.medium])
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
                            updatedText: chineseDateTime(asset.updatedAt)
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

    var stockResearchAddCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("新增股票")
                    .font(.title3.bold())
                Text("先用股票名称建档，后面可以持续补充你的理解。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            AddEntryBar(
                placeholder: "例如：腾讯控股、贵州茅台",
                text: $stockNameInput,
                icon: "chart.line.text.clipboard",
                tint: .blue,
                buttonTitle: "添加",
                action: addStockResearchItem
            )
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

                Text("\(stockResearchItems.count) 只")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
