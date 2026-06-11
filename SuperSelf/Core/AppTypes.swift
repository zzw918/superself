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

enum HealthSection: String, CaseIterable, Identifiable {
    case fasting
    case weight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fasting:
            return "16 + 8"
        case .weight:
            return "体重"
        }
    }
}

enum MemoSection: String, CaseIterable, Identifiable {
    case todo
    case wishlist
    case anniversary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todo:
            return "TODO"
        case .wishlist:
            return "愿望清单"
        case .anniversary:
            return "纪念日"
        }
    }
}

enum FinanceSection: String, CaseIterable, Identifiable {
    case assetRecord
    case stockResearch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assetRecord:
            return "资产记录"
        case .stockResearch:
            return "股票研究"
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
            return "备忘录"
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
            return "TODO、愿望清单和纪念日"
        case .finance:
            return "资产记录和股票研究"
        }
    }
}

struct MainTabPreferences: Codable {
    var order: [MainAppTab]
    var visibleTabs: [MainAppTab]
}
