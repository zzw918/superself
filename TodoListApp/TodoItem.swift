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
