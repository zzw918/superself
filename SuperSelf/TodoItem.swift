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

struct ExerciseGoal: Identifiable, Equatable, Codable {
    var id: UUID
    var title: String
    var targetCount: Int
    var unit: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    static let defaultGoals: [ExerciseGoal] = [
        ExerciseGoal(title: "俯卧撑", targetCount: 5),
        ExerciseGoal(title: "蹲起", targetCount: 5),
        ExerciseGoal(title: "仰卧起坐", targetCount: 5)
    ]

    enum CodingKeys: String, CodingKey {
        case id, title, targetCount, unit, isActive, createdAt, updatedAt
    }

    init(
        id: UUID = UUID(),
        title: String,
        targetCount: Int,
        unit: String = "次",
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetCount = max(1, targetCount)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        self.unit = trimmedUnit.isEmpty ? "次" : trimmedUnit
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "锻炼"
        targetCount = max(1, try container.decodeIfPresent(Int.self, forKey: .targetCount) ?? 5)
        let decodedUnit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "次"
        let trimmedUnit = decodedUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        unit = trimmedUnit.isEmpty ? "次" : trimmedUnit
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

struct ExerciseRecord: Identifiable, Equatable, Codable {
    var id: UUID
    var goalID: UUID
    var date: Date
    var count: Int
    var targetCount: Int?
    var unit: String?
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, goalID, date, count, targetCount, unit, updatedAt
    }

    init(
        id: UUID = UUID(),
        goalID: UUID,
        date: Date,
        count: Int,
        targetCount: Int? = nil,
        unit: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalID = goalID
        self.date = Calendar.current.startOfDay(for: date)
        self.count = max(0, count)
        self.targetCount = targetCount
        self.unit = unit
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        goalID = try container.decode(UUID.self, forKey: .goalID)
        date = Calendar.current.startOfDay(for: try container.decode(Date.self, forKey: .date))
        count = max(0, try container.decodeIfPresent(Int.self, forKey: .count) ?? 0)
        targetCount = try container.decodeIfPresent(Int.self, forKey: .targetCount)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? date
    }
}

struct ExerciseDayNote: Identifiable, Equatable, Codable {
    var id: UUID
    var date: Date
    var content: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date, content, updatedAt
    }

    init(
        id: UUID = UUID(),
        date: Date,
        content: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = Calendar.current.startOfDay(for: try container.decode(Date.self, forKey: .date))
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? date
    }
}

struct ExerciseDayNoteSheetTarget: Identifiable, Equatable {
    let date: Date

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }

    var id: TimeInterval {
        date.timeIntervalSince1970
    }
}

enum TodoTaskStatus: String, CaseIterable, Identifiable, Codable {
    case pending
    case inProgress
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending:
            return "待处理"
        case .inProgress:
            return "进行中"
        case .completed:
            return "已完成"
        }
    }
}

struct TodoTask: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var detail: String = ""
    var createdAt: Date
    var updatedAt: Date?
    var completedAt: Date?
    var status: TodoTaskStatus = .pending
    var priority: TodoPriority = .importantNotUrgent
    var dueDate: Date?
    var isPinned: Bool = false

    var isCompleted: Bool {
        status == .completed
    }

    var isInProgress: Bool {
        status == .inProgress
    }

    /// 用于排序与展示的最近活动时间：编辑过取编辑时间，否则取创建时间。
    var lastActivityAt: Date {
        max(updatedAt ?? createdAt, completedAt ?? .distantPast)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, detail, createdAt, updatedAt, completedAt, status, priority, dueDate, isPinned
    }

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        createdAt: Date,
        updatedAt: Date? = nil,
        completedAt: Date? = nil,
        status: TodoTaskStatus = .pending,
        priority: TodoPriority = .importantNotUrgent,
        dueDate: Date? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.status = completedAt != nil && status == .pending ? .completed : status
        self.priority = priority
        self.dueDate = dueDate
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        status = try container.decodeIfPresent(TodoTaskStatus.self, forKey: .status) ?? (completedAt != nil ? .completed : .pending)
        priority = try container.decodeIfPresent(TodoPriority.self, forKey: .priority) ?? .importantNotUrgent
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}

struct MoodEntry: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var detail: String = ""
    var createdAt: Date
    var updatedAt: Date?

    var content: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (trimmedTitle.isEmpty, trimmedDetail.isEmpty) {
        case (false, true):
            return trimmedTitle
        case (true, false):
            return trimmedDetail
        case (false, false):
            return trimmedTitle + "\n\n" + trimmedDetail
        case (true, true):
            return ""
        }
    }

    var lastActivityAt: Date {
        updatedAt ?? createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, detail, createdAt, updatedAt
    }

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = content
        self.detail = ""
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
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
    var note: String
    var categoryID: String
    var createdAt: Date
    var updatedAt: Date?
    var completedAt: Date?
    var isPinned: Bool = false

    var isCompleted: Bool {
        completedAt != nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        note: String = "",
        categoryID: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        completedAt: Date? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.categoryID = categoryID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.isPinned = isPinned
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case note
        case categoryID
        case category
        case createdAt
        case updatedAt
        case completedAt
        case isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
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
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(note, forKey: .note)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encode(isPinned, forKey: .isPinned)
    }
}

struct MemoNote: Identifiable, Equatable, Codable {
    var id = UUID()
    var content: String
    var tags: [String] = []
    var createdAt: Date
    var updatedAt: Date?
    var imageFileNames: [String] = []
    var isPinned: Bool = false

    var lastActivityAt: Date {
        updatedAt ?? createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case tags
        case createdAt
        case updatedAt
        case imageFileNames
        case isPinned
    }

    init(
        id: UUID = UUID(),
        content: String,
        tags: [String] = [],
        createdAt: Date,
        updatedAt: Date? = nil,
        imageFileNames: [String] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageFileNames = imageFileNames
        self.isPinned = isPinned
    }

    static let reservedTags: Set<String> = ["全部"]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let decodedContent = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        let decodedTags = try container.decodeIfPresent([String].self, forKey: .tags)
        tags = Self.sanitizedTags(decodedTags ?? Self.extractTags(from: decodedContent))
        content = decodedTags == nil ? Self.strippedContent(from: decodedContent, removing: tags) : decodedContent
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        imageFileNames = try container.decodeIfPresent([String].self, forKey: .imageFileNames) ?? []
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    static func extractTags(from text: String) -> [String] {
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let pattern = "#([\\p{L}\\p{N}_-]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        var uniqueTags: [String] = []

        for match in regex.matches(in: text, range: nsRange) {
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text) else { continue }

            let tag = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty, !uniqueTags.contains(tag) else { continue }
            uniqueTags.append(tag)
        }

        return uniqueTags
    }

    static func sanitizedTags(_ tags: [String]) -> [String] {
        var uniqueTags: [String] = []

        for rawTag in tags {
            let tag = rawTag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty,
                  !reservedTags.contains(tag),
                  !uniqueTags.contains(tag) else { continue }
            uniqueTags.append(tag)
        }

        return uniqueTags
    }

    static func strippedContent(from text: String, removing tags: [String]) -> String {
        let stripped = tags.reduce(text) { partial, tag in
            partial.replacingOccurrences(of: "#\(tag)", with: "")
        }

        return stripped
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
    var updatedAt: Date?
    var showsElapsedDays: Bool = false
    var isPinned: Bool = false

    var lastActivityAt: Date {
        updatedAt ?? createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, kind, calendarKind, date, createdAt, updatedAt, showsElapsedDays, isPinned
    }

    init(
        id: UUID = UUID(),
        title: String,
        kind: AnniversaryKind,
        calendarKind: AnniversaryCalendarKind,
        date: Date,
        createdAt: Date,
        updatedAt: Date? = nil,
        showsElapsedDays: Bool = false,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.calendarKind = calendarKind
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.showsElapsedDays = showsElapsedDays
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        kind = try container.decode(AnniversaryKind.self, forKey: .kind)
        calendarKind = try container.decode(AnniversaryCalendarKind.self, forKey: .calendarKind)
        date = try container.decode(Date.self, forKey: .date)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        showsElapsedDays = try container.decodeIfPresent(Bool.self, forKey: .showsElapsedDays) ?? false
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}

enum FinanceAssetKind: String, CaseIterable, Identifiable, Codable {
    case bankCard
    case providentFund
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
        case .providentFund:
            return "公积金"
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
        case .providentFund:
            return "building.columns"
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

struct ExpenseCategory: Identifiable, Equatable, Hashable, Codable {
    var id: String
    var title: String
    var icon: String
    var isDefault: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date?

    static let defaultCategories: [ExpenseCategory] = [
        ExpenseCategory(id: "housing", title: "住房", icon: "house.fill", isDefault: true),
        ExpenseCategory(id: "transport", title: "交通", icon: "car.fill", isDefault: true),
        ExpenseCategory(id: "food", title: "吃饭", icon: "fork.knife", isDefault: true),
        ExpenseCategory(id: "clothing", title: "衣服", icon: "tshirt.fill", isDefault: true),
        ExpenseCategory(id: "phone", title: "话费", icon: "phone.fill", isDefault: true),
        ExpenseCategory(id: "travel", title: "旅游", icon: "airplane", isDefault: true),
        ExpenseCategory(id: "fun", title: "玩乐", icon: "gamecontroller.fill", isDefault: true),
        ExpenseCategory(id: "other", title: "其他", icon: "ellipsis.circle.fill", isDefault: true)
    ]

    static let fallback = ExpenseCategory(id: "other", title: "其他", icon: "ellipsis.circle.fill", isDefault: true)

    enum CodingKeys: String, CodingKey {
        case id, title, icon, isDefault, createdAt, updatedAt
    }

    init(
        id: String,
        title: String,
        icon: String,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "tag.fill"
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

struct ExpenseRecord: Identifiable, Equatable, Codable {
    var id = UUID()
    var amount: Double
    var categoryID: String
    var date: Date
    var note: String = ""
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, amount, categoryID, date, note, createdAt, updatedAt
    }

    init(
        id: UUID = UUID(),
        amount: Double,
        categoryID: String,
        date: Date,
        note: String = "",
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.amount = amount
        self.categoryID = categoryID
        self.date = date
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        amount = try container.decode(Double.self, forKey: .amount)
        categoryID = try container.decodeIfPresent(String.self, forKey: .categoryID) ?? ExpenseCategory.fallback.id
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? date
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
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
