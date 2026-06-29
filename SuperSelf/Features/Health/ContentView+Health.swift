import SwiftUI

extension ContentView {
    var statusCard: some View {
        let accent: Color = isFasting ? .blue : .green
        let gradientColors: [Color] = isFasting ? [.blue, .cyan] : [.green, .mint]
        let overtimeAccent: Color = isFasting ? .green : .orange
        let reached = hasReachedCurrentGoal
        let ringInterval = reached ? overtime : (isFasting ? elapsed : remaining)
        let ringText = timerDisplayText(from: ringInterval)
        let ringFontSize: CGFloat = ringText.count >= 8 ? 40 : (ringText.count >= 7 ? 36 : 34)
        let phaseGoalHint = isFasting ? "需断食 \(fastingGoalHours) 小时" : "需进食 \(eatingGoalHours) 小时"
        let displayProgress = reached ? 1.0 : progress
        let ringLineCap: CGLineCap = reached ? .round : .butt

        let conclusion: String = isFasting ? "可以开吃了" : "该开始断食了"
        let subtitle: String = reached
            ? "已超过目标 \(compactDurationText(from: overtime)) · 目标 \(isFasting ? fastingGoalHours : eatingGoalHours) 小时"
            : "目标 \(isFasting ? fastingGoalHours : eatingGoalHours) 小时"

        return VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(isFasting ? (reached ? "断食中 🥳" : "断食中 🥺") : (reached ? "进食中 🐷" : "进食中 😋"))
                        .font(.title.bold())
                        .foregroundStyle(reached ? overtimeAccent : accent)
                    Spacer()
                    if reached {
                        Text(conclusion)
                            .font(.headline)
                            .foregroundStyle(overtimeAccent)
                    } else {
                        if isFasting {
                            AnimatedHourglassIcon(tint: accent)
                        } else {
                            Image(systemName: "fork.knife")
                                .font(.title2)
                                .foregroundStyle(accent)
                        }
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
                    .trim(from: 0, to: displayProgress)
                    .stroke(
                        AngularGradient(colors: gradientColors, center: .center),
                        style: StrokeStyle(lineWidth: 16, lineCap: ringLineCap)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accent.opacity(0.35), radius: 6, x: 0, y: 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.9), value: displayProgress)

                VStack(spacing: 6) {
                    Text(reached ? "已超时" : (isFasting ? "已断食时间" : "剩余时间"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(ringText)
                        .font(.system(size: ringFontSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .allowsTightening(true)
                        .lineLimit(1)
                        .foregroundStyle(reached ? overtimeAccent : .primary)

                    Text(phaseGoalHint)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 28)
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
                Group {
                    if let syncToastMessage {
                        let isSuccess = syncToastMessage.contains("完成") || syncToastMessage.contains("已同步")

                        Label(syncToastMessage, systemImage: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSuccess ? .green : .orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                isSuccess ? Color.green.opacity(0.10) : Color.orange.opacity(0.10),
                                in: Capsule()
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: syncStatusIcon)
                                .font(.caption)
                                .foregroundStyle(syncStatusTint)
                            Text(syncLastSyncText)
                                .font(.caption)
                                .foregroundStyle(syncStatusTint)
                        }
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 32, alignment: .leading)

                Spacer()

                if isSyncing {
                    ProgressView()
                } else {
                    Button("立即同步") {
                        syncNow()
                    }
                    .buttonStyle(AppSecondaryButtonStyle(tint: .blue, compact: true))
                }
            }
            .contentTransition(.opacity)
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

    var weightBMIBlock: some View {
        Button {
            isShowingBMIInfo = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("BMI")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    Image(systemName: "questionmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

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
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("点按查看 BMI 的计算规则和区间说明")
    }

    var bmiInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BMI 是身体质量指数，用来粗略判断体重和身高是否匹配。")
                            .font(.headline)

                        Text("它不是越低越好，也不是唯一标准，但对大多数成年人来说，是一个很常用、很容易看懂的参考值。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("你的当前结果")
                            .font(.headline)

                        if let bmiValue {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(String(format: "%.1f", bmiValue))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(bmiColor(for: bmiValue))
                                Text(bmiStatusText)
                                    .font(.headline)
                                    .foregroundStyle(bmiColor(for: bmiValue))
                            }

                            Text(currentBMIExplanation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("还无法计算 BMI")
                                .font(.headline)
                            Text(heightValue == nil ? "先填写身高，再记录体重，系统就会自动算出 BMI。" : "先记录一次当前体重，系统就会自动算出 BMI。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("BMI 怎么算")
                            .font(.headline)

                        Text("计算公式：BMI = 体重（kg）÷ 身高（m）²")
                            .font(.body.weight(.semibold))

                        Text("比如身高 1.70 米、体重 68.8 kg，BMI = 68.8 ÷ 1.70²，大约就是 23.8。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("怎么看区间")
                            .font(.headline)

                        bmiRangeRow(
                            title: "偏瘦",
                            range: "< 18.5",
                            tint: .blue,
                            description: "说明体重相对偏低。可以先看看最近是不是吃得少、睡得少，或者运动后恢复不够。"
                        )
                        bmiRangeRow(
                            title: "正常",
                            range: "18.5 - 23.9",
                            tint: .green,
                            description: "对大多数成年人来说，这是更常见也更稳妥的参考范围。能长期维持，比短期冲低更重要。"
                        )
                        bmiRangeRow(
                            title: "偏胖",
                            range: "24.0 - 27.9",
                            tint: .orange,
                            description: "说明体重有点超出理想范围了。通常可以先从少喝含糖饮料、多走路、规律吃饭开始，不必太激进。"
                        )
                        bmiRangeRow(
                            title: "肥胖",
                            range: "≥ 28.0",
                            tint: .red,
                            description: "说明超重程度更明显，建议尽早系统减重；如果还伴随腰围大、血压血糖异常，更值得认真关注。"
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("怎样算比较合理")
                            .font(.headline)

                        Text("如果你是普通成年人，把 BMI 大致维持在 18.5 到 23.9 之间，同时体重波动不要太剧烈，通常就可以认为比较合理。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("更重要的是：精神状态稳定、吃得下睡得着、运动后恢复正常、腰围没有持续上涨。BMI 只是一个起点，不需要把它当成唯一目标。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("补充说明")
                            .font(.headline)

                        Text("本应用按中国成年人常用分界值显示：18.5、24、28。未成年人、孕期、老年人、健身增肌人群，BMI 的参考意义会打折，最好结合体脂率、腰围和医生建议一起看。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("BMI 说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isShowingBMIInfo = false
                    }
                }
            }
        }
    }

    func bmiRangeRow(title: String, range: String, tint: Color, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(range)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var currentBMIExplanation: String {
        guard let bmiValue else {
            return ""
        }

        switch bmiValue {
        case ..<18.5:
            return "你现在属于偏瘦区间。不是立刻有问题，但如果长期偏低，建议顺手关注一下饮食、作息和力量训练。"
        case 18.5..<24:
            return "你现在处于正常区间。对大多数成年人来说，这是比较理想的范围，保持现在这种稳定状态就很好。"
        case 24..<28:
            return "你现在处于偏胖区间。通常不需要极端减肥，先把饮食节奏、活动量和睡眠慢慢拉回规律，会更容易坚持。"
        default:
            return "你现在处于肥胖区间。建议把减重当成一个长期计划来做，如果还有腰围偏大或体检指标异常，更值得认真管理。"
        }
    }

    var addWeightSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("体重")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            TextField(weightInputPlaceholder, text: $weightInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .focused($focusedWeightSheetField, equals: .weight)

                            Text("kg")
                                .font(.title3.bold())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveWeight()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .disabled(isWeightInputEmpty)
                }
            }
            .onAppear {
                didShowWeightSaveFeedback = false
                focusedWeightSheetField = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    focusedWeightSheetField = .weight
                }
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

    var weightLossTipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("减脂技巧")
                    .font(.title3.bold())

                Spacer()

                Button {
                    refreshWeightLossTip()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }

            Text(currentWeightLossTip)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        .onAppear(perform: ensureWeightLossTipForToday)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                ensureWeightLossTipForToday()
            }
        }
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
                    VStack(alignment: .leading, spacing: 6) {
                        MeasurementField(title: "身高", value: $heightCm, placeholder: "175", unit: "cm", icon: "ruler", tint: .blue)
                        Text("填写身高用于计算 BMI 指数")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        MeasurementField(title: "目标体重", value: $targetWeight, placeholder: "65", unit: "kg", icon: "target", tint: .orange)

                        Text("建议用你能长期维持的目标体重，不需要一步到位。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
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
                        WeightLogRow(log: log, weightText: weightText(log.weight), dateText: chineseDateTime(log.date), weekdayText: chineseWeekday(log.date), onOpen: {
                            shouldFocusWeightLogNote = false
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

    var weightLossTips: [String] {
        [
            "当我们想吃东西时，需要问问自己：究竟是饿了、还是馋了？不饿就不吃，饿了再等等吧",
            "多喝水很重要！多喝水可以增加饱腹感、帮助肠胃蠕动和促进排泄、有利于加速脂肪燃烧。",
            "靠饿瘦下来会反弹？可如果不瘦下来连反弹的机会都没有，先瘦下来再考虑反弹吧",
            "你已经很瘦不需要再减了吗？算算 BMI，如果没再正常范围内就别犹豫，继续减吧",
            "16 + 8 是控制热量最好的方法，只要坚持就一定可以瘦下来",
            "每天都要记录体重，而不是因为担心胖就不敢称了，每天记录才能防止自己持续变胖",
            "减肥后身体健康、轻盈，这种快乐是长久的快乐，才是真正的快乐",
            "小减降体重，大减换人生。",
            "每餐保证有鸡蛋、鸡胸、牛肉、鱼等优质蛋白，能明显减少饥饿感",
            "不要吃太快，要慢吃，才能更好控制热量",
            "无论如何，瘦下来一定是要比胖更好看的。",
            "对大部分来说，饿才是唯一有效的变瘦方法。",
            "对于正常体质的人而言，减肥是一辈子都要做的事情。要保持健康的体重，就得控制食欲。",
            "人不是一天胖起来的，也不是一天瘦下去的。",
            "有时候吃了过咸的食物容易使身体吸收很多水而导致 “变胖”，但这种情况下的胖是虚胖，过两天就会恢复了。",
            "16 + 8 最大的好处是可以让我们有固定的一段时间不吃饭，这样就避免因为馋而吃东西了。",
            "减肥最重要的是少吃，而不是运动。",
            "很多明星都会通过少吃来减肥，比如黄晓明、沈腾、杨紫、宁静、朱洁静、刘宇宁、王一博等。"
        ]
    }

    var currentWeightLossTip: String {
        guard !weightLossTips.isEmpty else { return "今天先从按时吃饭、规律记录开始。" }
        return weightLossTips[currentWeightLossTipIndex]
    }

    var currentWeightLossTipIndex: Int {
        guard !weightLossTips.isEmpty else { return 0 }
        if weightLossTips.indices.contains(weightLossTipIndex) {
            return weightLossTipIndex
        }
        return dailyWeightLossTipIndex(for: Date())
    }

    func hasWeightNoteSuggestion(_ suggestion: String) -> Bool {
        noteInput
            .split(separator: "、")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains(suggestion)
    }

    func dailyWeightLossTipIndex(for date: Date) -> Int {
        guard !weightLossTips.isEmpty else { return 0 }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        return abs(year * 1000 + day) % weightLossTips.count
    }

    func weightLossTipKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    func ensureWeightLossTipForToday() {
        guard !weightLossTips.isEmpty else { return }
        let todayKey = weightLossTipKey(for: Date())
        let hasValidStoredIndex = weightLossTips.indices.contains(weightLossTipIndex)

        guard weightLossTipDayKey != todayKey || !hasValidStoredIndex else { return }

        weightLossTipDayKey = todayKey
        weightLossTipIndex = dailyWeightLossTipIndex(for: Date())
    }

    func refreshWeightLossTip() {
        guard !weightLossTips.isEmpty else { return }

        ensureWeightLossTipForToday()
        let todayKey = weightLossTipKey(for: Date())
        guard weightLossTips.count > 1 else {
            weightLossTipDayKey = todayKey
            weightLossTipIndex = 0
            return
        }

        var nextIndex = Int.random(in: 0..<weightLossTips.count)
        while nextIndex == currentWeightLossTipIndex {
            nextIndex = Int.random(in: 0..<weightLossTips.count)
        }

        weightLossTipDayKey = todayKey
        weightLossTipIndex = nextIndex
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
        focusedWeightSheetField = nil
        didShowWeightSaveFeedback = false
    }

    func openTodayWeightEntry() {
        if let todayWeightLog {
            shouldFocusWeightLogNote = true
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

    // MARK: - 锻炼

    var exerciseSection: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 20) {
                exerciseTodayCard
                exerciseCalendarCard
                    .id("exerciseCalendarCard")
            }
            .alert("记录进度", isPresented: Binding(
                get: { exerciseInputGoal != nil },
                set: { if !$0 { exerciseInputGoal = nil; exerciseInputDate = nil } }
            )) {
                TextField("输入完成数量", text: $exerciseInputValue)
                    .keyboardType(.numberPad)
                Button("取消", role: .cancel) {
                    exerciseInputGoal = nil
                    exerciseInputDate = nil
                }
                // Add default keyboard shortcut so it's highlighted as the primary action in the alert
                Button("确定") {
                    if let goal = exerciseInputGoal, let val = Int(exerciseInputValue) {
                        let dateToSave = exerciseInputDate ?? Date()
                        setExerciseCount(val, for: goal, on: dateToSave)
                    }
                    exerciseInputGoal = nil
                    exerciseInputDate = nil
                }
                .keyboardShortcut(.defaultAction)
            } message: {
                if let goal = exerciseInputGoal {
                    Text(exerciseInputMessageText(for: goal))
                }
            }
            .onChange(of: exerciseCalendarSelectedDate) { _, newValue in
                if newValue != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            proxy.scrollTo("exerciseCalendarCard", anchor: .top)
                        }
                    }
                }
            }
        }
    }

    func exerciseInputMessageText(for goal: ExerciseGoal) -> String {
        let dateToSave = exerciseInputDate ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        let dateString = Calendar.current.isDateInToday(dateToSave) ? "今日" : formatter.string(from: dateToSave)
        return "请输入「\(goal.title)」在 \(dateString) 的完成数量（\(exerciseUnit(for: goal, on: dateToSave))）"
    }

    var activeExerciseGoals: [ExerciseGoal] {
        exerciseGoals
            .filter(\.isActive)
            .sorted { $0.createdAt < $1.createdAt }
    }

    var exerciseTodayCompletionText: String {
        guard !activeExerciseGoals.isEmpty else { return "还没有目标" }
        let completedCount = activeExerciseGoals.filter { isExerciseGoalCompleted($0, on: Date()) }.count
        let totalCount = activeExerciseGoals.count

        if completedCount == totalCount {
            let encouragements = [
                "太棒了 🎉",
                "完美的一天 🌟",
                "今日目标达成 💪",
                "全部搞定 👏"
            ]
            // We use the day of the year to pick a pseudo-random but stable encouragement for today
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            return encouragements[dayOfYear % encouragements.count]
        } else {
            return "\(completedCount) / \(totalCount) 已完成"
        }
    }

    var exerciseTodayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.green)
                    .frame(width: 42, height: 42)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("今日锻炼")
                        .font(.title3.bold())
                    Text(exerciseTodayCompletionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingExerciseGoalSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if activeExerciseGoals.isEmpty {
                Button {
                    isShowingExerciseGoalSheet = true
                } label: {
                    Label("添加锻炼目标", systemImage: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 12) {
                    ForEach(activeExerciseGoals) { goal in
                        let count = exerciseCount(for: goal, on: Date())
                        let target = exerciseTarget(for: goal, on: Date())
                        let unit = exerciseUnit(for: goal, on: Date())
                        ExerciseTodayGoalRow(
                            goal: goal,
                            count: count,
                            targetCount: target,
                            unit: unit,
                            isCompleted: count >= target,
                            onComplete: { completeExerciseGoal(goal, on: Date()) },
                            onInput: {
                                exerciseInputValue = "\(count)"
                                exerciseInputGoal = goal
                                exerciseInputDate = Date()
                            }
                        )
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var exerciseCalendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("锻炼日历")
                    .font(.title3.bold())

                Spacer()

                HStack(spacing: 16) {
                    if !exerciseCalendarIsViewingToday {
                        Button("今天") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                exerciseCalendarMonth = Date()
                                exerciseCalendarSelectedDate = nil
                            }
                        }
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.12), in: Capsule())
                    }

                    HStack(spacing: 8) {
                        Button {
                            moveExerciseCalendarMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Text(exerciseCalendarMonthTitle)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Button {
                            moveExerciseCalendarMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(.green)
            }

            HStack(spacing: 0) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(exerciseCalendarDays) { day in
                    exerciseCalendarDayCell(day)
                }
            }

            HStack(spacing: 8) {
                ExerciseCalendarLegend(color: .green, title: "完成")
                ExerciseCalendarLegend(color: .green.opacity(0.28), title: "部分完成")
                ExerciseCalendarLegend(color: Color(.systemGray5), title: "未完成")
                Spacer()
                Text(exerciseCompletedDaysText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            let displayDate = exerciseCalendarSelectedDate ?? (Calendar.current.isDate(exerciseCalendarMonth, equalTo: Date(), toGranularity: .month) ? Date() : nil)
            if let dateToShow = displayDate {
                Divider()
                    .padding(.vertical, 1)
                exerciseCalendarSelectedDateDetails(for: dateToShow)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    var exerciseCalendarMonthTitle: String {
        let isCurrentMonth = Calendar.current.isDate(exerciseCalendarMonth, equalTo: Date(), toGranularity: .month)
        if isCurrentMonth {
            return "本月"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: exerciseCalendarMonth)
        }
    }

    var exerciseCalendarIsViewingToday: Bool {
        if let selected = exerciseCalendarSelectedDate {
            return Calendar.current.isDateInToday(selected)
        } else {
            return Calendar.current.isDate(exerciseCalendarMonth, equalTo: Date(), toGranularity: .month)
        }
    }

    var exerciseCalendarDays: [ExerciseCalendarDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2

        let monthStart = calendar.dateInterval(of: .month, for: exerciseCalendarMonth)?.start ?? calendar.startOfDay(for: exerciseCalendarMonth)
        let monthInterval = calendar.dateInterval(of: .month, for: exerciseCalendarMonth)
        let monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval?.end ?? monthStart) ?? monthStart
        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingDays = (weekday + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart
        let trailingDays = (7 - ((leadingDays + calendar.component(.day, from: monthEnd)) % 7)) % 7
        let naturalCellCount = leadingDays + calendar.component(.day, from: monthEnd) + trailingDays
        let totalCellCount = max(35, naturalCellCount)

        return (0..<totalCellCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            return ExerciseCalendarDay(
                date: date,
                isInDisplayedMonth: calendar.isDate(date, equalTo: monthStart, toGranularity: .month),
                isToday: calendar.isDateInToday(date)
            )
        }
    }

    var exerciseCompletedDaysInMonth: Int {
        exerciseCalendarDays.filter {
            $0.isInDisplayedMonth && isExerciseDayCompleted($0.date)
        }.count
    }

    var exerciseCompletedDaysText: String {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(exerciseCalendarMonth, equalTo: Date(), toGranularity: .month)
        if isCurrentMonth {
            return "本月完成 \(exerciseCompletedDaysInMonth) 天"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月"
            let monthString = formatter.string(from: exerciseCalendarMonth)
            return "\(monthString)完成 \(exerciseCompletedDaysInMonth) 天"
        }
    }

    func exerciseCalendarSelectedDateDetails(for date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        let dateString = formatter.string(from: date)
        
        let goals = exerciseGoals(for: date)

        return VStack(alignment: .leading, spacing: 14) {
            Text("\(dateString)锻炼详情")
                .font(.subheadline.weight(.semibold))

            if goals.isEmpty {
                Text("当天没有设置任何锻炼目标")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ExerciseHistoryTableHeader()

                    ForEach(goals) { goal in
                        let count = exerciseCount(for: goal, on: date)
                        let target = exerciseTarget(for: goal, on: date)
                        let unit = exerciseUnit(for: goal, on: date)
                        ExerciseHistoryTableRow(
                            goal: goal,
                            count: count,
                            targetCount: target,
                            unit: unit,
                            isCompleted: count >= target
                        )

                        if goal.id != goals.last?.id {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    func exerciseCalendarDayCell(_ day: ExerciseCalendarDay) -> some View {
        let calendar = Calendar.current
        let isFuture = calendar.startOfDay(for: day.date) > calendar.startOfDay(for: Date())
        let fraction = exerciseCompletionFraction(on: day.date)
        let isSelected = exerciseCalendarSelectedDate.map { calendar.isDate($0, inSameDayAs: day.date) } ?? false

        let fillColor: Color = {
            if isFuture || !day.isInDisplayedMonth {
                return Color.clear
            }
            if fraction >= 1 {
                return .green
            }
            if fraction > 0 {
                return .green.opacity(0.28)
            }
            return Color(.systemGray5)
        }()

        let content = ZStack {
            if day.isToday {
                Circle()
                    .fill(Color.green.opacity(day.isInDisplayedMonth && !isFuture ? 0.16 : 0.08))
                    .frame(width: 40, height: 40)
            }

            Text("\(calendar.component(.day, from: day.date))")
                .font(.caption.weight(day.isToday ? .bold : .medium))
                .foregroundStyle(fraction >= 1 && day.isInDisplayedMonth && !isFuture ? .white : (day.isInDisplayedMonth ? .primary : .secondary.opacity(0.35)))
                .frame(width: 32, height: 32)
                .background(fillColor, in: Circle())
                .overlay {
                    if day.isToday {
                        Circle()
                            .stroke(Color.green, lineWidth: 2.5)
                            .padding(-3)
                    }

                    if isSelected {
                        Circle()
                            .stroke(Color.primary.opacity(0.58), lineWidth: 2)
                            .padding(day.isToday ? -6 : -2)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if day.isToday {
                        Text("今")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 14, height: 14)
                            .background(Color.green, in: Circle())
                            .offset(x: 3, y: -3)
                    }
                }
        }
        .frame(width: 42, height: 42)
        .opacity(day.isInDisplayedMonth ? 1 : 0.45)

        if isFuture || !day.isInDisplayedMonth {
            return AnyView(content)
        } else {
            return AnyView(Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if isSelected {
                        exerciseCalendarSelectedDate = nil
                    } else {
                        exerciseCalendarSelectedDate = day.date
                    }
                }
            } label: {
                content
            }
            .buttonStyle(.plain))
        }
    }

    func exerciseRecord(for goal: ExerciseGoal, on date: Date) -> ExerciseRecord? {
        let day = Calendar.current.startOfDay(for: date)
        return exerciseRecords.first { record in
            record.goalID == goal.id && Calendar.current.isDate(record.date, inSameDayAs: day)
        }
    }

    func exerciseCount(for goal: ExerciseGoal, on date: Date) -> Int {
        exerciseRecord(for: goal, on: date)?.count ?? 0
    }

    func exerciseGoals(for date: Date) -> [ExerciseGoal] {
        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
        return exerciseGoals.filter { goal in
            if isToday {
                return goal.isActive
            } else {
                return exerciseRecord(for: goal, on: date) != nil
            }
        }.sorted { $0.createdAt < $1.createdAt }
    }

    func exerciseTarget(for goal: ExerciseGoal, on date: Date) -> Int {
        exerciseRecord(for: goal, on: date)?.targetCount ?? goal.targetCount
    }

    func exerciseUnit(for goal: ExerciseGoal, on date: Date) -> String {
        exerciseRecord(for: goal, on: date)?.unit ?? goal.unit
    }

    func isExerciseGoalCompleted(_ goal: ExerciseGoal, on date: Date) -> Bool {
        exerciseCount(for: goal, on: date) >= exerciseTarget(for: goal, on: date)
    }

    func completedExerciseGoalCount(on date: Date) -> Int {
        exerciseGoals(for: date).filter { isExerciseGoalCompleted($0, on: date) }.count
    }

    func exerciseCompletionFraction(on date: Date) -> Double {
        let goals = exerciseGoals(for: date)
        guard !goals.isEmpty else { return 0 }
        return Double(goals.filter { isExerciseGoalCompleted($0, on: date) }.count) / Double(goals.count)
    }

    func isExerciseDayCompleted(_ date: Date) -> Bool {
        let goals = exerciseGoals(for: date)
        guard !goals.isEmpty else { return false }
        return completedExerciseGoalCount(on: date) == goals.count
    }

    func setExerciseCount(_ count: Int, for goal: ExerciseGoal, on date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        let normalizedCount = max(0, count)

        if let index = exerciseRecords.firstIndex(where: { $0.goalID == goal.id && Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            exerciseRecords[index].count = normalizedCount
            exerciseRecords[index].targetCount = goal.targetCount
            exerciseRecords[index].unit = goal.unit
            exerciseRecords[index].updatedAt = Date()
        } else {
            exerciseRecords.append(ExerciseRecord(
                goalID: goal.id,
                date: day,
                count: normalizedCount,
                targetCount: goal.targetCount,
                unit: goal.unit
            ))
        }

        persistExerciseRecords()
    }

    func adjustExerciseCount(for goal: ExerciseGoal, on date: Date = Date(), by delta: Int) {
        setExerciseCount(exerciseCount(for: goal, on: date) + delta, for: goal, on: date)
    }

    func completeExerciseGoal(_ goal: ExerciseGoal, on date: Date = Date()) {
        let target = exerciseTarget(for: goal, on: date)
        setExerciseCount(target, for: goal, on: date)
    }

    func addExerciseGoal(title: String, targetCount: Int, unit: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        exerciseGoals.append(ExerciseGoal(title: trimmedTitle, targetCount: targetCount, unit: trimmedUnit.isEmpty ? "次" : trimmedUnit))
        persistExerciseGoals()
    }

    func updateExerciseGoal(_ goal: ExerciseGoal, title: String, targetCount: Int, unit: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              let index = exerciseGoals.firstIndex(where: { $0.id == goal.id }) else { return }

        exerciseGoals[index].title = trimmedTitle
        exerciseGoals[index].targetCount = max(1, targetCount)
        exerciseGoals[index].unit = trimmedUnit.isEmpty ? "次" : trimmedUnit
        exerciseGoals[index].updatedAt = Date()
        persistExerciseGoals()
    }

    func deactivateExerciseGoal(_ goal: ExerciseGoal) {
        guard activeExerciseGoals.count > 1,
              let index = exerciseGoals.firstIndex(where: { $0.id == goal.id }) else { return }

        exerciseGoals[index].isActive = false
        exerciseGoals[index].updatedAt = Date()
        persistExerciseGoals()
    }

    func moveExerciseCalendarMonth(by value: Int) {
        let calendar = Calendar.current
        exerciseCalendarMonth = calendar.date(byAdding: .month, value: value, to: exerciseCalendarMonth) ?? exerciseCalendarMonth
        
        // When changing month, if we're viewing a month other than the current month,
        // automatically select the 1st day of that month.
        // If we are back to the current month, clear selection.
        if calendar.isDate(exerciseCalendarMonth, equalTo: Date(), toGranularity: .month) {
            exerciseCalendarSelectedDate = nil
        } else {
            let components = calendar.dateComponents([.year, .month], from: exerciseCalendarMonth)
            if let firstDay = calendar.date(from: components) {
                exerciseCalendarSelectedDate = firstDay
            }
        }
    }

    func smartExerciseStep(for target: Int) -> Int {
        if target >= 1000 { return 100 }
        if target >= 100 { return 10 }
        if target >= 50 { return 5 }
        return 1
    }
}

struct AnimatedHourglassIcon: View {
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let iconSize: CGFloat = 21
    private let cycleDuration: TimeInterval = 2.5

    var body: some View {
        if reduceMotion {
            baseHourglass
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 18.0, paused: false)) { context in
                let progress = (context.date.timeIntervalSinceReferenceDate / cycleDuration)
                    .truncatingRemainder(dividingBy: 1)
                let topOpacity = max(0.22, 1 - progress * 1.15)
                let bottomOpacity = min(1, max(0.16, (progress - 0.12) / 0.88))
                let streamOpacity = progress > 0.06 && progress < 0.94 ? 0.95 : 0

                ZStack {
                    baseHourglass

                    Image(systemName: "hourglass.tophalf.filled")
                        .font(.system(size: iconSize, weight: .light))
                        .foregroundStyle(tint.opacity(topOpacity))

                    Image(systemName: "hourglass.bottomhalf.filled")
                        .font(.system(size: iconSize, weight: .light))
                        .foregroundStyle(tint.opacity(bottomOpacity))

                    Capsule()
                        .fill(tint.opacity(streamOpacity))
                        .frame(width: 2.4, height: progress < 0.9 ? 9 : 4)
                        .offset(y: -4 + progress * 9)

                    Circle()
                        .fill(tint.opacity(streamOpacity * 0.9))
                        .frame(width: 3.4, height: 3.4)
                        .offset(y: 1 + progress * 7)
                }
                .frame(width: 24, height: 24)
            }
        }
    }

    private var baseHourglass: some View {
        Image(systemName: "hourglass")
            .font(.system(size: iconSize, weight: .light))
            .foregroundStyle(tint)
            .frame(width: 24, height: 24)
    }
}

struct ExerciseCalendarDay: Identifiable {
    var date: Date
    var isInDisplayedMonth: Bool
    var isToday: Bool

    var id: Date { date }
}

struct ExerciseTodayGoalRow: View {
    let goal: ExerciseGoal
    let count: Int
    let targetCount: Int
    let unit: String
    let isCompleted: Bool
    let onComplete: () -> Void
    let onInput: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.headline)
                Text("目标 \(String(targetCount)) \(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onInput) {
                HStack(spacing: 4) {
                    Text(String(count))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(isCompleted ? .green : .primary)
                    
                    if !isCompleted {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: {
                if isCompleted {
                    onInput()
                } else {
                    onComplete()
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isCompleted ? .green : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isCompleted ? Color.green.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ExerciseHistoryTableHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("运动")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("目标")
                .frame(width: 78, alignment: .leading)

            Text("实际")
                .frame(width: 62, alignment: .leading)

            Text("状态")
                .frame(width: 44, alignment: .leading)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

struct ExerciseHistoryTableRow: View {
    let goal: ExerciseGoal
    let count: Int
    let targetCount: Int
    let unit: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(goal.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(String(targetCount)) \(unit)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)

            Text(String(count))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isCompleted ? .green : .primary)
                .frame(width: 62, alignment: .leading)

            Text(isCompleted ? "完成" : "未完成")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isCompleted ? .green : .secondary)
                .frame(width: 44, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}

struct ExerciseCalendarLegend: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

enum ExerciseGoalAction {
    case add(String, Int, String)
    case update(ExerciseGoal, String, Int, String)
    case deactivate(ExerciseGoal)
}

struct ExerciseGoalManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let initialGoals: [ExerciseGoal]
    let onSave: ([ExerciseGoalAction]) -> Void

    @State private var draftGoals: [ExerciseGoal] = []
    @State private var pendingActions: [ExerciseGoalAction] = []

    @State private var editingGoal: ExerciseGoal?
    @State private var title = ""
    @State private var targetCount = "5"
    @State private var unit = "次"
    @State private var isEditingFormVisible = false
    @FocusState private var focusedField: Field?

    private let unitSuggestions = ["次", "个", "步", "分钟", "秒", "公里", "组"]
    private let titleSuggestionsAll = ["俯卧撑", "仰卧起坐", "蹲起", "步数", "引体向上", "平板支撑", "骑行"]

    private enum Field {
        case title
    }

    var titleSuggestions: [String] {
        let existingTitles = Set(draftGoals.map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) })
        let isWalkOrSteps = existingTitles.contains("步行") || existingTitles.contains("走路") || existingTitles.contains("步数")
        
        return titleSuggestionsAll.filter { suggestion in
            if suggestion == "步数" && isWalkOrSteps {
                return false
            }
            return !existingTitles.contains(suggestion)
        }
    }

    var formTitle: String {
        editingGoal == nil ? "新增目标" : "编辑目标"
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (Int(targetCount) ?? 0) > 0
            && !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 10) {
                        ForEach(draftGoals) { goal in
                            ExerciseGoalManagerRow(
                                goal: goal,
                                canDeactivate: draftGoals.count > 1,
                                onEdit: {
                                    if isEditingFormVisible, editingGoal?.id == goal.id {
                                        resetExerciseGoalForm()
                                    } else {
                                        beginEditExerciseGoal(goal)
                                    }
                                },
                                onDeactivate: { handleDeactivate(goal) }
                            )

                            if isEditingFormVisible, editingGoal?.id == goal.id {
                                exerciseGoalForm
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                            }
                        }
                    }

                    if isEditingFormVisible && editingGoal == nil {
                        exerciseGoalForm
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                    } else {
                        Button {
                            beginAddExerciseGoal()
                        } label: {
                            Label("新增目标", systemImage: "plus")
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("目标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onSave(pendingActions)
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                }
            }
            .onAppear {
                draftGoals = initialGoals
            }
        }
    }

    var exerciseGoalForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(formTitle)
                    .font(.headline)
                Spacer()
                Button {
                    resetExerciseGoalForm()
                } label: {
                    Text("取消")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    TextField("运动名称", text: $title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .submitLabel(.done)
                            .focused($focusedField, equals: .title)

                    if editingGoal == nil && !titleSuggestions.isEmpty {
                        Menu {
                            ForEach(titleSuggestions, id: \.self) { suggestion in
                                Button(suggestion) {
                                    title = suggestion
                                    if suggestion == "步数" {
                                        unit = "步"
                                    } else if suggestion == "平板支撑" {
                                        unit = "秒"
                                    } else if suggestion == "骑行" {
                                        unit = "公里"
                                    } else {
                                        unit = "个"
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "list.bullet.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("数量", text: $targetCount)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                        .frame(maxWidth: 80)
                        .minimumScaleFactor(0.5)

                    TextField("单位", text: $unit)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(unitSuggestions, id: \.self) { suggestion in
                        Button {
                            unit = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(unit == suggestion ? Color.green : Color(.tertiarySystemFill))
                                .foregroundStyle(unit == suggestion ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                print("保存按钮被点击 - 前")
                saveExerciseGoalForm()
                print("保存按钮被点击 - 后")
            } label: {
                Text("保存")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(canSave ? Color.green : Color(.tertiarySystemFill))
                    .foregroundStyle(canSave ? .white : .secondary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
    }

    func beginAddExerciseGoal() {
        editingGoal = nil
        title = ""
        targetCount = "5"
        unit = "次"
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            isEditingFormVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            focusedField = .title
        }
    }

    func beginEditExerciseGoal(_ goal: ExerciseGoal) {
        editingGoal = goal
        title = goal.title
        targetCount = "\(goal.targetCount)"
        unit = goal.unit
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            isEditingFormVisible = true
        }
    }

    func resetExerciseGoalForm() {
        focusedField = nil
        editingGoal = nil
        title = ""
        targetCount = "5"
        unit = "次"
        withAnimation(.easeInOut(duration: 0.18)) {
            isEditingFormVisible = false
        }
    }

    func saveExerciseGoalForm() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedUnit.isEmpty, let count = Int(targetCount), count > 0 else { return }

        if let editingGoal {
            if let index = draftGoals.firstIndex(where: { $0.id == editingGoal.id }) {
                draftGoals[index].title = trimmedTitle
                draftGoals[index].targetCount = count
                draftGoals[index].unit = trimmedUnit
            }
            pendingActions.append(.update(editingGoal, trimmedTitle, count, trimmedUnit))
        } else {
            let newGoal = ExerciseGoal(title: trimmedTitle, targetCount: count, unit: trimmedUnit)
            draftGoals.append(newGoal)
            pendingActions.append(.add(trimmedTitle, count, trimmedUnit))
        }
        resetExerciseGoalForm()
    }

    func handleDeactivate(_ goal: ExerciseGoal) {
        if let index = draftGoals.firstIndex(where: { $0.id == goal.id }) {
            draftGoals.remove(at: index)
        }
        pendingActions.append(.deactivate(goal))
    }
}

struct ExerciseGoalManagerRow: View {
    let goal: ExerciseGoal
    let canDeactivate: Bool
    let onEdit: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(goal.title)
                .font(.headline)

            Spacer()
            
            Button(action: onEdit) {
                Text("\(String(goal.targetCount)) \(goal.unit)")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.body.weight(.heavy))
                    .foregroundStyle(.green)
                    .frame(width: 34, height: 34)
                    .background(Color.green.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)

            Button(action: onDeactivate) {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red.opacity(canDeactivate ? 0.75 : 0.35))
                    .frame(width: 34, height: 34)
                    .background(Color.red.opacity(canDeactivate ? 0.08 : 0.04), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canDeactivate)
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
