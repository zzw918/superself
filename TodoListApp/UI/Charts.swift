import SwiftUI

struct FinanceTrendView: View {
    let points: [FinanceTrendPoint]
    let amountText: (Double) -> String

    let chartHeight: CGFloat = 92
    let pointWidth: CGFloat = 52
    let pointSpacing: CGFloat = 10

    var amounts: [Double] {
        points.map(\.amount)
    }

    var minAmount: Double {
        amounts.min() ?? 0
    }

    var maxAmount: Double {
        amounts.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let lastPoint = points.last {
                Text("\(lastPoint.topLabel)\(lastPoint.bottomLabel) \(amountText(lastPoint.amount))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: pointSpacing) {
                    ForEach(points) { point in
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                Color.clear
                                    .frame(height: chartHeight)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.gradient)
                                    .frame(height: barHeight(for: point.amount))

                                Text(compactAmountText(point.amount))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, barHeight(for: point.amount) + 6)
                            }

                            Text(point.bottomLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: pointWidth)
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    func barHeight(for amount: Double) -> CGFloat {
        guard maxAmount > minAmount else { return chartHeight * 0.7 }

        let ratio = (amount - minAmount) / (maxAmount - minAmount)
        return CGFloat(26 + ratio * Double(chartHeight - 26))
    }

    func compactAmountText(_ amount: Double) -> String {
        if abs(amount) >= 10_000 {
            return String(format: "%.0f万", amount / 10_000)
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
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    PieSliceShape(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index)
                    )
                    .fill(point.color)
                }

                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 72, height: 72)

                VStack(spacing: 2) {
                    Text("总计")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(amountText(totalAmount))
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(points.prefix(5)) { point in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(point.color)
                            .frame(width: 9, height: 9)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.title)
                                .font(.caption.bold())
                            Text("\(amountText(point.amount)) · \(percentageText(for: point.amount))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    func startAngle(for index: Int) -> Angle {
        let previousAmount = points.prefix(index).map(\.amount).reduce(0, +)
        return .degrees(-90 + 360 * previousAmount / max(totalAmount, 1))
    }

    func endAngle(for index: Int) -> Angle {
        let amount = points.prefix(index + 1).map(\.amount).reduce(0, +)
        return .degrees(-90 + 360 * amount / max(totalAmount, 1))
    }

    func percentageText(for amount: Double) -> String {
        String(format: "%.0f%%", amount / max(totalAmount, 1) * 100)
    }
}

struct PieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
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

struct VisibleTrendPointInfo: Equatable {
    let id: String
    let minX: CGFloat
    let maxX: CGFloat
    let topLabel: String
}

struct VisibleTrendPointPreferenceKey: PreferenceKey {
    static var defaultValue: [VisibleTrendPointInfo] = []

    static func reduce(value: inout [VisibleTrendPointInfo], nextValue: () -> [VisibleTrendPointInfo]) {
        value.append(contentsOf: nextValue())
    }
}

struct WeightTrendView: View {
    let points: [WeightTrendPoint]
    let targetWeight: Double?

    let chartHeight: CGFloat = 78
    let valueLabelHeight: CGFloat = 20
    let pointWidth: CGFloat = 42
    let pointSpacing: CGFloat = 8
    @State private var visibleLeadingLabel: String?

    var weights: [Double] {
        if let targetWeight {
            return points.map(\.weight) + [targetWeight]
        }

        return points.map(\.weight)
    }

    var minWeight: Double {
        weights.min() ?? 0
    }

    var maxWeight: Double {
        weights.max() ?? 1
    }

    var leadingTopLabel: String? {
        visibleLeadingLabel ?? points.first?.topLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let leadingTopLabel {
                Text(leadingTopLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                    .padding(.top, 18)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .bottom, spacing: pointSpacing) {
                        ForEach(points) { point in
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottom) {
                                    Color.clear
                                        .frame(height: chartHeight + valueLabelHeight)

                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue.gradient)
                                        .frame(height: barHeight(for: point.weight))

                                    Text(String(format: "%.1f", point.weight))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, barHeight(for: point.weight) + 6)
                                }

                                Text(point.bottomLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: pointWidth)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: VisibleTrendPointPreferenceKey.self,
                                        value: [
                                            VisibleTrendPointInfo(
                                                id: point.id,
                                                minX: proxy.frame(in: .named("weightTrendScroll")).minX,
                                                maxX: proxy.frame(in: .named("weightTrendScroll")).maxX,
                                                topLabel: point.topLabel
                                            )
                                        ]
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 8)

                    if let targetWeight {
                        targetLine(for: targetWeight)
                            .offset(y: targetLineOffset(for: targetWeight))
                    }
                }
            }
            .coordinateSpace(name: "weightTrendScroll")
            .onPreferenceChange(VisibleTrendPointPreferenceKey.self) { infos in
                let visibleInfos = infos
                    .filter { $0.maxX > 0 }
                    .sorted { $0.minX < $1.minX }

                visibleLeadingLabel = visibleInfos.first?.topLabel ?? points.first?.topLabel
            }
        }
    }

    func barHeight(for weight: Double) -> CGFloat {
        guard maxWeight > minWeight else { return chartHeight * 0.7 }

        let ratio = (weight - minWeight) / (maxWeight - minWeight)
        return CGFloat(24 + ratio * Double(chartHeight - 24))
    }

    func targetLineOffset(for targetWeight: Double) -> CGFloat {
        8 + valueLabelHeight + chartHeight - barHeight(for: targetWeight)
    }

    func targetLine(for targetWeight: Double) -> some View {
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
