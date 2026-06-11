import SwiftUI

extension ContentView {
    var statusCard: some View {
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

    var actionCard: some View {
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

            Button {
                resetCurrentPhase()
            } label: {
                Label("重置当前阶段", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var fastingHistoryCard: some View {
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

    var syncCard: some View {
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

    var weightCard: some View {
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

                    Text("最近：\(chineseDateTime(latestWeightLog.date))")
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

    var addWeightSheet: some View {
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

    var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体重趋势")
                .font(.title3.bold())

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

    var bmiCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("体重目标")
                    .font(.title3.bold())
                Spacer()
                Button {
                    isShowingBodySettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("目标体重")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let targetWeightValue {
                    Text("\(weightText(targetWeightValue)) kg")
                        .font(.title2.bold())
                } else {
                    Text("未设置")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: targetProgressIcon)
                    Text(targetProgressText)
                }
                .font(.caption.bold())
                .foregroundStyle(targetProgressColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(targetProgressColor.opacity(0.12))
                .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(bmiStatusText)
                            .font(.headline)

                        if let bmiValue {
                            Text("BMI \(String(format: "%.1f", bmiValue))")
                                .font(.subheadline.bold())
                                .foregroundStyle(bmiColor(for: bmiValue))
                        }
                    }
                    
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
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var bodySettingsSheet: some View {
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

    var historyCard: some View {
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
                        WeightLogRow(log: log, weightText: weightText(log.weight), dateText: chineseDateTime(log.date)) {
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

    var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日减脂目标")
                .font(.title3.bold())

            TextEditor(text: $dailyGoal)
                .frame(minHeight: 90)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var startTimeText: String {
        "开始 \(relativeTimeText(for: fastingStartDate))"
    }

    var endTimeText: String {
        "结束 \(relativeTimeText(for: phaseEndDate))"
    }

    var primaryActionTitle: String {
        if isFasting {
            return hasReachedCurrentGoal ? "已达标，可以吃饭了" : "还没到点，先忍一忍"
        }

        return "吃完了，开始 \(fastingGoalHours) 小时计划"
    }

    var primaryActionTint: Color {
        if isFasting {
            return hasReachedCurrentGoal ? .green : .orange
        }

        return .blue
    }

    var planSelection: Binding<Int> {
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

    var weightPlaceholder: String {
        if let latestWeightLog {
            return "上次 \(weightText(latestWeightLog.weight)) kg"
        }

        return latestWeight.isEmpty ? "输入今天体重" : latestWeight
    }

    var changeText: String? {
        guard let firstPoint = trendPoints.first,
              let lastPoint = trendPoints.last,
              firstPoint.id != lastPoint.id else {
            return nil
        }

        let change = lastPoint.weight - firstPoint.weight
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(weightText(change)) kg"
    }

    func averagedTrendPoints(
        groupedBy keyForLog: (FastingLog) -> Date,
        labelFor: (Date) -> (String, String)
    ) -> [WeightTrendPoint] {
        let groupedLogs = Dictionary(grouping: weightLogs, by: keyForLog)

        let points = groupedLogs.map { date, logs in
            let averageWeight = logs.map(\.weight).reduce(0, +) / Double(logs.count)
            let labels = labelFor(date)

            return WeightTrendPoint(
                date: date,
                weight: averageWeight,
                topLabel: labels.0,
                bottomLabel: labels.1
            )
        }

        return Array(points.sorted { $0.date < $1.date }.suffix(30))
    }

    func bmiColor(for bmi: Double) -> Color {
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

    func switchPhase() {
        if isFasting {
            recordCurrentFastingSession(endDate: Date())
        }

        isFasting.toggle()
        fastingStartTime = Date().timeIntervalSince1970
        persistSettingsToICloud()
    }

    func resetCurrentPhase() {
        fastingStartTime = Date().timeIntervalSince1970
        persistSettingsToICloud()
    }

    func prepareWeightSheet() {
        weightInput = ""
        noteInput = ""
    }

    func saveWeight() {
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

    func seedMockWeightLogs() {
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
}
