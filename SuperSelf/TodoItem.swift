import Foundation

struct FastingLog: Identifiable, Equatable, Codable {
    var id = UUID()
    var date: Date
    var weight: Double
    var note: String

    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, date, weight, note, updatedAt
    }

    init(
        id: UUID = UUID(),
        date: Date,
        weight: Double,
        note: String,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.note = note
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        weight = try container.decode(Double.self, forKey: .weight)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
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
    var updatedAt: Date?
    var completedAt: Date?
    var priority: TodoPriority = .importantNotUrgent
    var dueDate: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    /// 用于排序与展示的最近活动时间：编辑过取编辑时间，否则取创建时间。
    var lastActivityAt: Date {
        updatedAt ?? createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, updatedAt, completedAt, priority, dueDate
    }

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        completedAt: Date? = nil,
        priority: TodoPriority = .importantNotUrgent,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.priority = priority
        self.dueDate = dueDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        priority = try container.decodeIfPresent(TodoPriority.self, forKey: .priority) ?? .importantNotUrgent
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
    }
}

enum TodoPriority: String, CaseIterable, Identifiable, Codable {
    case importantUrgent
    case importantNotUrgent
    case urgentNotImportant
    case notImportantNotUrgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .importantUrgent: return "重要紧急"
        case .importantNotUrgent: return "重要不紧急"
        case .urgentNotImportant: return "紧急不重要"
        case .notImportantNotUrgent: return "不重要不紧急"
        }
    }

    var icon: String {
        switch self {
        case .importantUrgent: return "flame.fill"
        case .importantNotUrgent: return "star.fill"
        case .urgentNotImportant: return "bolt.fill"
        case .notImportantNotUrgent: return "leaf.fill"
        }
    }
}

struct WishlistCategory: Identifiable, Equatable, Hashable, Codable {
    var id: String
    var title: String
    var icon: String

    static let defaultCategories: [WishlistCategory] = [
        WishlistCategory(id: "travel", title: "旅行", icon: "airplane"),
        WishlistCategory(id: "food", title: "美食", icon: "fork.knife"),
        WishlistCategory(id: "movie", title: "电影", icon: "film"),
        WishlistCategory(id: "reading", title: "阅读", icon: "book.closed"),
        WishlistCategory(id: "music", title: "音乐", icon: "music.note"),
        WishlistCategory(id: "experience", title: "新体验", icon: "sparkles"),
        WishlistCategory(id: "other", title: "其他", icon: "ellipsis.circle")
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
    var updatedAt: Date?
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        categoryID: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.categoryID = categoryID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case categoryID
        case category
        case createdAt
        case updatedAt
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
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
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
    var createdAt: Date
    var updatedAt: Date
    var note: String = ""

    enum CodingKeys: String, CodingKey {
        case id, name, kind, amount, createdAt, updatedAt, note
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: FinanceAssetKind,
        amount: Double,
        createdAt: Date,
        updatedAt: Date,
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.amount = amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decode(FinanceAssetKind.self, forKey: .kind)
        amount = try container.decode(Double.self, forKey: .amount)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? updatedAt
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
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
