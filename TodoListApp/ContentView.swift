import SwiftUI

private enum WeightTrendGranularity: String, CaseIterable, Identifiable {
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

private struct WeightTrendPoint: Identifiable {
    let date: Date
    let weight: Double
    let label: String

    var id: String {
        "\(date.timeIntervalSince1970)-\(label)"
    }
}

struct ContentView: View {
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let fastingStartTimeCloudKey = "fastingStartTime"
    private let isFastingCloudKey = "isFasting"
    private let latestWeightCloudKey = "latestWeight"
    private let weightLogsCloudKey = "weightLogs"
    private let fastingSessionsCloudKey = "fastingSessions"
    private let fastingGoalHoursCloudKey = "fastingGoalHours"
    private let eatingGoalHoursCloudKey = "eatingGoalHours"
    private let dailyGoalCloudKey = "dailyGoal"
    private let planOptions = [(fasting: 16, eating: 8), (fasting: 18, eating: 6), (fasting: 20, eating: 4)]
    private let isoCalendar = Calendar(identifier: .iso8601)

    @AppStorage("fastingStartTime") private var fastingStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("isFasting") private var isFasting = true
    @AppStorage("fastingGoalHours") private var fastingGoalHours = 16
    @AppStorage("eatingGoalHours") private var eatingGoalHours = 8
    @AppStorage("latestWeight") private var latestWeight = ""
    @AppStorage("weightLogs") private var weightLogsData = Data()
    @AppStorage("fastingSessions") private var fastingSessionsData = Data()
    @AppStorage("dailyGoal") private var dailyGoal = "Drink water, eat protein, walk 20 minutes"
    @AppStorage("heightCm") private var heightCm = ""
    @AppStorage("targetWeight") private var targetWeight = ""

    @State private var now = Date()
    @State private var weightInput = ""
    @State private var noteInput = ""
    @State private var weightLogs: [FastingLog] = []
    @State private var fastingSessions: [FastingSession] = []
    @State private var syncStatus = "iCloud 同步准备中"
    @State private var isShowingWeightSheet = false
    @State private var isShowingBodySettings = false
    @State private var trendGranularity: WeightTrendGranularity = .day
    @State private var visibleWeightHistoryDays = 10

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            fastingPage
                .tabItem {
                    Label("16 + 8", systemImage: "timer")
                }

            weightPage
                .tabItem {
                    Label("体重", systemImage: "scalemass")
                }
        }
        .onReceive(timer) { currentTime in
            now = currentTime
        }
        .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
            pullFromICloud()
        }
        .onAppear(perform: loadAppData)
        .onChange(of: dailyGoal) {
            persistSettingsToICloud()
        }
        .onChange(of: fastingGoalHours) {
            persistSettingsToICloud()
        }
        .onChange(of: eatingGoalHours) {
            persistSettingsToICloud()
        }
        .sheet(isPresented: $isShowingWeightSheet) {
            addWeightSheet
        }
        .sheet(isPresented: $isShowingBodySettings) {
            bodySettingsSheet
        }
    }

    private var fastingPage: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusCard
                    actionCard
                    fastingHistoryCard
                    planCard
                    syncCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(fastingGoalHours)+\(eatingGoalHours) 计划")
        }
    }

    private var weightPage: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weightCard
                    bmiCard
                    trendCard
                    historyCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("体重")
            .onDisappear {
                visibleWeightHistoryDays = 10
            }
        }
    }

    private var fastingStartDate: Date {
        Date(timeIntervalSince1970: fastingStartTime)
    }

    private var phaseDuration: TimeInterval {
        TimeInterval((isFasting ? fastingGoalHours : eatingGoalHours) * 60 * 60)
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

    private var hasReachedCurrentGoal: Bool {
        elapsed >= phaseDuration
    }

    private var phaseEndDate: Date {
        fastingStartDate.addingTimeInterval(phaseDuration)
    }

    private var sortedWeightLogs: [FastingLog] {
        weightLogs.sorted { $0.date > $1.date }
    }

    private var latestWeightLog: FastingLog? {
        sortedWeightLogs.first
    }

    private var oldestWeightLog: FastingLog? {
        sortedWeightLogs.last
    }

    private var sortedFastingSessions: [FastingSession] {
        fastingSessions.sorted { $0.endDate > $1.endDate }
    }

    private var dailyTrendLogs: [FastingLog] {
        let logsByDay = Dictionary(grouping: weightLogs) { log in
            Calendar.current.startOfDay(for: log.date)
        }

        let latestLogPerDay = logsByDay.values.compactMap { logs in
            logs.max { $0.date < $1.date }
        }

        return Array(latestLogPerDay.sorted { $0.date < $1.date }.suffix(30))
    }

    private var trendPoints: [WeightTrendPoint] {
        switch trendGranularity {
        case .day:
            return dailyTrendLogs.map { log in
                WeightTrendPoint(
                    date: log.date,
                    weight: log.weight,
                    label: log.date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
                )
            }
        case .week:
            return averagedTrendPoints(groupedBy: { log in
                isoCalendar.dateInterval(of: .weekOfYear, for: log.date)?.start ?? Calendar.current.startOfDay(for: log.date)
            }, labelFor: { date in
                "周\(date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits)))"
            })
        case .month:
            return averagedTrendPoints(groupedBy: { log in
                Calendar.current.dateInterval(of: .month, for: log.date)?.start ?? Calendar.current.startOfDay(for: log.date)
            }, labelFor: { date in
                date.formatted(.dateTime.year(.twoDigits).month(.defaultDigits))
            })
        }
    }

    private var displayedWeightLogs: [FastingLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoffDate = calendar.date(byAdding: .day, value: -(visibleWeightHistoryDays - 1), to: today) ?? today

        return sortedWeightLogs.filter { $0.date >= cutoffDate }
    }

    private var bmiValue: Double? {
        guard let height = Double(heightCm.replacingOccurrences(of: ",", with: ".")),
              let weight = latestWeightLog?.weight,
              height > 0 else {
            return nil
        }

        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }

    private var targetWeightValue: Double? {
        Double(targetWeight.replacingOccurrences(of: ",", with: "."))
    }

    private var bmiStatusText: String {
        guard let bmiValue else { return "录入身高和体重后显示 BMI" }

        switch bmiValue {
        case ..<18.5:
            return "偏瘦"
        case 18.5..<24:
            return "正常"
        case 24..<28:
            return "偏胖"
        default:
            return "肥胖"
        }
    }

    private var statusCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(isFasting ? "\(fastingGoalHours) 小时挑战" : "\(eatingGoalHours) 小时吃饭时间")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(isFasting ? "先忍住不吃" : "可以吃饭啦")
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
                    Text(isFasting ? "再坚持一下" : "吃饭时间还剩")
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
                Text(primaryActionTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(primaryActionTint)

            Picker("计划模式", selection: planSelection) {
                ForEach(planOptions, id: \.fasting) { option in
                    Text("\(option.fasting)+\(option.eating)")
                        .tag(option.fasting)
                }
            }
            .pickerStyle(.segmented)

            Button("重置当前阶段") {
                resetCurrentPhase()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var fastingHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("计划记录")
                    .font(.title3.bold())
                Spacer()
                Text("\(fastingSessions.count) 次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sortedFastingSessions.isEmpty {
                Text("每次从“不吃东西”切到“准备吃饭”后，这里会记一条完成情况。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedFastingSessions.prefix(8)) { session in
                        FastingSessionRow(session: session)

                        if session.id != sortedFastingSessions.prefix(8).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var syncCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "icloud")
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("iCloud 同步")
                    .font(.headline)
                Text(syncStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("立即同步") {
                pushAllToICloud()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var weightCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("体重记录")
                    .font(.title3.bold())

                if let latestWeightLog {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(weightText(latestWeightLog.weight))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("kg")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Text("最近：\(latestWeightLog.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("还没有体重记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                prepareWeightSheet()
                isShowingWeightSheet = true
            } label: {
                Label("添加", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var addWeightSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("今天体重")
                        .font(.title2.bold())

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        TextField("67.8", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        Text("kg")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    TextField("可选，例如：空腹、运动后", text: $noteInput, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                }

                Text("体重会保存到本地历史记录，并在 iCloud 可用时尝试同步。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    saveWeight()
                } label: {
                    Text("保存体重")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingWeightSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("体重趋势")
                    .font(.title3.bold())
                Spacer()
                if let changeText {
                    Text(changeText)
                        .font(.subheadline.bold())
                        .foregroundStyle(changeText.hasPrefix("-") ? .green : .orange)
                }
            }

            Picker("趋势粒度", selection: $trendGranularity) {
                ForEach(WeightTrendGranularity.allCases) { granularity in
                    Text(granularity.title)
                        .tag(granularity)
                }
            }
            .pickerStyle(.segmented)

            if trendPoints.count >= 2 {
                WeightTrendView(points: trendPoints, targetWeight: targetWeightValue)
                    .frame(height: 120)
            } else {
                ContentUnavailableView(
                    "还没有趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("至少保存 2 个\(trendGranularity.title)粒度记录后会显示趋势。")
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            }

            Button {
                seedMockWeightLogs()
            } label: {
                Label("生成 30 天示例体重", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var bmiCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("体重目标")
                    .font(.title3.bold())
                Spacer()
                Button {
                    isShowingBodySettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.bordered)

                if let bmiValue {
                    Text("BMI \(String(format: "%.1f", bmiValue))")
                        .font(.subheadline.bold())
                        .foregroundStyle(bmiColor(for: bmiValue))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("目标体重")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let targetWeightValue {
                    Text("\(weightText(targetWeightValue)) kg")
                        .font(.title2.bold())
                } else {
                    Text("未设置")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(bmiStatusText)
                        .font(.headline)
                    Spacer()
                    if let latestWeightLog {
                        Text("当前 \(weightText(latestWeightLog.weight)) kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                BMIRangeBar(bmi: bmiValue)

                HStack {
                    Text("偏瘦 <18.5")
                    Spacer()
                    Text("正常 18.5-24")
                    Spacer()
                    Text("偏胖 24-28")
                    Spacer()
                    Text("肥胖 ≥28")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var bodySettingsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("体重目标")
                        .font(.title2.bold())

                    Text("身高和目标体重通常很少变化，设置好之后首页只展示目标体重和 BMI。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    MeasurementField(title: "身高", value: $heightCm, placeholder: "175", unit: "cm")
                    MeasurementField(title: "目标体重", value: $targetWeight, placeholder: "65", unit: "kg")
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("体重目标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingBodySettings = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isShowingBodySettings = false
                    }
                }
            }
        }
        .presentationDetents([.height(360)])
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("体重历史")
                    .font(.title3.bold())
                Spacer()
                Text("\(weightLogs.count) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sortedWeightLogs.isEmpty {
                Text("保存体重后，这里会显示历史记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(displayedWeightLogs) { log in
                        WeightLogRow(log: log, weightText: weightText(log.weight)) {
                            deleteWeightLog(log)
                        }

                        if log.id != displayedWeightLogs.last?.id {
                            Divider()
                        }
                    }
                }

                if displayedWeightLogs.count < sortedWeightLogs.count {
                    Button {
                        visibleWeightHistoryDays += 10
                    } label: {
                        Text("查看更多")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
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
                TipRow(icon: "drop.fill", text: "不吃东西这段时间，可以喝水、无糖茶或黑咖啡。")
                TipRow(icon: "fork.knife", text: "吃饭这 \(eatingGoalHours) 小时，优先吃蛋白质、蔬菜和原型食物。")
                TipRow(icon: "figure.walk", text: "每天保持轻量活动，避免暴食补偿。")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var startTimeText: String {
        "开始 \(relativeTimeText(for: fastingStartDate))"
    }

    private var endTimeText: String {
        "结束 \(relativeTimeText(for: phaseEndDate))"
    }

    private var primaryActionTitle: String {
        if isFasting {
            return hasReachedCurrentGoal ? "已达标，可以吃饭了" : "还没到点，先忍一忍"
        }

        return "吃完了，开始 \(fastingGoalHours) 小时计划"
    }

    private var primaryActionTint: Color {
        if isFasting {
            return hasReachedCurrentGoal ? .green : .orange
        }

        return .blue
    }

    private var planSelection: Binding<Int> {
        Binding(
            get: { fastingGoalHours },
            set: { newFastingHours in
                if let option = planOptions.first(where: { $0.fasting == newFastingHours }) {
                    fastingGoalHours = option.fasting
                    eatingGoalHours = option.eating
                }
            }
        )
    }

    private var weightPlaceholder: String {
        if let latestWeightLog {
            return "上次 \(weightText(latestWeightLog.weight)) kg"
        }

        return latestWeight.isEmpty ? "输入今天体重" : latestWeight
    }

    private var changeText: String? {
        guard let firstPoint = trendPoints.first,
              let lastPoint = trendPoints.last,
              firstPoint.id != lastPoint.id else {
            return nil
        }

        let change = lastPoint.weight - firstPoint.weight
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(weightText(change)) kg"
    }

    private func averagedTrendPoints(
        groupedBy keyForLog: (FastingLog) -> Date,
        labelFor: (Date) -> String
    ) -> [WeightTrendPoint] {
        let groupedLogs = Dictionary(grouping: weightLogs, by: keyForLog)

        let points = groupedLogs.map { date, logs in
            let averageWeight = logs.map(\.weight).reduce(0, +) / Double(logs.count)

            return WeightTrendPoint(date: date, weight: averageWeight, label: labelFor(date))
        }

        return Array(points.sorted { $0.date < $1.date }.suffix(30))
    }

    private func bmiColor(for bmi: Double) -> Color {
        switch bmi {
        case ..<18.5:
            return .blue
        case 18.5..<24:
            return .green
        case 24..<28:
            return .orange
        default:
            return .red
        }
    }

    private func switchPhase() {
        if isFasting {
            recordCurrentFastingSession(endDate: Date())
        }

        isFasting.toggle()
        fastingStartTime = Date().timeIntervalSince1970
        persistSettingsToICloud()
    }

    private func resetCurrentPhase() {
        fastingStartTime = Date().timeIntervalSince1970
        persistSettingsToICloud()
    }

    private func prepareWeightSheet() {
        weightInput = ""
        noteInput = ""
    }

    private func saveWeight() {
        let trimmedWeight = weightInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWeight = trimmedWeight.replacingOccurrences(of: ",", with: ".")

        guard let weight = Double(normalizedWeight) else { return }

        let trimmedNote = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let log = FastingLog(date: Date(), weight: weight, note: trimmedNote)

        weightLogs.insert(log, at: 0)
        latestWeight = weightText(weight)
        persistWeightLogs()
        weightInput = ""
        noteInput = ""
        isShowingWeightSheet = false
    }

    private func seedMockWeightLogs() {
        let calendar = Calendar.current

        weightLogs = (0..<30).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()),
                  let date = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: day) else {
                return nil
            }

            let fluctuation = sin(Double(dayOffset) * 0.7) * 1.4 + sin(Double(dayOffset) * 0.23) * 0.8
            let weight = min(70, max(65, 67.5 + fluctuation))

            return FastingLog(date: date, weight: weight, note: "示例数据")
        }

        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? ""
        visibleWeightHistoryDays = 10
        persistWeightLogs()
    }

    private func loadAppData() {
        loadWeightLogs()
        loadFastingSessions()
        pullFromICloud()
        pushAllToICloud()
    }

    private func loadWeightLogs() {
        guard !weightLogsData.isEmpty else {
            migrateLatestWeightIfNeeded()
            return
        }

        if let decodedLogs = try? JSONDecoder().decode([FastingLog].self, from: weightLogsData) {
            weightLogs = decodedLogs
            latestWeight = latestWeightLog.map { weightText($0.weight) } ?? latestWeight
        }
    }

    private func migrateLatestWeightIfNeeded() {
        let normalizedWeight = latestWeight.replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(normalizedWeight), weightLogs.isEmpty else { return }

        weightLogs = [FastingLog(date: Date(), weight: weight, note: "历史最近记录")]
        persistWeightLogs()
    }

    private func persistWeightLogs() {
        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            weightLogsData = encodedLogs
            cloudStore.set(encodedLogs, forKey: weightLogsCloudKey)
            persistSettingsToICloud()
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func deleteWeightLog(_ log: FastingLog) {
        weightLogs.removeAll { $0.id == log.id }
        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? ""
        persistWeightLogs()
    }

    private func loadFastingSessions() {
        guard !fastingSessionsData.isEmpty else { return }

        if let decodedSessions = try? JSONDecoder().decode([FastingSession].self, from: fastingSessionsData) {
            fastingSessions = decodedSessions
        }
    }

    private func recordCurrentFastingSession(endDate: Date) {
        let session = FastingSession(
            startDate: fastingStartDate,
            endDate: endDate,
            targetHours: fastingGoalHours,
            breakHours: eatingGoalHours,
            completed: endDate.timeIntervalSince(fastingStartDate) >= TimeInterval(fastingGoalHours * 60 * 60)
        )

        fastingSessions.insert(session, at: 0)
        persistFastingSessions()
    }

    private func persistFastingSessions() {
        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            fastingSessionsData = encodedSessions
            cloudStore.set(encodedSessions, forKey: fastingSessionsCloudKey)
            persistSettingsToICloud()
            syncStatus = cloudStore.synchronize() ? "已保存并请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
        }
    }

    private func pullFromICloud() {
        cloudStore.synchronize()

        if let cloudLogsData = cloudStore.data(forKey: weightLogsCloudKey),
           let cloudLogs = try? JSONDecoder().decode([FastingLog].self, from: cloudLogsData) {
            mergeWeightLogs(cloudLogs)
        }

        if let cloudSessionsData = cloudStore.data(forKey: fastingSessionsCloudKey),
           let cloudSessions = try? JSONDecoder().decode([FastingSession].self, from: cloudSessionsData) {
            mergeFastingSessions(cloudSessions)
        }

        if cloudStore.object(forKey: fastingStartTimeCloudKey) != nil {
            fastingStartTime = cloudStore.double(forKey: fastingStartTimeCloudKey)
        }

        if cloudStore.object(forKey: isFastingCloudKey) != nil {
            isFasting = cloudStore.bool(forKey: isFastingCloudKey)
        }

        if cloudStore.object(forKey: fastingGoalHoursCloudKey) != nil {
            fastingGoalHours = Int(cloudStore.longLong(forKey: fastingGoalHoursCloudKey))
        }

        if cloudStore.object(forKey: eatingGoalHoursCloudKey) != nil {
            eatingGoalHours = Int(cloudStore.longLong(forKey: eatingGoalHoursCloudKey))
        }

        if let cloudLatestWeight = cloudStore.string(forKey: latestWeightCloudKey), !cloudLatestWeight.isEmpty {
            latestWeight = cloudLatestWeight
        }

        if let cloudDailyGoal = cloudStore.string(forKey: dailyGoalCloudKey), !cloudDailyGoal.isEmpty {
            dailyGoal = cloudDailyGoal
        }

        syncStatus = "已从 iCloud 检查更新"
    }

    private func pushAllToICloud() {
        persistSettingsToICloud()

        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            cloudStore.set(encodedLogs, forKey: weightLogsCloudKey)
        }

        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            cloudStore.set(encodedSessions, forKey: fastingSessionsCloudKey)
        }

        syncStatus = cloudStore.synchronize() ? "已请求同步到 iCloud" : "已本地保存，iCloud 暂不可用"
    }

    private func persistSettingsToICloud() {
        cloudStore.set(fastingStartTime, forKey: fastingStartTimeCloudKey)
        cloudStore.set(isFasting, forKey: isFastingCloudKey)
        cloudStore.set(Int64(fastingGoalHours), forKey: fastingGoalHoursCloudKey)
        cloudStore.set(Int64(eatingGoalHours), forKey: eatingGoalHoursCloudKey)
        cloudStore.set(latestWeight, forKey: latestWeightCloudKey)
        cloudStore.set(dailyGoal, forKey: dailyGoalCloudKey)
    }

    private func mergeWeightLogs(_ cloudLogs: [FastingLog]) {
        var mergedLogsByID = Dictionary(uniqueKeysWithValues: weightLogs.map { ($0.id, $0) })

        for log in cloudLogs {
            mergedLogsByID[log.id] = log
        }

        weightLogs = mergedLogsByID.values.sorted { $0.date > $1.date }

        if let encodedLogs = try? JSONEncoder().encode(weightLogs) {
            weightLogsData = encodedLogs
        }

        latestWeight = latestWeightLog.map { weightText($0.weight) } ?? latestWeight
    }

    private func mergeFastingSessions(_ cloudSessions: [FastingSession]) {
        var mergedSessionsByID = Dictionary(uniqueKeysWithValues: fastingSessions.map { ($0.id, $0) })

        for session in cloudSessions {
            mergedSessionsByID[session.id] = session
        }

        fastingSessions = mergedSessionsByID.values.sorted { $0.endDate > $1.endDate }

        if let encodedSessions = try? JSONEncoder().encode(fastingSessions) {
            fastingSessionsData = encodedSessions
        }
    }

    private func relativeTimeText(for date: Date) -> String {
        let calendar = Calendar.current
        let dayText: String

        if calendar.isDateInToday(date) {
            dayText = "今天"
        } else if calendar.isDateInYesterday(date) {
            dayText = "昨天"
        } else if calendar.isDateInTomorrow(date) {
            dayText = "明天"
        } else {
            dayText = date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
        }

        return "\(dayText) \(date.formatted(date: .omitted, time: .shortened))"
    }

    private func durationText(from startDate: Date, to endDate: Date) -> String {
        let totalMinutes = max(0, Int(endDate.timeIntervalSince(startDate) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours) 小时"
        }

        return "\(hours) 小时 \(minutes) 分钟"
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func weightText(_ weight: Double) -> String {
        String(format: "%.1f", weight)
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

private struct WeightLogRow: View {
    let log: FastingLog
    let weightText: String
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "scalemass")
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(weightText) kg")
                    .font(.headline)

                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !log.note.isEmpty {
                    Text(log.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}

private struct FastingSessionRow: View {
    let session: FastingSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: session.completed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(session.completed ? .green : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(session.targetHours)+\(session.breakHours)")
                        .font(.headline)

                    Text(session.completed ? "已达标" : "提前结束")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(session.completed ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundStyle(session.completed ? .green : .orange)
                        .clipShape(Capsule())
                }

                Text("\(relativeTimeText(for: session.startDate)) - \(relativeTimeText(for: session.endDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("坚持了 \(durationText(from: session.startDate, to: session.endDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func relativeTimeText(for date: Date) -> String {
        let calendar = Calendar.current
        let dayText: String

        if calendar.isDateInToday(date) {
            dayText = "今天"
        } else if calendar.isDateInYesterday(date) {
            dayText = "昨天"
        } else if calendar.isDateInTomorrow(date) {
            dayText = "明天"
        } else {
            dayText = date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
        }

        return "\(dayText) \(date.formatted(date: .omitted, time: .shortened))"
    }

    private func durationText(from startDate: Date, to endDate: Date) -> String {
        let totalMinutes = max(0, Int(endDate.timeIntervalSince(startDate) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours) 小时"
        }

        return "\(hours) 小时 \(minutes) 分钟"
    }
}

private struct MeasurementField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField(placeholder, text: $value)
                    .keyboardType(.decimalPad)
                    .font(.headline)
                Text(unit)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct BMIRangeBar: View {
    let bmi: Double?

    private let minBMI = 15.0
    private let maxBMI = 32.0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Color.blue.opacity(0.7)
                    Color.green.opacity(0.8)
                    Color.orange.opacity(0.8)
                    Color.red.opacity(0.75)
                }
                .clipShape(Capsule())

                if let bmi {
                    Circle()
                        .fill(.primary)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                        }
                        .offset(x: markerOffset(for: bmi, width: proxy.size.width))
                }
            }
        }
        .frame(height: 14)
    }

    private func markerOffset(for bmi: Double, width: CGFloat) -> CGFloat {
        let clampedBMI = min(maxBMI, max(minBMI, bmi))
        let ratio = (clampedBMI - minBMI) / (maxBMI - minBMI)
        return max(0, min(width - 14, CGFloat(ratio) * width - 7))
    }
}

private struct WeightTrendView: View {
    let points: [WeightTrendPoint]
    let targetWeight: Double?

    private let chartHeight: CGFloat = 78
    private let pointWidth: CGFloat = 42
    private let pointSpacing: CGFloat = 8

    private var weights: [Double] {
        if let targetWeight {
            return points.map(\.weight) + [targetWeight]
        }

        return points.map(\.weight)
    }

    private var minWeight: Double {
        weights.min() ?? 0
    }

    private var maxWeight: Double {
        weights.max() ?? 1
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                HStack(alignment: .bottom, spacing: pointSpacing) {
                    ForEach(points) { point in
                        VStack(spacing: 6) {
                            Text(String(format: "%.1f", point.weight))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            ZStack(alignment: .bottom) {
                                Color.clear
                                    .frame(height: chartHeight)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.gradient)
                                    .frame(height: barHeight(for: point.weight))
                            }

                            Text(point.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: pointWidth)
                    }
                }
                .padding(.top, 8)

                if let targetWeight {
                    targetLine(for: targetWeight)
                        .offset(y: targetLineOffset(for: targetWeight))
                }
            }
        }
    }

    private func barHeight(for weight: Double) -> CGFloat {
        guard maxWeight > minWeight else { return chartHeight * 0.7 }

        let ratio = (weight - minWeight) / (maxWeight - minWeight)
        return CGFloat(24 + ratio * Double(chartHeight - 24))
    }

    private func targetLineOffset(for targetWeight: Double) -> CGFloat {
        8 + 14 + chartHeight - barHeight(for: targetWeight)
    }

    private func targetLine(for targetWeight: Double) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(.orange)
                .frame(width: max(0, CGFloat(points.count) * (pointWidth + pointSpacing) - pointSpacing), height: 1)

            Text("目标 \(String(format: "%.1f", targetWeight))")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
