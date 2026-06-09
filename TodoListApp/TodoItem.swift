import Foundation

struct FastingLog: Identifiable, Equatable, Codable {
    var id = UUID()
    var date: Date
    var weight: Double
    var note: String
}
