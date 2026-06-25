import SwiftUI
import Charts

struct HistoricalRateResponse: Codable {
    let amount: Double
    let base: String
    let start_date: String
    let end_date: String
    let rates: [String: [String: Double]]
}

enum TimeRange: Int, CaseIterable, Identifiable {
    case oneYear = 1
    case fiveYears = 5
    case tenYears = 10
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .oneYear: return "1年"
        case .fiveYears: return "5年"
        case .tenYears: return "10年"
        }
    }
}

struct ExchangeRateTrendPage: View {
    let from: String
    let to: String
    let fromName: String
    let toName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var historicalData: [(Date, Double)] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedRange: TimeRange = .oneYear
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("加载趋势数据...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(fromName)兑\(toName)")
                                    .font(.system(size: 24, weight: .bold))
                                Text("最近\(selectedRange.rawValue)年趋势")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            
                            Picker("时间范围", selection: $selectedRange) {
                                ForEach(TimeRange.allCases) { range in
                                    Text(range.title).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            if !historicalData.isEmpty {
                                let minRate = historicalData.map { $0.1 }.min() ?? 0
                                let maxRate = historicalData.map { $0.1 }.max() ?? 1
                                let padding = (maxRate - minRate) * 0.1
                                
                                Chart {
                                    ForEach(historicalData, id: \.0) { item in
                                        LineMark(
                                            x: .value("Date", item.0),
                                            y: .value("Rate", item.1)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(.blue.gradient)
                                        
                                        AreaMark(
                                            x: .value("Date", item.0),
                                            yStart: .value("Min", minRate - padding),
                                            yEnd: .value("Rate", item.1)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(.blue.opacity(0.1).gradient)
                                    }
                                }
                                .chartYScale(domain: (minRate - padding)...(maxRate + padding))
                                .chartXAxis {
                                    let strideComponent: Calendar.Component = selectedRange == .oneYear ? .month : .year
                                    let strideCount = selectedRange == .oneYear ? 3 : (selectedRange == .fiveYears ? 1 : 2)
                                    
                                    AxisMarks(values: .stride(by: strideComponent, count: strideCount)) { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel {
                                                Text(formatAxisDate(date))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        AxisGridLine()
                                    }
                                }
                                .frame(height: 280)
                                .padding(.horizontal)
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(selectedRange.rawValue)年内最低")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.2f", minRate))
                                            .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                                    }
                                    
                                    Divider()
                                        .frame(height: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(selectedRange.rawValue)年内最高")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.2f", maxRate))
                                            .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal)
                                
                            } else {
                                Text("暂无数据")
                                    .frame(height: 250)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("汇率趋势")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchHistoricalData()
            }
            .onChange(of: selectedRange) { _ in
                fetchHistoricalData()
            }
        }
        .presentationDetents([.fraction(0.75), .large])
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        if selectedRange == .oneYear {
            formatter.dateFormat = "M月"
        } else {
            formatter.dateFormat = "yyyy年"
        }
        return formatter.string(from: date)
    }
    
    private func fetchHistoricalData() {
        isLoading = true
        errorMessage = nil
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -selectedRange.rawValue, to: endDate)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        let urlString = "https://api.frankfurter.app/\(startString)..\(endString)?from=\(from)&to=\(to)"
        guard let url = URL(string: urlString) else {
            errorMessage = "无效的请求URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "加载失败: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "暂无数据"
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(HistoricalRateResponse.self, from: data)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    var result: [(Date, Double)] = []
                    for (dateString, rates) in decoded.rates {
                        if let date = dateFormatter.date(from: dateString), let rate = rates[to] {
                            result.append((date, rate))
                        }
                    }
                    result.sort { $0.0 < $1.0 }
                    self.historicalData = result
                    
                    if result.isEmpty {
                        self.errorMessage = "暂无该货币对的趋势数据"
                    }
                } catch {
                    self.errorMessage = "数据解析失败"
                }
            }
        }.resume()
    }
}
