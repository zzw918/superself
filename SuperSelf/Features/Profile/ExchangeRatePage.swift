import SwiftUI

struct CurrencyPair: Identifiable {
    let id = UUID()
    let from: String
    let to: String
}

struct ExchangeRatePage: View {
    @StateObject private var service = ExchangeRateService()
    
    @State private var sourceCurrency: String = "USD"
    @State private var targetCurrency: String = "CNY"
    @State private var amountText: String = "1"
    @State private var bottomAmountText: String = ""
    @State private var isEditingTop: Bool = true
    
    @State private var selectedTrendPair: CurrencyPair? = nil
    
    @FocusState private var isInputFocused: Bool
    
    let commonCurrencies = [
        ("CNY", "人民币", "¥"),
        ("USD", "美元", "$"),
        ("EUR", "欧元", "€"),
        ("GBP", "英镑", "£"),
        ("SGD", "新币", "S$"),
        ("JPY", "日元", "¥"),
        ("KRW", "韩元", "₩"),
        ("THB", "泰铢", "฿")
    ]
    
    private var foreignToCnyConversions: [(String, String)] {
        let list = [
            ("USD", "CNY"),
            ("EUR", "CNY"),
            ("GBP", "CNY"),
            ("SGD", "CNY")
        ]
        return list.sorted {
            let val1 = service.convert(amount: 1.0, from: $0.0, to: $0.1) ?? 0.0
            let val2 = service.convert(amount: 1.0, from: $1.0, to: $1.1) ?? 0.0
            return val1 > val2
        }
    }
    
    private var cnyToForeignConversions: [(String, String)] {
        let list = [
            ("CNY", "JPY"),
            ("CNY", "KRW"),
            ("CNY", "THB")
        ]
        return list.sorted {
            let val1 = service.convert(amount: 1.0, from: $0.0, to: $0.1) ?? 0.0
            let val2 = service.convert(amount: 1.0, from: $1.0, to: $1.1) ?? 0.0
            return val1 > val2
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Converter Card
                VStack(spacing: 0) {
                    // Source Row
                    HStack(spacing: 16) {
                        TextField("0", text: $amountText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .focused($isInputFocused)
                            .onChange(of: amountText) { newValue in
                                if isEditingTop {
                                    updateBottomAmount()
                                }
                            }
                            .onTapGesture {
                                isEditingTop = true
                            }
                            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                                if let textField = obj.object as? UITextField, textField.text == amountText || amountText.isEmpty {
                                    isEditingTop = true
                                }
                            }
                        
                        Spacer()
                        
                        currencyMenu(isSource: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    
                    ZStack {
                        Divider()
                            .padding(.leading, 16)
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                swapCurrencies()
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.blue)
                                .padding(8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        }
                    }
                    .zIndex(1)
                    
                    // Target Row
                    HStack(spacing: 16) {
                        TextField("0", text: $bottomAmountText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .focused($isInputFocused)
                            .onChange(of: bottomAmountText) { newValue in
                                if !isEditingTop {
                                    updateTopAmount()
                                }
                            }
                            .onTapGesture {
                                isEditingTop = false
                            }
                            // 关键修复：当用户开始输入时，也标记当前正在编辑下方，避免 onChange 被忽略
                            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                                if let textField = obj.object as? UITextField, textField.text == bottomAmountText || bottomAmountText.isEmpty {
                                    isEditingTop = false
                                }
                            }
                        
                        Spacer()
                        
                        currencyMenu(isSource: false)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Common Conversions List
                VStack(alignment: .leading, spacing: 20) {
                    // Category 1: Foreign to CNY
                    VStack(alignment: .leading, spacing: 12) {
                        Text("外币兑换人民币")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            let conversions = foreignToCnyConversions
                            ForEach(Array(conversions.enumerated()), id: \.element.0) { index, item in
                                commonConversionRow(from: item.0, to: item.1, isLast: index == conversions.count - 1)
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    // Category 2: CNY to Foreign
                    VStack(alignment: .leading, spacing: 12) {
                        Text("人民币兑换外币")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            let conversions = cnyToForeignConversions
                            ForEach(Array(conversions.enumerated()), id: \.element.1) { index, item in
                                commonConversionRow(from: item.0, to: item.1, isLast: index == conversions.count - 1)
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("汇率转换")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTrendPair) { pair in
            let fromName = commonCurrencies.first(where: { $0.0 == pair.from })?.1 ?? pair.from
            let toName = commonCurrencies.first(where: { $0.0 == pair.to })?.1 ?? pair.to
            ExchangeRateTrendPage(from: pair.from, to: pair.to, fromName: fromName, toName: toName)
        }
        .onAppear {
            if service.rates.isEmpty {
                service.fetchRates()
            } else {
                updateBottomAmount()
            }
        }
        .onChange(of: service.rates) { _ in
            if isEditingTop {
                updateBottomAmount()
            } else {
                updateTopAmount()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    isInputFocused = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func currencyMenu(isSource: Bool) -> some View {
        let currency = isSource ? sourceCurrency : targetCurrency
        let info = commonCurrencies.first(where: { $0.0 == currency })
        
        Menu {
            ForEach(commonCurrencies, id: \.0) { item in
                Button {
                    if isSource {
                        sourceCurrency = item.0
                        if isEditingTop {
                            updateBottomAmount()
                        } else {
                            updateTopAmount()
                        }
                    } else {
                        targetCurrency = item.0
                        if isEditingTop {
                            updateBottomAmount()
                        } else {
                            updateTopAmount()
                        }
                    }
                } label: {
                    Text("\(item.1) (\(item.0))")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(info?.1 ?? "") (\(currency))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func swapCurrencies() {
        let temp = sourceCurrency
        sourceCurrency = targetCurrency
        targetCurrency = temp
        
        let tempAmount = amountText
        amountText = bottomAmountText
        bottomAmountText = tempAmount
    }
    
    private func updateBottomAmount() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: "")),
              let converted = service.convert(amount: amount, from: sourceCurrency, to: targetCurrency) else {
            if amountText.isEmpty {
                bottomAmountText = ""
            }
            return
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        bottomAmountText = formatter.string(from: NSNumber(value: converted)) ?? ""
    }
    
    private func updateTopAmount() {
        guard let amount = Double(bottomAmountText.replacingOccurrences(of: ",", with: "")),
              let converted = service.convert(amount: amount, from: targetCurrency, to: sourceCurrency) else {
            if bottomAmountText.isEmpty {
                amountText = ""
            }
            return
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        amountText = formatter.string(from: NSNumber(value: converted)) ?? ""
    }
    
    private func commonConversionRow(from: String, to: String, isLast: Bool) -> some View {
        let fromInfo = commonCurrencies.first(where: { $0.0 == from })
        let toInfo = commonCurrencies.first(where: { $0.0 == to })
        
        let amount: Double = 1.0
        let converted = service.convert(amount: amount, from: from, to: to)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let convertedString = converted != nil ? (formatter.string(from: NSNumber(value: converted!)) ?? "--") : "--"
        
        return Button {
            selectedTrendPair = CurrencyPair(from: from, to: to)
        } label: {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("1 \(fromInfo?.1 ?? from)")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text(from)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(convertedString)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                        
                        Text(toInfo?.1 ?? to)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(to)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                
                if !isLast {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        ExchangeRatePage()
    }
}
