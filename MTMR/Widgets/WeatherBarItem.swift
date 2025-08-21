//
//  WeatherBarItem.swift
//  MTMR
//
//  Created by Daniel Apatin on 18.04.2018.
//  Copyright © 2018 Anton Palgunov. All rights reserved.
//

import Cocoa
import Foundation
import CoreLocation

@MainActor
class WeatherBarItem: CustomButtonTouchBarItem, @preconcurrency CLLocationManagerDelegate {
    private let activity: NSBackgroundActivityScheduler
    private var units: String
    private var iconType: String
    private var refreshInterval: TimeInterval
    private var prev_location: CLLocation!
    private var location: CLLocation!
    private var manager: CLLocationManager!
    private var isInitialized = false
    private var lastError: String?
    
    // Weather data structure
    struct WeatherData {
        let current: Current
        let hourly: Hourly
        
        struct Current {
            let time: Date
            let temperature2m: Float
            let precipitation: Float
            let rain: Float
            let isDay: Float
        }
        
        struct Hourly {
            let time: [Date]
            let temperature2m: [Float]
        }
    }
    
    // Weather icons based on conditions
    private let weatherIcons: [String: String] = [
        "clear": "☀️",
        "cloudy": "☁️",
        "rainy": "🌧️",
        "snowy": "❄️",
        "stormy": "⛈️",
        "foggy": "🌫️"
    ]

    init?(identifier: NSTouchBarItem.Identifier, refreshInterval: TimeInterval, units: String, iconType: String) {
        self.refreshInterval = refreshInterval
        self.units = units
        self.iconType = iconType
        self.activity = NSBackgroundActivityScheduler(identifier: "\(identifier.rawValue).updatecheck")
        self.activity.interval = refreshInterval
        
        super.init(identifier: identifier, title: "🌤️ Loading...")
        
        // Set up location manager
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // Set up background activity
        activity.repeats = true
        activity.qualityOfService = .utility
        activity.schedule { (completion: NSBackgroundActivityScheduler.CompletionHandler) in
            DispatchQueue.main.async {
                self.updateWeather()
            }
            completion(NSBackgroundActivityScheduler.Result.finished)
        }
        
        // Check location permissions
        let status = CLLocationManager.authorizationStatus()
        print("MTMR: Weather widget - Initial location status: \(status.rawValue)")
        
        if status == .restricted || status == .denied {
            print("MTMR: Weather widget - Location permission denied, using default location")
            useDefaultLocation()
            return
        }

        if !CLLocationManager.locationServicesEnabled() {
            print("MTMR: Weather widget - Location services disabled, using default location")
            useDefaultLocation()
            return
        }

        // Request location permission if not determined
        if status == .notDetermined {
            print("MTMR: Weather widget - Requesting location permission")
            if #available(macOS 10.15, *) {
                manager.requestWhenInUseAuthorization()
            } else {
                // For older macOS versions, try to start updates directly
                print("MTMR: Weather widget - Using legacy location method for macOS < 10.15")
                startLocationUpdates()
            }
        } else if status == .authorizedAlways {
            startLocationUpdates()
        } else {
            print("MTMR: Weather widget - Unexpected authorization status, using default location")
            useDefaultLocation()
        }
    }
    
    private func useDefaultLocation() {
        // Use default coordinates (Ho Chi Minh City area) as fallback
        let defaultLocation = CLLocation(latitude: 11.31, longitude: 106.0983)
        location = defaultLocation
        isInitialized = true
        print("MTMR: Weather widget - Using default location: \(defaultLocation.coordinate.latitude), \(defaultLocation.coordinate.longitude)")
        updateWeather()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startLocationUpdates() {
        print("MTMR: Weather widget - Starting location updates")
        manager.startUpdatingLocation()
        isInitialized = true
    }

    @objc func updateWeather() {
        guard isInitialized, let location = location else {
            if lastError != nil {
                setWeather(text: "🌤️ \(lastError!)")
            } else {
                setWeather(text: "🌤️ Getting Location...")
            }
            return
        }
        
        // Build OpenMeteo API URL
        let baseURL = "https://api.open-meteo.com/v1/forecast"
        let queryItems = [
            "latitude": String(location.coordinate.latitude),
            "longitude": String(location.coordinate.longitude),
            "hourly": "temperature_2m",
            "current": "temperature_2m,precipitation,rain,is_day",
            "temperature_unit": units == "metric" ? "celsius" : "fahrenheit",
            "precipitation_unit": "mm"
        ]
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = urlComponents.url else {
            print("MTMR: Weather widget - Invalid URL")
            setWeather(text: "🌤️ URL Error")
            return
        }
        
        print("MTMR: Weather widget - Fetching weather from: \(url)")
        
        let urlRequest = URLRequest(url: url)
        let unitsValue = units // Capture the value before the closure
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            if let error = error {
                print("MTMR: Weather widget - Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.setWeather(text: "🌤️ Network Error")
                }
                return
            }
            
            guard let data = data else {
                print("MTMR: Weather widget - No data received")
                DispatchQueue.main.async {
                    self.setWeather(text: "🌤️ No Data")
                }
                return
            }
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("MTMR: Weather widget - HTTP error: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        self.setWeather(text: "🌤️ HTTP \(httpResponse.statusCode)")
                    }
                    return
                }
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: AnyObject]
                
                // Check for API error
                if let errorMessage = json["error"] as? Bool, errorMessage == true {
                    if let reason = json["reason"] as? String {
                        print("MTMR: Weather widget - API error: \(reason)")
                        DispatchQueue.main.async {
                            self.setWeather(text: "🌤️ API Error")
                            self.lastError = reason
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.setWeather(text: "🌤️ API Error")
                        }
                    }
                    return
                }
                
                // Parse weather data
                guard let current = json["current"] as? [String: AnyObject] else {
                    print("MTMR: Weather widget - No current weather data")
                    DispatchQueue.main.async {
                        self.setWeather(text: "🌤️ No Data")
                    }
                    return
                }
                
                let temperature = current["temperature_2m"] as? Double ?? 0.0
                let precipitation = current["precipitation"] as? Double ?? 0.0
                let rain = current["rain"] as? Double ?? 0.0
                let isDay = current["is_day"] as? Double ?? 1.0
                
                // Format temperature with proper unit
                let tempUnit = unitsValue == "metric" ? "°C" : "°F"
                let formattedTemp = String(format: "%.0f", temperature)
                
                // Determine weather icon and create display text on main actor
                DispatchQueue.main.async {
                    let weatherIcon = self.getWeatherIcon(precipitation: precipitation, rain: rain, isDay: isDay)
                    var weatherText = "\(weatherIcon) \(formattedTemp)\(tempUnit)"
                    
                    // Add precipitation info if significant
                    if precipitation > 0.1 || rain > 0.1 {
                        let precipValue = max(precipitation, rain)
                        if precipValue > 5.0 {
                            weatherText += " 🌧️"
                        } else if precipValue > 0.5 {
                            weatherText += " 💧"
                        }
                    }
                    
                    self.setWeather(text: weatherText)
                    self.lastError = nil
                    
                    print("MTMR: Weather widget - Updated: \(weatherText)")
                    print("MTMR: Weather widget - Raw data: temp=\(temperature), precip=\(precipitation), rain=\(rain), isDay=\(isDay)")
                }
                
            } catch let jsonError {
                print("MTMR: Weather widget - JSON parsing error: \(jsonError.localizedDescription)")
                DispatchQueue.main.async {
                    self.setWeather(text: "🌤️ Parse Error")
                }
            }
        }

        task.resume()
    }
    
    private func getWeatherIcon(precipitation: Double, rain: Double, isDay: Double) -> String {
        let isDaytime = isDay > 0.5
        
        if rain > 5.0 || precipitation > 5.0 {
            return "🌧️" // Heavy rain
        } else if rain > 0.5 || precipitation > 0.5 {
            return "🌦️" // Light rain
        } else if isDaytime {
            return "☀️" // Sunny day
        } else {
            return "🌙" // Clear night
        }
    }

    func setWeather(text: String) {
        title = text
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        location = lastLocation
        print("MTMR: Weather widget - Location updated: \(lastLocation.coordinate.latitude), \(lastLocation.coordinate.longitude)")
        
        if prev_location == nil {
            DispatchQueue.main.async {
                self.updateWeather()
            }
        }
        prev_location = lastLocation
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        // Only log significant errors, not routine location unavailable messages
        let nsError = error as NSError
        if nsError.code != CLError.locationUnknown.rawValue {
            print("MTMR: Weather widget - Location error: \(error.localizedDescription)")
        }
        
        // If we don't have a location yet, use default location
        if location == nil {
            print("MTMR: Weather widget - Using default location")
            useDefaultLocation()
        }
        
        // Stop trying to get location updates after first failure to prevent spam
        manager?.stopUpdatingLocation()
    }

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("MTMR: Weather widget - Authorization status changed: \(status.rawValue)")
        
        switch status {
        case .authorizedAlways:
            if !isInitialized {
                startLocationUpdates()
            }
        case .denied, .restricted:
            setWeather(text: "🌤️ Location Denied")
        case .notDetermined:
            if #available(macOS 10.15, *) {
                manager?.requestWhenInUseAuthorization()
            } else {
                // For older macOS versions, try to start updates directly
                startLocationUpdates()
            }
        case .authorizedWhenInUse:
            if !isInitialized {
                startLocationUpdates()
            }
        @unknown default:
            print("MTMR: Weather widget - Unknown authorization status: \(status.rawValue)")
        }
    }
    
    deinit {
        // Note: Cannot access @MainActor properties in deinit
        // The manager will be cleaned up automatically when the object is deallocated
    }
}
