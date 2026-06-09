import SwiftUI

struct ContentView: View {
    private let fastingHours = 16
    private let eatingHours = 8

    @AppStorage("fastingStartTime") private var fastingStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("isFasting") private var isFasting = true
    @AppStorage("latestWeight") private var latestWeight = ""
    @AppStorage("dailyGoal") private var dailyGoal = "Drink water, eat protein, walk 20 minutes"

    @State private var now = Date()
    @State private var weightInput = ""

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusCard
                    actionCard
                    weightCard
                    planCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("16:8 Fasting")
            .onReceive(timer) { currentTime in
                now = currentTime
            }
        }
    }

    private var fastingStartDate: Date {
        Date(timeIntervalSince1970: fastingStartTime)
    }

    private var phaseDuration: TimeInterval {
        TimeInterval((isFasting ? fastingHours : eatingHours) * 60 * 60)
    }

    private var elapsed: TimeInterval {
        max(0, now.timeIntervalSince(fastingStartDate))
    }

    private var remaining: TimeInterval {
        max(0, phaseDuration - elapsed)
    }

    private var progress: Double {
        min(1, elapsed / phaseDuration)
    }

    private var phaseEndDate: Date {
        fastingStartDate.addingTimeInterval(phaseDuration)
    }

    private var statusCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(isFasting ? "Fasting Window" : "Eating Window")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(isFasting ? "禁食中" : "进食窗口")
                    .font(.largeTitle.bold())
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isFasting ? Color.blue : Color.green,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(timeString(from: remaining))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("剩余时间")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            HStack {
                Label(startTimeText, systemImage: "play.circle")
                Spacer()
                Label(endTimeText, systemImage: "flag.checkered")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var actionCard: some View {
        VStack(spacing: 12) {
            Button {
                switchPhase()
            } label: {
                Text(isFasting ? "结束禁食，开始 8 小时进食" : "开始 16 小时禁食")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            Button("重置当前阶段") {
                fastingStartTime = Date().timeIntervalSince1970
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体重记录")
                .font(.title3.bold())

            HStack {
                TextField(latestWeight.isEmpty ? "输入今天体重" : latestWeight, text: $weightInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                Button("保存") {
                    saveWeight()
                }
                .buttonStyle(.borderedProminent)
                .disabled(weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !latestWeight.isEmpty {
                Label("最近记录：\(latestWeight) kg", systemImage: "scalemass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日减脂目标")
                .font(.title3.bold())

            TextEditor(text: $dailyGoal)
                .frame(minHeight: 90)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "drop.fill", text: "禁食期可以喝水、无糖茶或黑咖啡。")
                TipRow(icon: "fork.knife", text: "进食窗口优先蛋白质、蔬菜和原型食物。")
                TipRow(icon: "figure.walk", text: "每天保持轻量活动，避免暴食补偿。")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var startTimeText: String {
        "开始 \(fastingStartDate.formatted(date: .omitted, time: .shortened))"
    }

    private var endTimeText: String {
        "结束 \(phaseEndDate.formatted(date: .omitted, time: .shortened))"
    }

    private func switchPhase() {
        isFasting.toggle()
        fastingStartTime = Date().timeIntervalSince1970
    }

    private func saveWeight() {
        let trimmedWeight = weightInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWeight.isEmpty else { return }
        latestWeight = trimmedWeight
        weightInput = ""
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

private struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
