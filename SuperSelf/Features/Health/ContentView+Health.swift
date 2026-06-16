import SwiftUI

extension ContentView {
    var statusCard: some View {
        let accent: Color = isFasting ? .blue : .green
        let gradientColors: [Color] = isFasting ? [.blue, .cyan] : [.green, .mint]
        let overtimeAccent: Color = isFasting ? .green : .orange
        let reached = hasReachedCurrentGoal

        let conclusion: String = isFasting ? "可以开吃了" : "该开始断食了"
        let subtitle: String = reached
            ? "已超过目标 \(compactDurationText(from: overtime)) · 目标 \(isFasting ? fastingGoalHours : eatingGoalHours) 小时"
            : "目标 \(isFasting ? fastingGoalHours : eatingGoalHours) 小时"

        return VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(isFasting ? "断食中" : "进食中")
                        .font(.title.bold())
                        .foregroundStyle(reached ? overtimeAccent : accent)
                    Spacer()
                    if reached {
                        Text(conclusion)
                            .font(.headline)
                            .foregroundStyle(overtimeAccent)
                    } else {
                        Image(systemName: isFasting ? "hourglass" : "fork.knife")
                            .font(.title2)
                            .foregroundStyle(accent)
                    }
                }
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background((reached ? overtimeAccent : accent).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 16)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: gradientColors, center: .center),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accent.opacity(0.35), radius: 6, x: 0, y: 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.9), value: progress)

                VStack(spacing: 6) {
                    Text(reached ? "已超时" : (isFasting ? "已断食时间" : "剩余时间"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(timeString(from: reached ? overtime : (isFasting ? elapsed : remaining)))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(reached ? overtimeAccent : .primary)
                }
                .padding(.horizontal, 36)
            }
            .frame(width: 230, height: 230)
            .padding(.vertical, 4)

            HStack(spacing: 0) {
                Button {
                    isShowingStartTimeSheet = true
                } label: {
                    timeStat(
                        title: isFasting ? "断食开始时间" : "吃饭开始时间",
                        value: relativeTimeText(for: fastingStartDate),
                        systemImage: "play.circle.fill",
                        tint: accent,
                        editable: true
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 1, height: 36)

                timeStat(
                    title: isFasting ? "断食结束时间" : "吃饭结束时间",
                    value: relativeTimeText(for: phaseEndDate),
                    systemImage: "flag.checkered.circle.fill",
                    tint: .secondary,
                    editable: false
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    func timeStat(title: String, value: String, systemImage: String, tint: Color, editable: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if editable {
                    Image(systemName: "pencil")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(tint)
                }
            }
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    var actionCard: some View {
        VStack(spacing: 16) {
            Button {
                if isFasting && !hasReachedCurrentGoal {
                    isShowingEndFastingConfirm = true
                } else {
                    switchPhase()
                }
            } label: {
                Text(primaryActionTitle)
            }
            .buttonStyle(AppPrimaryButtonStyle(tint: primaryActionTint))
            .alert("中断断食？", isPresented: $isShowingEndFastingConfirm) {
                Button("再坚持一下", role: .cancel) {}
                Button("结束断食", role: .destructive) {
                    switchPhase()
                }
            } message: {
                Text("目标尚未达成，确定要提前结束吗？")
            }

            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("当前计划")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(fastingGoalHours) + \(eatingGoalHours) · 断食 + 进食")
                        .font(.subheadline.bold())
                }

                Spacer()

                Button {
                    isShowingPlanSheet = true
                } label: {
                    Text("调整")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color.blue.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                resetCurrentPhase()
            } label: {
                Label("重置当前阶段", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
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
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var syncCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: isICloudAvailable ? "checkmark.icloud.fill" : "icloud.slash")
                    .font(.title2)
                    .foregroundStyle(isICloudAvailable ? .blue : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isICloudAvailable ? "iCloud 已连接" : "未连接 iCloud")
                        .font(.headline)
                    Text(isICloudAvailable ? "数据会自动同步到你的 iCloud" : "请在系统「设置」登录 iCloud 后自动同步")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if isSyncing {
                    ProgressView()
                } else {
                    Button("立即同步") {
                        syncNow()
                    }
                    .buttonStyle(AppSecondaryButtonStyle(tint: .blue))
                    .disabled(!isICloudAvailable)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var weightCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "scalemass.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("体重记录")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                if let latestWeightLog {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(weightText(latestWeightLog.weight))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("kg")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Text("最近 \(chineseDateTime(latestWeightLog.date))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if let badge = weightDeltaBadge {
                            HStack(spacing: 2) {
                                Image(systemName: badge.icon)
                                Text(badge.text)
                            }
                            .font(.caption2.bold())
                            .foregroundStyle(badge.color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.14))
                            .clipShape(Capsule())
                            .fixedSize()
                        }
                    }
                } else {
                    Text("还没有体重记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                openTodayWeightEntry()
            } label: {
                AppIconCircleButton(
                    icon: todayWeightLog == nil ? "plus" : "pencil",
                    tint: .blue,
                    size: 44,
                    iconFont: .headline.weight(.bold)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var weightDeltaBadge: (icon: String, text: String, color: Color)? {
        let logs = sortedWeightLogs
        guard logs.count >= 2 else { return nil }
        let delta = logs[0].weight - logs[1].weight
        if abs(delta) < 0.05 {
            return ("minus", "持平", .secondary)
        }
        let icon = delta < 0 ? "arrow.down.right" : "arrow.up.right"
        let color: Color = delta < 0 ? .green : .orange
        return (icon, "\(weightText(abs(delta))) kg", color)
    }

    var weightOverviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "scalemass.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 34, height: 34)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                        Text("我的体重")
                            .font(.title3.bold())
                    }

                    if let currentWeight = currentWeightValue {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(weightText(currentWeight))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text("kg")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            if let badge = weightDeltaBadge {
                                HStack(spacing: 2) {
                                    Image(systemName: badge.icon)
                                    Text(badge.text)
                                }
                                .font(.caption2.bold())
                                .foregroundStyle(badge.color)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(badge.color.opacity(0.14))
                                .clipShape(Capsule())
                                .fixedSize()
                            }
                        }

                        if let latestWeightLog {
                            Text("最近 \(chineseDateTime(latestWeightLog.date))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("还没有体重记录")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    openTodayWeightEntry()
                } label: {
                    AppIconCircleButton(
                        icon: todayWeightLog == nil ? "plus" : "pencil",
                        tint: .blue,
                        size: 34,
                        iconFont: .subheadline.weight(.bold)
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                weightGoalProgressBlock
                weightBMIBlock
            }
            .fixedSize(horizontal: false, vertical: true)
        }

        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    var weightGoalProgressBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text(weightRemainingValue != nil ? "还需减重" : "目标")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 2)
                Button {
                    isShowingBodySettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(targetProgressColor)
                        .frame(width: 18, height: 18)
                        .background(targetProgressColor.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if let remaining = weightRemainingValue {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(weightText(remaining))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(targetProgressColor)
                    Text("kg")
                        .font(.caption.bold())
                        .foregroundStyle(targetProgressColor.opacity(0.8))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                if let fraction = goalProgressFraction, let lost = weightLostValue {
                    ProgressView(value: fraction)
                        .tint(targetProgressColor)
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)

                    Text("已减 \(weightText(lost)) kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else if let target = targetWeightValue {
                    Text("目标 \(weightText(target)) kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            } else if targetWeightValue != nil {
                Text("已达标")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("保持住，状态不错")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("未设置")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("先定一个目标")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(targetProgressColor.opacity(weightRemainingValue != nil ? 0.10 : 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    var weightBMIBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BMI")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if let bmiValue {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", bmiValue))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(bmiColor(for: bmiValue))
                    Text(bmiStatusText)
                        .font(.caption.bold())
                        .foregroundStyle(bmiColor(for: bmiValue))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                BMIRangeBar(bmi: bmiValue)

                HStack(spacing: 0) {
                    Text("偏瘦")
                    Spacer(minLength: 0)
                    Text("正常")
                    Spacer(minLength: 0)
                    Text("偏胖")
                    Spacer(minLength: 0)
                    Text("肥胖")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            } else {
                Text("未生成")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(heightValue == nil ? "先填身高" : "先记体重")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var addWeightSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            ZStack(alignment: .leading) {
                                if weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(weightInputPlaceholder)
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundStyle(.tertiary)
                                        .allowsHitTesting(false)
                                }

                                TextField("", text: $weightInput)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .focused($focusedWeightSheetField, equals: .weight)
                            }
                            .fixedSize()

                            Text("kg")
                                .font(.title2.bold())
                                .foregroundStyle(.secondary)

                            Spacer()
                        }

                        if let latestWeightLog {
                            HStack(spacing: 6) {
                                Text("上次 \(weightText(latestWeightLog.weight)) kg · \(chineseDateTime(latestWeightLog.date))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                Button("填入") {
                                    weightInput = weightText(latestWeightLog.weight)
                                }
                                .font(.footnote.bold())
                                .foregroundStyle(.blue)
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("备注")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ZStack(alignment: .topLeading) {
                            if noteInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("今天吃了什么喝了什么，这里记录下吧")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 14)
                            }

                            TextEditor(text: $noteInput)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 88)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .focused($focusedWeightSheetField, equals: .note)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
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
                    .foregroundStyle(isWeightInputEmpty ? Color.white.opacity(0.85) : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: isWeightInputEmpty
                                ? [Color.blue.opacity(0.4), Color.cyan.opacity(0.4)]
                                : [Color.blue, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(
                        color: isWeightInputEmpty
                            ? .clear
                            : Color.blue.opacity(0.22),
                        radius: 14,
                        y: 8
                    )
                }
                .buttonStyle(.plain)
                .disabled(isWeightInputEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(.bar)
            }
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
                didShowWeightSaveFeedback = false
            }
            .task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                focusedWeightSheetField = .weight
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: didShowWeightSaveFeedback)
        }
        .presentationDetents([.large])
    }

    var trendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("体重趋势")
                    .font(.title3.bold())

                Spacer()
            }

            AppSegmentedControl(
                options: WeightTrendGranularity.allCases,
                selection: $trendGranularity,
                title: \.title,
                compact: true
            )

            if !trendPoints.isEmpty {
                WeightTrendView(points: trendPoints, targetWeight: targetWeightValue)
                    .frame(height: 180)
            } else {
                AppEmptyState(
                    title: "还没有趋势",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: "记录体重后会自动生成趋势。"
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var bmiCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("体重目标")
                        .font(.title3.bold())

                    Text("记录体重后自动显示进度和 BMI。")
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
                    detail: targetWeightValue == nil ? "先定一个能坚持的目标。" : nil,
                    tint: .blue,
                    isPlaceholder: targetWeightValue == nil
                )

                healthSummaryTile(
                    title: targetWeightValue == nil ? "下一步" : "目标进度",
                    value: targetProgressHeadline,
                    detail: (currentWeightValue == nil || targetWeightValue == nil) ? targetProgressText : nil,
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

    func healthSummaryTile(title: String, value: String, detail: String? = nil, tint: Color, isPlaceholder: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(isPlaceholder ? .title3.weight(.semibold) : .title2.bold())
                .foregroundStyle(isPlaceholder ? .secondary : .primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let detail {
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
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
        .padding(14)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    var bodySettingsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        MeasurementField(title: "身高", value: $heightCm, placeholder: "175", unit: "cm", icon: "ruler", tint: .blue)
                        Text("填写身高用于计算 BMI 指数")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        MeasurementField(title: "目标体重", value: $targetWeight, placeholder: "65", unit: "kg", icon: "target", tint: .orange)

                        Text("建议用你能长期维持的目标体重，不需要一步到位。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        MeasurementField(title: "本轮初始体重", value: $roundStartWeight, placeholder: roundStartPlaceholder, unit: "kg", icon: "flag.fill", tint: .pink)

                        Text("设置后，可以看到当前体重相对初始体重的变化情况")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
            }
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
        .presentationDetents([.medium, .large])
    }

    var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("体重记录")
                    .font(.title3.bold())
                Spacer()
                Text("\(weightLogs.count) 条")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
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
                        WeightLogRow(log: log, weightText: weightText(log.weight), dateText: chineseDateTime(log.date), onOpen: {
                            editingWeightLog = log
                        }, onDelete: {
                            deleteWeightLog(log)
                        })
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
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var planCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日减脂目标")
                        .font(.title3.bold())
                    Text("写一句今天最想做到的事，让节奏更明确。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

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
                    .frame(minHeight: 100)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator).opacity(0.14), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("快速选择")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dailyGoalSuggestions, id: \.self) { suggestion in
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                    dailyGoal = suggestion
                                }
                            } label: {
                                Text(suggestion)
                                    .font(.caption.bold())
                                    .foregroundStyle(dailyGoal == suggestion ? .orange : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        dailyGoal == suggestion
                                        ? Color.orange.opacity(0.14)
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
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var startTimeSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SheetHeader(
                        icon: "clock.arrow.circlepath",
                        title: "修改开始时间",
                        subtitle: isFasting ? "把开始时间设成上次吃完饭的时刻" : "调整进食阶段的开始时刻",
                        gradient: [.blue, .indigo]
                    )

                    Text(isFasting
                         ? "比如昨晚 11 点吃完饭，就把开始时间设为昨晚 23:00，倒计时会据此重新计算。"
                         : "倒计时会根据新的开始时间重新计算。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("开始时间")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "开始时间",
                            selection: $startTimeDraft,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    }
                    .padding(18)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    HStack(spacing: 10) {
                        ForEach(startTimeQuickOptions, id: \.0) { option in
                            Button {
                                startTimeDraft = Date().addingTimeInterval(-option.1)
                            } label: {
                                Text(option.0)
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.10))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Label("结束时间会根据当前计划自动顺延。", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("修改开始时间")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startTimeDraft = fastingStartDate
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingStartTimeSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        fastingStartTime = startTimeDraft.timeIntervalSince1970
                        persistSettingsToICloud()
                        isShowingStartTimeSheet = false
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
        .presentationDetents([.large])
    }

    var planSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("14+10 最容易上手，16+8 适合大多数人，18+6、20+4 难度更高。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        ForEach(planOptions, id: \.fasting) { option in
                            let isSelected = fastingGoalHours == option.fasting

                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    planSelection.wrappedValue = option.fasting
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text("\(option.fasting) + \(option.eating)")
                                                .font(.title3.bold())
                                                .foregroundStyle(isSelected ? .white : .primary)

                                            if let badge = planBadge(for: option.fasting) {
                                                Text(badge.title)
                                                    .font(.caption2.bold())
                                                    .foregroundStyle(isSelected ? .white : badge.color)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(
                                                        (isSelected ? Color.white.opacity(0.22) : badge.color.opacity(0.14)),
                                                        in: Capsule()
                                                    )
                                            }
                                        }
                                        Text("断食 \(option.fasting) 小时 · 进食 \(option.eating) 小时")
                                            .font(.caption)
                                            .foregroundStyle(isSelected ? Color.white.opacity(0.85) : .secondary)
                                    }

                                    Spacer()

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                                .background {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color.blue.gradient)
                                            .shadow(color: Color.blue.opacity(0.26), radius: 10, y: 4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color(.secondarySystemGroupedBackground))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Label("切换计划只改变目标时长，不会重置当前正在进行的阶段。", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("调整断食计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingPlanSheet = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isShowingPlanSheet = false
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                }
            }
        }
        .presentationDetents([.large])
    }

    func planBadge(for fasting: Int) -> (title: String, color: Color)? {
        switch fasting {
        case 14:
            return ("新手", .green)
        case 16:
            return ("推荐", .blue)
        case 18:
            return ("进阶", .orange)
        case 20:
            return ("挑战", .red)
        default:
            return nil
        }
    }

    var startTimeQuickOptions: [(String, TimeInterval)] {
        [
            ("现在", 0),
            ("1 小时前", 3600),
            ("8 小时前", 8 * 3600),
            ("昨晚 11 点", lastNight11Interval)
        ]
    }

    var lastNight11Interval: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 23
        components.minute = 0
        guard var target = calendar.date(from: components) else { return 0 }
        if target > now {
            target = calendar.date(byAdding: .day, value: -1, to: target) ?? target
        }
        return now.timeIntervalSince(target)
    }

    var primaryActionTitle: String {
        if isFasting {
            if hasReachedCurrentGoal {
                return "已达标，开吃犒劳自己"
            }
            return "结束断食"
        }

        return "吃完了，开始 \(fastingGoalHours) 小时计划"
    }

    var primaryActionTint: Color {
        if isFasting {
            return hasReachedCurrentGoal ? .green : Color(.systemGray)
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
        let groupedLogs = Dictionary(grouping: dailyTrendLogs, by: keyForLog)

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
        rescheduleFastingNotifications()
    }

    func resetCurrentPhase() {
        fastingStartTime = Date().timeIntervalSince1970
        persistSettingsToICloud()
        rescheduleFastingNotifications()
    }

    func prepareWeightSheet() {
        weightInput = ""
        noteInput = ""
        didShowWeightSaveFeedback = false
    }

    func openTodayWeightEntry() {
        if let todayWeightLog {
            editingWeightLog = todayWeightLog
        } else {
            prepareWeightSheet()
            isShowingWeightSheet = true
        }
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
}
