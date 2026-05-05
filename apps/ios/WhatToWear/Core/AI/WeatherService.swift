import Foundation
import Alamofire
import CoreLocation

class WeatherService: NSObject, CLLocationManagerDelegate {

    static let shared = WeatherService()

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var locationCompletion: ((CLLocation?) -> Void)?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        locationCompletion = completion
        locationManager.requestLocation()
    }

    func fetchWeather(completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        getCurrentLocation { [weak self] location in
            guard let location = location else {
                completion(.failure(NSError(domain: "WeatherService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location not available"])))
                return
            }

            Task {
                do {
                    let response = try await WTWAPI.AI.getWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                    DispatchQueue.main.async {
                        completion(.success(response))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func getOutfitRecommendation(weather: WeatherItem) -> (style: String, occasion: String) {
        let temp = weather.temp

        if temp < 10 {
            return ("layered", "cold_weather")
        } else if temp < 20 {
            return ("casual", "cool_weather")
        } else if temp < 28 {
            return ("light", "warm_weather")
        } else {
            return ("breathable", "hot_weather")
        }
    }

    func getClothingRecommendation(weather: WeatherItem) -> [String] {
        let temp = weather.temp
        let condition = weather.condition.lowercased()

        var recommendations: [String] = []

        if temp < 10 {
            recommendations.append("coat")
            recommendations.append("sweater")
            recommendations.append("jeans")
        } else if temp < 20 {
            recommendations.append("jacket")
            recommendations.append("tshirt")
            recommendations.append("pants")
        } else if temp < 28 {
            recommendations.append("polo")
            recommendations.append("shorts")
        } else {
            recommendations.append("tshirt")
            recommendations.append("shorts")
        }

        if condition.contains("rain") {
            recommendations.append("raincoat")
            recommendations.append("waterproof")
        }

        if weather.wind > 20 {
            recommendations.append("windbreaker")
        }

        return recommendations
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        locationCompletion?(currentLocation)
        locationCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        locationCompletion?(nil)
        locationCompletion = nil
    }
}