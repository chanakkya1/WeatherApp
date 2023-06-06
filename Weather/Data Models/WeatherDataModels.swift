//
//  WeatherDataModels.swift
//  Weather
//
//  Created by Mathi, Chanakya on 6/2/23.
//

import Foundation

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Coordinate: Codable {
    let lon: Double
    let lat: Double
}

struct MainDetails: Codable {
    let temp: Double?
    let feels_like: Double?
    let temp_min: Double?
    let temp_max: Double?
    let pressure: Double?
    let humidity: Double?
    let sea_level: Double?
    let grnd_level: Double?
}

struct Clouds: Codable {
    var all: Double
}

struct WeatherResponse: Codable {
    let coord: Coordinate
    let weather: [Weather]
    let main: MainDetails
    let clouds: Clouds
    let name: String?
}
