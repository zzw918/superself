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

struct WishlistCategory: Identifiable, Equatable, Hashable, Codable {
    var id: String
    var title: String
    var icon: String

    static let defaultCategories: [WishlistCategory] = [
        WishlistCategory(id: "travel", title: "旅行", icon: "airplane"),
        WishlistCategory(id: "food", title: "美食", icon: "fork.knife"),
        WishlistCategory(id: "reading", title: "阅读", icon: "book.closed"),
        WishlistCategory(id: "movie", title: "电影", icon: "film"),
        WishlistCategory(id: "experience", title: "新体验", icon: "sparkles")
    ]

    static let fallback = WishlistCategory(id: "experience", title: "新体验", icon: "sparkles")

    static func migratedID(from legacyID: String) -> String {
        switch legacyID {
        case "travel":
            return "travel"
        case "food", "drink":
            return "food"
        default:
            return "experience"
        }
    }
}

struct WishlistFilter: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let categoryID: String?

    static let all = WishlistFilter(id: "all", title: "全部", icon: "square.grid.2x2", categoryID: nil)

    init(id: String, title: String, icon: String, categoryID: String?) {
        self.id = id
        self.title = title
        self.icon = icon
        self.categoryID = categoryID
    }

    init(category: WishlistCategory) {
        id = category.id
        title = category.title
        icon = category.icon
        categoryID = category.id
    }
}

struct WishlistItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var categoryID: String
    var createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    init(id: UUID = UUID(), title: String, categoryID: String, createdAt: Date, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.categoryID = categoryID
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case categoryID
        case category
        case createdAt
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        if let categoryID = try container.decodeIfPresent(String.self, forKey: .categoryID) {
            self.categoryID = categoryID
        } else if let legacyCategory = try container.decodeIfPresent(String.self, forKey: .category) {
            self.categoryID = WishlistCategory.migratedID(from: legacyCategory)
        } else {
            categoryID = WishlistCategory.fallback.id
        }
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
    }
}

enum AnniversaryKind: String, CaseIterable, Identifiable, Codable {
    case birthday
    case wedding
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .birthday:
            return "生日"
        case .wedding:
            return "结婚纪念日"
        case .other:
            return "其他"
        }
    }

    var icon: String {
        switch self {
        case .birthday:
            return "birthday.cake"
        case .wedding:
            return "heart.fill"
        case .other:
            return "calendar.badge.heart"
        }
    }
}

enum AnniversaryCalendarKind: String, CaseIterable, Identifiable, Codable {
    case solar
    case lunar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solar:
            return "阳历"
        case .lunar:
            return "阴历"
        }
    }
}

struct AnniversaryItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var kind: AnniversaryKind
    var calendarKind: AnniversaryCalendarKind
    var date: Date
    var createdAt: Date
    var showsElapsedDays: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, kind, calendarKind, date, createdAt, showsElapsedDays
    }

    init(
        id: UUID = UUID(),
        title: String,
        kind: AnniversaryKind,
        calendarKind: AnniversaryCalendarKind,
        date: Date,
        createdAt: Date,
        showsElapsedDays: Bool = false
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.calendarKind = calendarKind
        self.date = date
        self.createdAt = createdAt
        self.showsElapsedDays = showsElapsedDays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        kind = try container.decode(AnniversaryKind.self, forKey: .kind)
        calendarKind = try container.decode(AnniversaryCalendarKind.self, forKey: .calendarKind)
        date = try container.decode(Date.self, forKey: .date)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        showsElapsedDays = try container.decodeIfPresent(Bool.self, forKey: .showsElapsedDays) ?? false
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

enum StockRating: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
}

struct StockResearchItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var thesis: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool = false
    var certainty: StockRating?
    var growth: StockRating?
    var attention: StockRating?
}
