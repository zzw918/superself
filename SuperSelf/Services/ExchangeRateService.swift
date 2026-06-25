import Foundation
import Combine

struct ExchangeRateResponse: Codable {
    let result: String
    let base_code: String
    let rates: [String: Double]
}

class ExchangeRateService: ObservableObject {
    @Published var rates: [String: Double] = [:]
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    
    private let cacheKey = "ExchangeRateService_CachedRates"
    private let dateKey = "ExchangeRateService_LastUpdated"
    
    init() {
        loadCache()
    }
    
    func fetchRates() {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                if decoded.result == "success" {
                    DispatchQueue.main.async {
                        self.rates = decoded.rates
                        self.lastUpdated = Date()
                        self.isLoading = false
                        self.saveCache(rates: decoded.rates)
                    }
                } else {
                    DispatchQueue.main.async { self.isLoading = false }
                }
            } catch {
                print("Failed to decode exchange rates: \(error)")
                DispatchQueue.main.async { self.isLoading = false }
            }
        }.resume()
    }
    
    private func saveCache(rates: [String: Double]) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: dateKey)
        }
    }
    
    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedRates = try? JSONDecoder().decode([String: Double].self, from: data) {
            self.rates = cachedRates
            self.lastUpdated = UserDefaults.standard.object(forKey: dateKey) as? Date
        }
    }
    
    func convert(amount: Double, from source: String, to target: String) -> Double? {
        guard let sourceRate = rates[source], let targetRate = rates[target] else {
            return nil
        }
        return (amount / sourceRate) * targetRate
    }
}
