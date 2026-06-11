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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let point = selectedPoint {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(point.topLabel)\(point.bottomLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(String(format: "%.1f", point.weight)) kg")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                }
            }

            Chart {
                if let targetWeight {
                    RuleMark(y: .value("目标", targetWeight))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .annotation(position: .top, alignment: .trailing, spacing: 2) {
                            Text("目标 \(String(format: "%.1f", targetWeight))")
                                .font(.caption2.bold())
                                .foregroundStyle(.orange)
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
                            colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("体重", point.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }

                if let point = selectedPoint {
                    PointMark(
                        x: .value("日期", point.date),
                        y: .value("体重", point.weight)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(80)
                }
            }
            .chartYScale(domain: yDomain)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.4))
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text(String(format: "%.0f", weight))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day(.defaultDigits))
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
