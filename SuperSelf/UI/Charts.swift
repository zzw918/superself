import SwiftUI
import Charts

struct FinanceTrendView: View {
    let points: [FinanceTrendPoint]
    let amountText: (Double) -> String

    @State private var selectedPointID: String?

    var selectedPoint: FinanceTrendPoint? {
        guard let selectedPointID else { return points.last }
        return points.first { $0.id == selectedPointID } ?? points.last
    }

    var minAmount: Double {
        (points.map(\.amount).min() ?? 0)
    }

    var maxAmount: Double {
        (points.map(\.amount).max() ?? 1)
    }

    var yDomain: ClosedRange<Double> {
        let padding = max((maxAmount - minAmount) * 0.18, maxAmount * 0.06, 1)
        let lower = max(0, minAmount - padding)
        return lower...(maxAmount + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let point = selectedPoint {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(point.topLabel)\(point.bottomLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(amountText(point.amount))
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                }
            }

            Chart {
                ForEach(points) { point in
                    AreaMark(
                        x: .value("月份", point.date),
                        y: .value("金额", point.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.28), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("月份", point.date),
                        y: .value("金额", point.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }

                if let point = selectedPoint {
                    PointMark(
                        x: .value("月份", point.date),
                        y: .value("金额", point.amount)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(90)
                    .annotation(position: .top, spacing: 4) {
                        Text(compactAmountText(point.amount))
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.4))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(compactAmountText(amount))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let xPosition = drag.location.x - geo[plotFrame].origin.x
                                    guard let date: Date = proxy.value(atX: xPosition) else { return }
                                    selectedPointID = nearestPoint(to: date)?.id
                                }
                        )
                }
            }
            .frame(height: 150)
        }
    }

    func nearestPoint(to date: Date) -> FinanceTrendPoint? {
        points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    func compactAmountText(_ amount: Double) -> String {
        if abs(amount) >= 10_000 {
            return String(format: "%.1f万", amount / 10_000)
        }

        return String(format: "%.0f", amount)
    }
}

struct FinanceDistributionView: View {
    let points: [FinanceDistributionPoint]
    let amountText: (Double) -> String

    var totalAmount: Double {
        points.map(\.amount).reduce(0, +)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Chart(points) { point in
                SectorMark(
                    angle: .value("金额", point.amount),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(point.color)
            }
            .chartLegend(.hidden)
            .frame(width: 140, height: 140)
            .overlay {
                VStack(spacing: 2) {
                    Text("总计")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(amountText(totalAmount))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(points.prefix(5)) { point in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(point.color)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.title)
                                .font(.caption.bold())
                            Text(amountText(point.amount))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        Text(percentageText(for: point.amount))
                            .font(.caption.bold())
                            .foregroundStyle(point.color)
                    }
                }
            }
        }
    }

    func percentageText(for amount: Double) -> String {
        String(format: "%.0f%%", amount / max(totalAmount, 1) * 100)
    }
}

struct BMIRangeBar: View {
    let bmi: Double?

    let minBMI = 15.0
    let maxBMI = 32.0

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

    func markerOffset(for bmi: Double, width: CGFloat) -> CGFloat {
        let clampedBMI = min(maxBMI, max(minBMI, bmi))
        let ratio = (clampedBMI - minBMI) / (maxBMI - minBMI)
        return max(0, min(width - 14, CGFloat(ratio) * width - 7))
    }
}

struct WeightTrendView: View {
    let points: [WeightTrendPoint]
    let targetWeight: Double?

    @State private var selectedID: String?

    var selectedPoint: WeightTrendPoint? {
        guard let selectedID else { return points.last }
        return points.first { $0.id == selectedID } ?? points.last
    }

    var weights: [Double] {
        if let targetWeight {
            return points.map(\.weight) + [targetWeight]
        }
        return points.map(\.weight)
    }

    var minWeight: Double { weights.min() ?? 0 }
    var maxWeight: Double { weights.max() ?? 1 }

    var yDomain: ClosedRange<Double> {
        let padding = max((maxWeight - minWeight) * 0.25, 0.5)
        return (minWeight - padding)...(maxWeight + padding)
    }

    var xDomain: ClosedRange<Date> {
        let dates = points.map(\.date).sorted()
        guard let first = dates.first, let last = dates.last else {
            let now = Date()
            return now...now.addingTimeInterval(1)
        }
        let span = last.timeIntervalSince(first)
        let pad = max(span * 0.12, 12 * 3600)
        return first.addingTimeInterval(-pad)...last.addingTimeInterval(pad)
    }

    /// 用真实数据点的日期做刻度，均匀采样最多 4 个，去重后保证不会全是同一天。
    var axisDates: [Date] {
        let sorted = points.map(\.date).sorted()
        guard sorted.count > 1 else { return sorted }

        let desired = min(4, sorted.count)
        var picked: [Date] = []
        for i in 0..<desired {
            let idx = Int((Double(i) / Double(desired - 1)) * Double(sorted.count - 1).rounded())
            picked.append(sorted[min(idx, sorted.count - 1)])
        }
        // 去重，避免数据点过少时取到相同日期
        var seen = Set<Date>()
        return picked.filter { seen.insert($0).inserted }
    }

    func label(for date: Date) -> String {
        if let match = points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
            return match.bottomLabel
        }
        return ""
    }

    private let lineColor = Color.blue
    private let tooltipColor = Color.blue
    private let targetColor = Color.orange

    var monthLabel: String {
        guard let first = points.map(\.date).min() else { return "" }
        return points.first(where: { $0.date == first })?.topLabel ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            Chart {
                if let targetWeight {
                    RuleMark(y: .value("目标", targetWeight))
                        .foregroundStyle(targetColor.opacity(0.9))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 5]))
                        .annotation(position: .top, alignment: .leading, spacing: 2) {
                            Text("目标 \(String(format: "%.1f", targetWeight))")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(targetColor, in: Capsule())
                        }
                }

                ForEach(points) { point in
                    AreaMark(
                        x: .value("日期", point.date),
                        y: .value("体重", point.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: lineColor.opacity(0.42), location: 0.0),
                                .init(color: lineColor.opacity(0.24), location: 0.32),
                                .init(color: lineColor.opacity(0.08), location: 0.66),
                                .init(color: lineColor.opacity(0.0), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .alignsMarkStylesWithPlotArea()

                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("体重", point.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                if let point = selectedPoint {
                    PointMark(
                        x: .value("日期", point.date),
                        y: .value("体重", point.weight)
                    )
                    .foregroundStyle(lineColor)
                    .symbolSize(160)
                    .annotation(position: .top, alignment: .center, spacing: 6, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        WeightCallout(
                            text: "\(String(format: "%.1f", point.weight)) kg",
                            background: tooltipColor
                        )
                    }

                    PointMark(
                        x: .value("日期", point.date),
                        y: .value("体重", point.weight)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(56)
                }
            }
            .chartYScale(domain: yDomain)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.3))
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text(String(format: "%.0f", weight))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXScale(domain: xDomain)
            .chartXAxis {
                AxisMarks(values: axisDates) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(label(for: date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { tap in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let xPosition = tap.location.x - geo[plotFrame].origin.x
                                    guard let date: Date = proxy.value(atX: xPosition) else { return }
                                    selectedID = nearestPoint(to: date)?.id
                                }
                        )
                }
            }
        }
    }

    func nearestPoint(to date: Date) -> WeightTrendPoint? {
        points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}

private struct WeightCallout: View {
    let text: String
    let background: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            CalloutArrow()
                .fill(background)
                .frame(width: 14, height: 7)
        }
        .shadow(color: background.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

private struct CalloutArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
