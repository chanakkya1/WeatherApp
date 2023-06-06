//
//  WeatherTests.swift
//  WeatherTests
//
//  Created by Mathi, Chanakya on 6/2/23.
//

import XCTest
import CoreLocation
import Combine
@testable import Weather

final class WeatherTests: XCTestCase {

    var sut: WeatherViewModel!
    var dataProvider = MockWeatherDataProvider()
    var locationProvider = MockLocationManager()

    override func setUpWithError() throws {
        dataProvider = MockWeatherDataProvider()
        locationProvider = MockLocationManager()
        sut = WeatherViewModel(dataProvider: dataProvider, locationManager: locationProvider)
    }

    func testHappyPath() async {
        // When
        locationProvider.authorizationStatus = .authorizedWhenInUse
        sut.fetchCurrentLocationWeather()
        XCTAssertTrue(sut.isLoading)
        locationProvider.delegate?.locationManager?(
            CLLocationManager(),
            didUpdateLocations: [CLLocation(latitude: 20.0, longitude: 23.0)]
        )
        try? await Task.sleep(until: .now + .seconds(2), clock: .continuous) // would use a sophecticated way to listen to the updates instead of sleep
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isServiceError)
        XCTAssertFalse(sut.isLocationFailure)
        XCTAssertEqual(dataProvider.coordinateInput?.lat, 20.0)
        XCTAssertEqual(dataProvider.coordinateInput?.lon, 23.0)
        XCTAssertEqual(sut.weatherInfo?.city, "New York")
        XCTAssertEqual(sut.weatherInfo?.mainWeatherCondition, "Rainy")
        XCTAssertEqual(sut.weatherInfo?.description, "Heavy rains")
        XCTAssertEqual(sut.weatherInfo?.temperature, "200.0 kelvin")
    }

}

extension WeatherResponse {
    static var mock: Self {
        WeatherResponse(
            coord: Coordinate(lon: 11.0, lat: 12.0),
            weather: [
                Weather(
                    id: 10,
                    main: "Rainy",
                    description: "Heavy rains",
                    icon: "10d"
                )
            ],
            main: MainDetails(
                temp: 200.00,
                feels_like: nil,
                temp_min: nil,
                temp_max: nil,
                pressure: nil,
                humidity: nil,
                sea_level: nil,
                grnd_level: nil),
            clouds: Clouds(all: 100),
            name: "New York"
        )
    }
}


class MockWeatherDataProvider: WeatherDataProviding {
    var coordinateInput: Coordinate?
    var cityInput: String?

    func fetchWeather(for coordinate: Coordinate) async throws -> WeatherResponse {
        coordinateInput = coordinate
        return WeatherResponse.mock
    }

    func fetchWeather(city: String) async throws -> WeatherResponse {
        cityInput = city
        return WeatherResponse.mock
    }
}

class MockLocationManager: LocationManaging {
    var requestLocationCalled = true
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

    var delegate: CLLocationManagerDelegate?

    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    func requestLocation() {
        requestLocationCalled = true
    }
}

extension XCTestCase {
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
        var result: Result<T.Output, Error>?
        let expectation = self.expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        // Just like before, we await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }
}


