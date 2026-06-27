import Foundation

struct ExerciseGoal: Codable {
    var id: UUID
    var title: String
    var targetCount: Int
    var unit: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct ExerciseRecord: Codable {
    var id: UUID
    var goalID: UUID
    var date: Date
    var count: Int
    var targetCount: Int?
    var unit: String?
    var updatedAt: Date
}

let defaults = UserDefaults.standard
if let data = defaults.data(forKey: "exerciseGoals"),
   let goals = try? JSONDecoder().decode([ExerciseGoal].self, from: data) {
    print("Goals: \(goals.count)")
    for goal in goals {
        print("- \(goal.title): target=\(goal.targetCount), active=\(goal.isActive)")
    }
}

if let data = defaults.data(forKey: "exerciseRecords"),
   let records = try? JSONDecoder().decode([ExerciseRecord].self, from: data) {
    print("Records: \(records.count)")
    for record in records {
        print("- goal=\(record.goalID), count=\(record.count), target=\(String(describing: record.targetCount))")
    }
}
