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
            }
            .buttonStyle(AppPrimaryButtonStyle(tint: primaryActionTint))

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
            .buttonStyle(AppSecondaryButtonStyle(tint: .blue))
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
            }
            .buttonStyle(AppPrimaryButtonStyle(tint: .blue, isFullWidth: false))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var addWeightSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今天体重")
                        .font(.title2.bold())

                    Text("记录当前体重，趋势和 BMI 会自动更新。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("当前体重")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        ZStack(alignment: .leading) {
                            if weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(weightPlaceholder)
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }

                            TextField("", text: $weightInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .focused($focusedWeightSheetField, equals: .weight)
                        }

                        Text("kg")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 6)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            focusedWeightSheetField == .weight ? Color.blue.opacity(0.55) : Color(.separator).opacity(0.14),
                            lineWidth: focusedWeightSheetField == .weight ? 1.5 : 1
                        )
                }
                .shadow(
                    color: focusedWeightSheetField == .weight ? Color.blue.opacity(0.12) : .clear,
                    radius: 14,
                    y: 6
                )

                if let latestWeightLog {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("上次记录")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(weightText(latestWeightLog.weight)) kg · \(chineseDateTime(latestWeightLog.date))")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Button("填入上次") {
                            weightInput = weightText(latestWeightLog.weight)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.10))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble")
                            .font(.caption.weight(.semibold))
                        Text("备注")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if noteInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("可选，例如空腹、运动后、晚饭前")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 14)
                                .padding(.horizontal, 14)
                        }

                        TextEditor(text: $noteInput)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 96)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .focused($focusedWeightSheetField, equals: .note)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                focusedWeightSheetField == .note ? Color.blue.opacity(0.55) : Color(.separator).opacity(0.14),
                                lineWidth: focusedWeightSheetField == .note ? 1.5 : 1
                            )
                    }
                    .shadow(
                        color: focusedWeightSheetField == .note ? Color.blue.opacity(0.10) : .clear,
                        radius: 12,
                        y: 6
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(weightNoteSuggestions, id: \.self) { suggestion in
                                Button {
                                    applyWeightNoteSuggestion(suggestion)
                                } label: {
                                    Text(suggestion)
                                        .font(.caption.bold())
                                        .foregroundStyle(hasWeightNoteSuggestion(suggestion) ? .blue : .secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            hasWeightNoteSuggestion(suggestion)
                                            ? Color.blue.opacity(0.12)
                                            : Color(.tertiarySystemFill)
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Label("体重会保存到本地历史记录，并在 iCloud 可用时尝试同步。", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    saveWeight()
                } label: {
                    HStack(spacing: 8) {
                        if didShowWeightSaveFeedback {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.headline)
                        }

                        Text(didShowWeightSaveFeedback ? "已保存" : "保存体重")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? [Color(.tertiarySystemFill), Color(.tertiarySystemFill)]
                                    : [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(
                            color: weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .clear
                                : Color.blue.opacity(0.22),
                            radius: 14,
                            y: 8
                        )
                }
                .buttonStyle(.plain)
                .disabled(weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .overlay(alignment: .top) {
                if didShowWeightSaveFeedback {
                    Label("体重已保存", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("添加体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingWeightSheet = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                focusedWeightSheetField = .weight
                didShowWeightSaveFeedback = false
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.88), value: focusedWeightSheetField)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: didShowWeightSaveFeedback)
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
                AppEmptyState(
                    title: "还没有趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: "至少保存 2 个\(trendGranularity.title)粒度记录后会显示趋势。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            }

            Button {
                seedMockWeightLogs()
            } label: {
                Label("生成 30 天示例体重", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppSecondaryButtonStyle(tint: .blue, isFullWidth: true))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var bmiCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("体重目标")
                        .font(.title3.bold())

                    Text("填写身高、目标体重，并记录一次当前体重后，这里会自动显示进度和 BMI。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingBodySettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(width: 38, height: 38)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 12) {
                healthSummaryTile(
                    title: "目标体重",
                    value: targetWeightValue.map { "\(weightText($0)) kg" } ?? "未设置",
                    detail: targetWeightValue == nil ? "建议先定一个舒服、能坚持的目标。" : "修改后会自动刷新首页进度。",
                    tint: .blue,
                    isPlaceholder: targetWeightValue == nil
                )

                healthSummaryTile(
                    title: targetWeightValue == nil ? "下一步" : "目标进度",
                    value: targetProgressHeadline,
                    detail: targetProgressText,
                    tint: targetProgressColor,
                    isPlaceholder: currentWeightValue == nil || targetWeightValue == nil
                )
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BMI")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        if let bmiValue {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(bmiStatusText)
                                    .font(.headline)

                                Text(String(format: "%.1f", bmiValue))
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(bmiColor(for: bmiValue))
                            }
                        } else {
                            Text("暂未生成")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let currentWeightValue {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("当前体重")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(weightText(currentWeightValue)) kg")
                                .font(.subheadline.bold())
                        }
                    }
                }

                BMIRangeBar(bmi: bmiValue)

                HStack(alignment: .top) {
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

                if bmiValue == nil {
                    Label(heightValue == nil ? "先填写身高，BMI 会自动生成。" : "先记录一次当前体重，BMI 会自动生成。", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    func healthSummaryTile(title: String, value: String, detail: String, tint: Color, isPlaceholder: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(isPlaceholder ? .title3.weight(.semibold) : .headline)
                .foregroundStyle(isPlaceholder ? .secondary : .primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(tint)
                    .padding(.top, 1)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(14)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    var bodySettingsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("体重目标")
                        .font(.title2.bold())

                    Text("身高和目标体重通常很少变化，设置好之后会自动刷新目标进度和 BMI。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    MeasurementField(title: "身高", value: $heightCm, placeholder: "175", unit: "cm")
                    MeasurementField(title: "目标体重", value: $targetWeight, placeholder: "65", unit: "kg")
                }

                Label("建议用你能长期维持的目标体重，不需要一步到位。", systemImage: "sparkles")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)

                Spacer()
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("体重目标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingBodySettings = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isShowingBodySettings = false
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
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
                        Label("查看更多", systemImage: "chevron.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppSecondaryButtonStyle(tint: .blue, isFullWidth: true))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日减脂目标")
                    .font(.title3.bold())

                Text("写一句今天最想做到的事，让节奏更明确。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("今天想坚持什么")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    if dailyGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("例如：晚饭少吃一点，散步 20 分钟，早点睡。")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 14)
                            .padding(.horizontal, 14)
                    }

                    TextEditor(text: $dailyGoal)
                        .font(.subheadline)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 108)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(.separator).opacity(0.14), lineWidth: 1)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dailyGoalSuggestions, id: \.self) { suggestion in
                        Button {
                            dailyGoal = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.caption.bold())
                                .foregroundStyle(dailyGoal == suggestion ? .blue : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    dailyGoal == suggestion
                                    ? Color.blue.opacity(0.12)
                                    : Color(.tertiarySystemFill)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
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

    var weightNoteSuggestions: [String] {
        ["空腹", "运动后", "晚饭前", "晚饭后", "经期", "出差"]
    }

    var dailyGoalSuggestions: [String] {
        [
            "多喝水，优先吃蛋白质",
            "晚饭少一点，饭后散步 20 分钟",
            "今天不喝含糖饮料",
            "早点睡，别吃夜宵"
        ]
    }

    func hasWeightNoteSuggestion(_ suggestion: String) -> Bool {
        noteInput
            .split(separator: "、")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains(suggestion)
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
        didShowWeightSaveFeedback = false
    }

    func applyWeightNoteSuggestion(_ suggestion: String) {
        let trimmedNote = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        var segments = trimmedNote
            .split(separator: "、")
            .map { String($0) }
            .filter { !$0.isEmpty }

        if let index = segments.firstIndex(of: suggestion) {
            segments.remove(at: index)
        } else {
            segments.append(suggestion)
        }

        noteInput = segments.joined(separator: "、")
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
        focusedWeightSheetField = nil

        withAnimation {
            didShowWeightSaveFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            didShowWeightSaveFeedback = false
            weightInput = ""
            noteInput = ""
            isShowingWeightSheet = false
        }
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
