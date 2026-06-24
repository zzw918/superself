import SwiftUI

enum WeightTrendGranularity: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            return "天"
        case .week:
            return "周"
        case .month:
            return "月"
        }
    }
}

struct WeightTrendPoint: Identifiable {
    let date: Date
    let weight: Double
    let topLabel: String
    let bottomLabel: String

    var id: String {
        "\(date.timeIntervalSince1970)-\(topLabel)-\(bottomLabel)"
    }
}

struct FinanceTrendPoint: Identifiable {
    let date: Date
    let amount: Double
    let topLabel: String
    let bottomLabel: String

    var id: String {
        "\(date.timeIntervalSince1970)-\(amount)"
    }
}

struct FinanceDistributionPoint: Identifiable {
    let title: String
    let amount: Double
    let color: Color

    var id: String { title }
}

enum FinanceDistributionGrouping: String, CaseIterable, Identifiable {
    case kind
    case assetName

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kind:
            return "类型"
        case .assetName:
            return "名称"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable, Hashable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色"
        case .dark:
            return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum HealthSection: String, CaseIterable, Identifiable, Codable {
    case weight
    case fasting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fasting:
            return "16 + 8"
        case .weight:
            return "体重"
        }
    }

    var icon: String {
        switch self {
        case .fasting:
            return "timer"
        case .weight:
            return "scalemass"
        }
    }

    var description: String {
        switch self {
        case .fasting:
            return "断食计时与目标"
        case .weight:
            return "体重记录与趋势"
        }
    }
}

enum MemoSection: String, CaseIterable, Identifiable, Codable {
    case todo
    case note
    case wishlist
    case anniversary
    case calendar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todo:
            return "TODO"
        case .note:
            return "笔记"
        case .wishlist:
            return "愿望"
        case .anniversary:
            return "纪念日"
        case .calendar:
            return "日历"
        }
    }

    var icon: String {
        switch self {
        case .todo:
            return "checklist"
        case .note:
            return "square.text.square"
        case .wishlist:
            return "sparkles"
        case .anniversary:
            return "calendar.badge.clock"
        case .calendar:
            return "calendar"
        }
    }

    var description: String {
        switch self {
        case .todo:
            return "待办事项清单"
        case .note:
            return "带标签和图片的笔记"
        case .wishlist:
            return "想做想要的事"
        case .anniversary:
            return "重要日子倒数"
        case .calendar:
            return "查看月历和日期"
        }
    }
}

enum FinanceSection: String, CaseIterable, Identifiable, Codable {
    case expenseBook
    case assetRecord
    case stockResearch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assetRecord:
            return "资产"
        case .expenseBook:
            return "记账"
        case .stockResearch:
            return "股票"
        }
    }

    var icon: String {
        switch self {
        case .assetRecord:
            return "wallet.pass"
        case .expenseBook:
            return "list.bullet.clipboard"
        case .stockResearch:
            return "chart.line.text.clipboard"
        }
    }

    var description: String {
        switch self {
        case .assetRecord:
            return "资产分布与趋势"
        case .expenseBook:
            return "记录每笔支出"
        case .stockResearch:
            return "个股研究笔记"
        }
    }
}

enum MainAppTab: String, CaseIterable, Identifiable, Codable, Hashable {
    case health
    case todo
    case finance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health:
            return "健康"
        case .todo:
            return "备忘"
        case .finance:
            return "理财"
        }
    }

    var icon: String {
        switch self {
        case .health:
            return "heart"
        case .todo:
            return "note.text"
        case .finance:
            return "yensign.circle"
        }
    }

    var description: String {
        switch self {
        case .health:
            return "16 + 8、体重和健康目标"
        case .todo:
            return "TODO、笔记、愿望和纪念日"
        case .finance:
            return "资产记录和股票研究"
        }
    }
}

struct MainTabPreferences: Codable {
    var order: [MainAppTab]
    var visibleTabs: [MainAppTab]
}

/// 通用的「分区顺序 + 可见性」偏好，供健康/备忘/理财三个 tab 复用。
struct SectionPreferences<Section: RawRepresentable & CaseIterable & Hashable>: Codable
where Section.RawValue == String, Section.AllCases == [Section] {
    var order: [Section]
    var visibleSections: [Section]

    init(order: [Section] = Array(Section.allCases),
         visibleSections: [Section] = Array(Section.allCases)) {
        self.order = order
        self.visibleSections = visibleSections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let orderRaw = try container.decode([String].self, forKey: .order)
        let visibleRaw = try container.decode([String].self, forKey: .visibleSections)
        order = orderRaw.compactMap(Section.init(rawValue:))
        visibleSections = visibleRaw.compactMap(Section.init(rawValue:))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(order.map(\.rawValue), forKey: .order)
        try container.encode(visibleSections.map(\.rawValue), forKey: .visibleSections)
    }

    private enum CodingKeys: String, CodingKey {
        case order
        case visibleSections
    }

    /// 补全缺失分区、过滤无效分区，保证 order 覆盖全部 case 且 visible 至少一个。
    var normalized: SectionPreferences<Section> {
        let validOrder = order.filter { Section.allCases.contains($0) }
        let missing = Section.allCases.filter { !validOrder.contains($0) }
        let fullOrder = validOrder + missing

        let validVisible = visibleSections.filter { fullOrder.contains($0) }
        let visible = validVisible.isEmpty ? [fullOrder[0]] : validVisible

        return SectionPreferences(order: fullOrder, visibleSections: visible)
    }

    /// 按 order 排序的可见分区列表，至少返回一个。
    var orderedVisible: [Section] {
        let normalized = self.normalized
        return normalized.order.filter { normalized.visibleSections.contains($0) }
    }
}
