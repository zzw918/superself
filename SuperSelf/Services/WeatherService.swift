import Foundation
import CoreLocation

struct WeatherCity: Identifiable, Equatable, Codable {
    var name: String
    var latitude: Double
    var longitude: Double
    var country: String?
    var admin1: String?
    var admin2: String?
    var admin3: String?
    var admin4: String?
    var featureCode: String?
    var population: Int?

    var id: String {
        "\(name)-\(latitude)-\(longitude)"
    }

    var presentedName: String {
        if isCountyLevelName(name) {
            return name
        }

        let candidates = [admin4, admin3, admin2]
            .compactMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let countyLike = candidates.first(where: { isCountyLevelName($0) }) {
            return countyLike
        }

        return name
    }

    var displayName: String {
        [presentedName, admin1, name, admin2, admin3, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .filter { $0 != presentedName }
            .deduplicated()
            .joined(separator: " · ")
    }

    var detailName: String {
        [admin1, name, admin2, admin3, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .filter { $0 != presentedName }
            .deduplicated()
            .joined(separator: " · ")
    }

    private func isCountyLevelName(_ text: String) -> Bool {
        text.hasSuffix("县")
            || text.hasSuffix("区")
            || text.hasSuffix("旗")
            || text.hasSuffix("自治县")
            || text.hasSuffix("自治旗")
            || text.hasSuffix("林区")
            || text.hasSuffix("特区")
    }
}

private extension Array where Element == String {
    func deduplicated() -> [String] {
        var seen: Set<String> = []
        return filter { seen.insert($0).inserted }
    }
}

struct DailyWeatherInfo: Equatable, Identifiable {
    let id = UUID()
    var date: Date
    var weatherCode: Int
    var maxTemperature: Double
    var minTemperature: Double
    var sunrise: Date?
    var sunset: Date?
    
    var symbolName: String { WeatherInfo.symbol(for: weatherCode) }
    var conditionText: String { WeatherInfo.condition(for: weatherCode) }
    var maxTemperatureText: String { "\(Int(maxTemperature.rounded()))°" }
    var minTemperatureText: String { "\(Int(minTemperature.rounded()))°" }
}

struct WeatherInfo: Equatable {
    var temperature: Double
    var apparentTemperature: Double
    var humidity: Int
    var windSpeed: Double
    var weatherCode: Int
    var cityName: String
    var dailyForecast: [DailyWeatherInfo] = []
    
    var todayForecast: DailyWeatherInfo? {
        dailyForecast.first(where: { Calendar.current.isDateInToday($0.date) }) ?? dailyForecast.first
    }

    var symbolName: String { WeatherInfo.symbol(for: weatherCode) }
    var conditionText: String { WeatherInfo.condition(for: weatherCode) }
    var temperatureText: String { "\(Int(temperature.rounded()))°" }
    var apparentText: String { "体感 \(Int(apparentTemperature.rounded()))°" }

    static func condition(for code: Int) -> String {
        switch code {
        case 0: return "晴"
        case 1: return "大致晴朗"
        case 2: return "多云"
        case 3: return "阴"
        case 45, 48: return "雾"
        case 51, 53, 55: return "毛毛雨"
        case 56, 57: return "冻雨"
        case 61, 63, 65: return "雨"
        case 66, 67: return "冻雨"
        case 71, 73, 75, 77: return "雪"
        case 80, 81, 82: return "阵雨"
        case 85, 86: return "阵雪"
        case 95: return "雷雨"
        case 96, 99: return "雷雨伴冰雹"
        default: return "未知"
        }
    }

    static func symbol(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

enum WeatherLoadState: Equatable {
    case idle
    case loading
    case loaded(WeatherInfo)
    case denied
    case failed
}

@MainActor
final class WeatherStore: NSObject, ObservableObject {
    @Published var state: WeatherLoadState = .idle
    @Published private(set) var selectedCity: WeatherCity?
    @Published private(set) var recentCities: [WeatherCity] = []

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var isRequesting = false
    private let recentCitiesKey = "weatherRecentCities"

    var isUsingCurrentLocation: Bool {
        selectedCity == nil
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        loadRecentCities()
    }

    func refresh() {
        guard !isRequesting else { return }

        if let selectedCity {
            state = .loading
            isRequesting = true
            Task {
                await loadWeather(for: selectedCity)
                isRequesting = false
            }
            return
        }

        refreshCurrentLocation()
    }

    func useCurrentLocation() {
        guard !isRequesting else { return }
        selectedCity = nil
        refreshCurrentLocation()
    }

    func selectCity(_ city: WeatherCity) {
        guard !isRequesting else { return }
        selectedCity = city
        rememberCity(city)
        state = .loading
        isRequesting = true
        Task {
            await loadWeather(for: city)
            isRequesting = false
        }
    }

    private func rememberCity(_ city: WeatherCity) {
        recentCities.removeAll { $0.id == city.id }
        recentCities.insert(city, at: 0)
        recentCities = Array(recentCities.prefix(6))
        persistRecentCities()
    }

    private func loadRecentCities() {
        guard let data = UserDefaults.standard.data(forKey: recentCitiesKey),
              let decoded = try? JSONDecoder().decode([WeatherCity].self, from: data) else {
            return
        }
        recentCities = Array(decoded.prefix(6))
    }

    private func persistRecentCities() {
        guard let data = try? JSONEncoder().encode(recentCities) else { return }
        UserDefaults.standard.set(data, forKey: recentCitiesKey)
    }

    private func refreshCurrentLocation() {
        guard !isRequesting else { return }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            state = .loading
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            state = .denied
        default:
            state = .loading
            isRequesting = true
            locationManager.requestLocation()
        }
    }

    private func loadWeather(for city: WeatherCity) async {
        let coordinate = CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)
        guard var info = await fetchWeather(for: coordinate) else {
            state = .failed
            return
        }

        info.cityName = city.presentedName
        state = .loaded(info)
    }

    private func loadWeather(for location: CLLocation) async {
        async let city = cityName(for: location)
        async let weather = fetchWeather(for: location.coordinate)

        guard let weather = await weather else {
            state = .failed
            return
        }

        var info = weather
        info.cityName = await city
        state = .loaded(info)
    }

    private func cityName(for location: CLLocation) async -> String {
        guard let placemarks = try? await geocoder.reverseGeocodeLocation(
                  location,
                  preferredLocale: Locale(identifier: "zh_CN")
              ),
              let placemark = placemarks.first else {
            return "当前位置"
        }

        let city = placemark.locality ?? placemark.administrativeArea
        let district = placemark.subLocality ?? placemark.subAdministrativeArea

        switch (city, district) {
        case let (city?, district?):
            return city == district ? city : "\(city)\(district)"
        case let (city?, nil):
            return city
        case let (nil, district?):
            return district
        default:
            return placemark.name ?? "当前位置"
        }
    }

    private struct OpenMeteoResponse: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let relative_humidity_2m: Int
            let apparent_temperature: Double
            let wind_speed_10m: Double
            let weather_code: Int
        }
        struct Daily: Decodable {
            let time: [String]
            let weather_code: [Int]
            let temperature_2m_max: [Double]
            let temperature_2m_min: [Double]
            let sunrise: [String]?
            let sunset: [String]?
        }
        let current: Current
        let daily: Daily?
    }

    private func fetchWeather(for coordinate: CLLocationCoordinate2D) async -> WeatherInfo? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "10")
        ]

        guard let url = components?.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let current = response.current
            
            var dailyForecast: [DailyWeatherInfo] = []
            if let daily = response.daily {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone.current

                let timeFormatter = DateFormatter()
                timeFormatter.locale = Locale(identifier: "en_US_POSIX")
                timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                timeFormatter.timeZone = TimeZone.current
                
                let count = min(daily.time.count, min(daily.weather_code.count, min(daily.temperature_2m_max.count, daily.temperature_2m_min.count)))
                for i in 0..<count {
                    if let date = dateFormatter.date(from: daily.time[i]) {
                        dailyForecast.append(DailyWeatherInfo(
                            date: date,
                            weatherCode: daily.weather_code[i],
                            maxTemperature: daily.temperature_2m_max[i],
                            minTemperature: daily.temperature_2m_min[i],
                            sunrise: daily.sunrise.flatMap { i < $0.count ? timeFormatter.date(from: $0[i]) : nil },
                            sunset: daily.sunset.flatMap { i < $0.count ? timeFormatter.date(from: $0[i]) : nil }
                        ))
                    }
                }
            }
            
            return WeatherInfo(
                temperature: current.temperature_2m,
                apparentTemperature: current.apparent_temperature,
                humidity: current.relative_humidity_2m,
                windSpeed: current.wind_speed_10m,
                weatherCode: current.weather_code,
                cityName: "",
                dailyForecast: dailyForecast
            )
        } catch {
            return nil
        }
    }

    private struct OpenMeteoGeocodingResponse: Decodable {
        struct Result: Decodable {
            let name: String
            let latitude: Double
            let longitude: Double
            let country: String?
            let admin1: String?
            let admin2: String?
            let admin3: String?
            let admin4: String?
            let feature_code: String?
            let population: Int?
        }

        let results: [Result]?
    }

    func searchCities(matching query: String) async -> [WeatherCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "12"),
            URLQueryItem(name: "language", value: "zh"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
            let normalizedCities = normalizeCities(
                (response.results ?? []).map {
                    WeatherCity(
                        name: $0.name,
                        latitude: $0.latitude,
                        longitude: $0.longitude,
                        country: $0.country,
                        admin1: $0.admin1,
                        admin2: $0.admin2,
                        admin3: $0.admin3,
                        admin4: $0.admin4,
                        featureCode: $0.feature_code,
                        population: $0.population
                    )
                },
                query: trimmed
            )
            if !normalizedCities.isEmpty {
                return normalizedCities
            }

            return await searchCitiesWithSystemGeocoder(matching: trimmed)
        } catch {
            return await searchCitiesWithSystemGeocoder(matching: trimmed)
        }
    }

    private func searchCitiesWithSystemGeocoder(matching query: String) async -> [WeatherCity] {
        let placemarks = (try? await geocoder.geocodeAddressString(
            query,
            in: nil,
            preferredLocale: Locale(identifier: "zh_CN")
        )) ?? []

        let cities = placemarks.compactMap { placemark -> WeatherCity? in
            guard let location = placemark.location else { return nil }
            let rawName = placemark.locality
                ?? placemark.subAdministrativeArea
                ?? placemark.administrativeArea
                ?? placemark.name
            guard let rawName, !rawName.isEmpty else { return nil }

            return WeatherCity(
                name: rawName,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                country: placemark.country,
                admin1: placemark.administrativeArea,
                admin2: placemark.subAdministrativeArea,
                admin3: placemark.locality == rawName ? placemark.subLocality : placemark.locality,
                admin4: placemark.subLocality,
                featureCode: "APPLE_GEOCODER",
                population: nil
            )
        }

        return normalizeCities(cities, query: query)
    }

    private func normalizeCities(_ cities: [WeatherCity], query: String) -> [WeatherCity] {
        let filtered = cities
            .filter { isCityOrCountyLevel($0, query: query) }
            .sorted { lhs, rhs in
                let lhsScore = citySearchScore(lhs, query: query)
                let rhsScore = citySearchScore(rhs, query: query)
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                return (lhs.population ?? 0) > (rhs.population ?? 0)
            }

        var seen: Set<String> = []
        return filtered.filter { city in
            let key = [
                city.name,
                city.admin1,
                city.admin2,
                city.admin3,
                city.country
            ]
                .compactMap { $0 }
                .joined(separator: "-")
            return seen.insert(key).inserted
        }
    }

    private func isCityOrCountyLevel(_ city: WeatherCity, query: String) -> Bool {
        let code = city.featureCode ?? ""
        if isPreferredAdministrativeFeatureCode(code) {
            return true
        }

        let normalizedQuery = normalizedCityName(query)
        let name = normalizedCityName(city.name)
        let admin1 = normalizedCityName(city.admin1 ?? "")
        let admin2 = normalizedCityName(city.admin2 ?? "")
        let admin3 = normalizedCityName(city.admin3 ?? "")

        if !admin1.isEmpty, name == admin1 { return true }
        if !admin2.isEmpty, name == admin2 { return true }
        if !admin3.isEmpty, name == admin3 { return true }

        if code == "APPLE_GEOCODER", name == normalizedQuery {
            return !admin1.isEmpty || !admin2.isEmpty || !admin3.isEmpty
        }

        if name == normalizedQuery {
            return admin1.contains(normalizedQuery)
                || admin2.contains(normalizedQuery)
                || admin3.contains(normalizedQuery)
                || (city.population ?? 0) > 100_000
        }

        return hasCityOrCountySuffix(city.name)
    }

    private func citySearchScore(_ city: WeatherCity, query: String) -> Int {
        let normalizedQuery = normalizedCityName(query)
        let name = normalizedCityName(city.name)
        let admin1 = normalizedCityName(city.admin1 ?? "")
        let admin2 = normalizedCityName(city.admin2 ?? "")
        let admin3 = normalizedCityName(city.admin3 ?? "")
        let code = city.featureCode ?? ""

        var score = 0
        if name == normalizedQuery { score += 100 }
        if admin1 == normalizedQuery { score += 80 }
        if admin2 == normalizedQuery { score += 70 }
        if admin3 == normalizedQuery { score += 60 }
        if admin1.contains(normalizedQuery) { score += 40 }
        if admin2.contains(normalizedQuery) { score += 35 }
        if admin3.contains(normalizedQuery) { score += 30 }
        if code == "ADM1" { score += 25 }
        if code == "ADM2" { score += 20 }
        if code == "ADM3" { score += 15 }
        if code == "PPLC" { score += 24 }
        if code == "PPLA" { score += 22 }
        if code == "PPLA2" { score += 20 }
        if code == "PPLA3" { score += 18 }
        if code == "PPLA4" { score += 16 }
        if code == "APPLE_GEOCODER" { score += 10 }
        if city.country == "中国" { score += 5 }
        return score
    }

    private func isPreferredAdministrativeFeatureCode(_ code: String) -> Bool {
        [
            "ADM1", "ADM2", "ADM3",
            "PPLC", "PPLA", "PPLA2", "PPLA3", "PPLA4"
        ].contains(code)
    }

    private func normalizedCityName(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "市", with: "")
            .replacingOccurrences(of: "县", with: "")
            .replacingOccurrences(of: "区", with: "")
            .replacingOccurrences(of: "自治州", with: "")
            .replacingOccurrences(of: "自治县", with: "")
            .replacingOccurrences(of: "特别行政区", with: "")
    }

    private func hasCityOrCountySuffix(_ text: String) -> Bool {
        text.hasSuffix("市")
            || text.hasSuffix("县")
            || text.hasSuffix("区")
            || text.hasSuffix("自治州")
            || text.hasSuffix("自治县")
            || text.hasSuffix("特别行政区")
    }
}

extension WeatherStore: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if !isRequesting {
                    state = .loading
                    isRequesting = true
                    manager.requestLocation()
                }
            case .denied, .restricted:
                state = .denied
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            isRequesting = false
            await loadWeather(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isRequesting = false
            if state != .denied {
                state = .failed
            }
        }
    }
}
