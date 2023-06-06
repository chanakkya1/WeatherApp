//
//  WeatherDataProvider.swift
//  Weather
//
//  Created by Mathi, Chanakya on 6/2/23.
//

import Foundation
import Combine

protocol WeatherDataProviding {
    func fetchWeather(for coordinate: Coordinate) async throws -> WeatherResponse
    func fetchWeather(city: String) async throws -> WeatherResponse
}

struct WeatherDataProvider: WeatherDataProviding {

    private let currentWeatherPath: String = "https://api.openweathermap.org/data/2.5/weather"
    private let appID = "d4f669afa9cc889b4476de06579751cd"


    func fetchWeather(for coordinate: Coordinate) async throws -> WeatherResponse {
        var urlComponents = URLComponents(string: currentWeatherPath)
        urlComponents?.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.lat)),
            URLQueryItem(name: "lon", value: String(coordinate.lon)),
            URLQueryItem(name: "appid", value: appID)
        ]

        guard let url = urlComponents?.url else {
            fatalError("Programming Error, URL should be valid")
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }

    func fetchWeather(city: String) async throws -> WeatherResponse {
        var urlComponents = URLComponents(string: currentWeatherPath)
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: appID)
        ]

        guard let url = urlComponents?.url else {
            fatalError("Programming Error, URL should be valid")
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }
}
