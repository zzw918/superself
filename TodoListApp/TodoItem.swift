import Foundation

struct FastingLog: Identifiable, Equatable, Codable {
    var id = UUID()
    var date: Date
    var weight: Double
    var note: String
}

struct FastingSession: Identifiable, Equatable, Codable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var targetHours: Int
    var breakHours: Int
    var completed: Bool
}

struct TodoTask: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }
}

enum WishlistCategory: String, CaseIterable, Identifiable, Codable {
    case travel
    case food
    case drink
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .travel:
            return "去哪玩"
        case .food:
            return "吃什么"
        case .drink:
            return "喝什么"
        case .other:
            return "其他"
        }
    }

    var icon: String {
        switch self {
        case .travel:
            return "airplane"
        case .food:
            return "fork.knife"
        case .drink:
            return "cup.and.saucer"
        case .other:
            return "sparkles"
        }
    }
}

struct WishlistItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var category: WishlistCategory
    var createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }
}

enum FinanceAssetKind: String, CaseIterable, Identifiable, Codable {
    case bankCard
    case stock
    case option
    case alipay
    case wechat
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bankCard:
            return "银行卡"
        case .stock:
            return "股票"
        case .option:
            return "期权"
        case .alipay:
            return "支付宝"
        case .wechat:
            return "微信"
        case .custom:
            return "自定义"
        }
    }

    var icon: String {
        switch self {
        case .bankCard:
            return "creditcard"
        case .stock:
            return "chart.line.uptrend.xyaxis"
        case .option:
            return "chart.bar.xaxis"
        case .alipay:
            return "a.circle"
        case .wechat:
            return "message"
        case .custom:
            return "tag"
        }
    }
}

struct FinanceAsset: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var kind: FinanceAssetKind
    var amount: Double
    var updatedAt: Date
}

struct FinanceSnapshot: Identifiable, Equatable, Codable {
    var id = UUID()
    var date: Date
    var totalAmount: Double
    var assets: [FinanceAsset]
}

struct StockResearchItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var thesis: String
    var createdAt: Date
    var updatedAt: Date
}
