//
//  WeatherViewModel.swift
//  Weather
//
//  Created by Mathi, Chanakya on 6/2/23.
//

import Combine
import CoreLocation
import Foundation



class WeatherViewModel: NSObject, ObservableObject {
    enum OpertaingError: Error, Equatable {
        case location
    }

    init(
        dataProvider: WeatherDataProviding = WeatherDataProvider(),
        locationManager: LocationManaging = CLLocationManager()
    ) {
        self.dataProvider = dataProvider
        self.locationManager = locationManager
        super.init()
        self.configureLocationManager()
        setup()
    }


    @Published var cityName = ""
    @Published private(set) var result: LoadingState<WeatherResponse> = .idle
    var coordinatesPublisher = PassthroughSubject<CLLocationCoordinate2D, Error>()
    private let dataProvider: WeatherDataProviding
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    private(set) var locationManager: LocationManaging

    var isLoading: Bool {
        result.isLoading
    }

    var isLocationFailure: Bool {
        guard case .failure(let error) = result else {
            return false
        }

        return (error as? OpertaingError) == .location
    }

    var isServiceError: Bool {
        result.isFailure && !isLocationFailure
    }

    var weatherInfo: WeatherView.Info? {
        result.data.map {
            let weather = $0.weather.first
            let iconURL = (weather?.icon).flatMap {
                URL(string: "https://openweathermap.org/img/wn/\($0)@2x.png")
            }

            return WeatherView.Info(
                city: $0.name ?? "",
                mainWeatherCondition: weather?.main ?? "",
                description: weather?.description ?? "",
                temperature: $0.main.temp.map { "\($0) kelvin" } ?? "--",
                weatherIcon: iconURL
            )
        }
    }

    func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func setup() {
        guard let city = UserDefaults.standard.string(forKey: "cityName") else {
            return
        }
        self.cityName = city
        fetchWeatherData()
    }

    func fetchWeatherData() {
        Task { @MainActor in
            result = .loading
            do {
                let weatherData = try await dataProvider.fetchWeather(city: cityName)
                result = .success(weatherData)
                saveLastfetchedToUserDefaults(cityName: cityName)
            } catch {
                result = .failure(error)
            }
        }
    }

    private func saveLastfetchedToUserDefaults(cityName: String) {
        UserDefaults.standard.set(cityName, forKey: "cityName")
    }

    func fetchCurrentLocationWeather() {
        guard
            (locationManager.authorizationStatus == .authorizedWhenInUse) || (locationManager.authorizationStatus == .authorizedAlways) else {
            return
        }

        result = .loading
        coordinatesPublisher
            .tryFirst { _ in true }
            .sink { [weak self] completion in
                switch completion {
                case .failure:
                    self?.result = .failure(OpertaingError.location)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] coordinate in
                self?.fetchWeatherData(location: coordinate)
            }.store(in: &cancellables)

        locationManager.requestLocation()
    }

    private func fetchWeatherData(location: CLLocationCoordinate2D) {
        Task { @MainActor in
            result = .loading
            do {
                let coordinate = Coordinate(lon: location.longitude, lat: location.latitude)
                let weatherData = try await dataProvider.fetchWeather(for: coordinate)
                result = .success(weatherData)
            } catch {
                result = .failure(error)
            }
        }

    }
}

extension CLLocationManager: LocationManaging { }

extension WeatherViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        fetchCurrentLocationWeather()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        coordinatesPublisher.send(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        coordinatesPublisher.send(completion: .failure(error))
    }
}


// MARK: Helper

enum LoadingState<T> {
    case idle
    case loading
    case success(T)
    case failure(Error)

    var isLoading: Bool {
        guard case .loading = self else {
            return false
        }

        return true
    }

    var isFailure: Bool {
        guard case .failure = self else {
            return false
        }

        return true
    }

    var data: T? {
        guard case .success(let data) = self else {
            return nil
        }

        return data
    }
}

protocol LocationManaging: AnyObject {
    var desiredAccuracy: CLLocationAccuracy { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var authorizationStatus:CLAuthorizationStatus { get }
    func requestLocation()
}
