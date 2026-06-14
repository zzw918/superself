import Foundation
import CoreLocation

struct WeatherInfo: Equatable {
    var temperature: Double
    var apparentTemperature: Double
    var humidity: Int
    var weatherCode: Int
    var cityName: String

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

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var isRequesting = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh() {
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

    private func fetchWeather(for coordinate: CLLocationCoordinate2D) async -> WeatherInfo? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components?.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let current = response.current
            return WeatherInfo(
                temperature: current.temperature_2m,
                apparentTemperature: current.apparent_temperature,
                humidity: current.relative_humidity_2m,
                weatherCode: current.weather_code,
                cityName: ""
            )
        } catch {
            return nil
        }
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

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let relative_humidity_2m: Int
        let apparent_temperature: Double
        let weather_code: Int
    }
    let current: Current
}
