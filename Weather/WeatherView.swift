//
//  ContentView.swift
//  Weather
//
//  Created by Mathi, Chanakya on 6/2/23.
//

import SwiftUI
import CoreLocationUI

struct WeatherView: View {
    struct Info {
        let city: String
        let mainWeatherCondition: String
        let description: String
        let temperature: String
        let weatherIcon: URL?
    }

    @StateObject var viewModel = WeatherViewModel()
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        NavigationView {
            VStack {
                TextField("City", text: $viewModel.cityName)
                    .focused($fieldIsFocused)
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    .border(.secondary)
                    .onSubmit {
                        viewModel.fetchWeatherData()
                    }
                Spacer()
                    .frame(height: 20.0)

                LocationButton(.currentLocation){
                    viewModel.fetchCurrentLocationWeather()
                }
                Spacer()
                    .frame(height: 30.0)

                if viewModel.isLoading {
                    ProgressView()
                }

                if viewModel.isLocationFailure {
                    Text("Failed to get Current Location")
                }

                if viewModel.isServiceError {
                    Text("Failed to fetch Data")
                }

                if let info = viewModel.weatherInfo {
                    VStack {
                        Text(info.city)
                            .font(.title)
                        AsyncImage(url: info.weatherIcon)
                            .frame(width: 30.0, height: 30.0)
                            .padding()
                        row(title: "Temperature", value: info.temperature)
                        row(title: "Conditions", value: info.mainWeatherCondition)
                        row(title: "Description", value: info.description)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Weather")
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fieldIsFocused = true
        }

    }

    @ViewBuilder
    func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .padding(EdgeInsets(top: 0.2, leading: 0.0, bottom: 0.0, trailing: 0.0))
        .border(.black)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}
