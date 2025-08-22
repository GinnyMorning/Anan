//
//  ConfigurationManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Modern configuration management with validation and persistence.
//

import Cocoa
import Combine

@MainActor
final class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    @Published var currentConfiguration: TouchBarConfiguration?
    @Published var isLoading = false
    @Published var lastError: ConfigurationError?
    
    private let fileManager = FileManager.default
    private let configurationDirectoryURL: URL
    private let currentConfigurationURL: URL
    
    private init() {
        // Setup configuration directory
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        configurationDirectoryURL = appSupportURL.appendingPathComponent("MTMR")
        currentConfigurationURL = configurationDirectoryURL.appendingPathComponent("items.json")
        
        createConfigurationDirectoryIfNeeded()
        loadCurrentConfiguration()
    }
    
    // MARK: - Configuration Loading
    
    func loadCurrentConfiguration() {
        isLoading = true
        lastError = nil
        
        do {
            if fileManager.fileExists(atPath: currentConfigurationURL.path) {
                currentConfiguration = try loadConfiguration(from: currentConfigurationURL)
                print("MTMR: Configuration loaded successfully")
            } else {
                currentConfiguration = createDefaultConfiguration()
                print("MTMR: Created default configuration")
            }
        } catch {
            lastError = .loadingFailed(error)
            currentConfiguration = createDefaultConfiguration()
            print("MTMR: Failed to load configuration, using default: \(error)")
        }
        
        isLoading = false
    }
    
    func loadConfiguration(from url: URL) throws -> TouchBarConfiguration {
        let data = try Data(contentsOf: url)
        
        // Try to load as new format first
        if let newConfig = try? JSONDecoder().decode(TouchBarConfiguration.self, from: data) {
            return newConfig
        }
        
        // Fallback to legacy JSON format
        if let legacyItems = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return try convertLegacyConfiguration(legacyItems)
        }
        
        throw ConfigurationError.invalidFormat
    }
    
    private func convertLegacyConfiguration(_ items: [[String: Any]]) throws -> TouchBarConfiguration {
        var widgets: [WidgetConfiguration] = []
        
        for (index, item) in items.enumerated() {
            guard let type = item["type"] as? String else { continue }
            
            // Find matching descriptor
            guard let descriptor = WidgetManager.shared.availableWidgets.first(where: { $0.identifier == type }) else {
                print("MTMR: Unknown widget type: \(type)")
                continue
            }
            
            // Convert configuration
            var configuration = item
            configuration.removeValue(forKey: "type")
            
            let widget = WidgetConfiguration(
                descriptor: descriptor,
                configuration: configuration,
                position: index
            )
            widgets.append(widget)
        }
        
        return TouchBarConfiguration(
            widgets: widgets,
            layout: LayoutConfiguration(),
            globalSettings: GlobalSettings()
        )
    }
    
    // MARK: - Configuration Saving
    
    func saveConfiguration(_ configuration: TouchBarConfiguration) {
        do {
            currentConfiguration = configuration
            
            // Save in new format
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(configuration)
            try data.write(to: currentConfigurationURL)
            
            // Also save in legacy format for compatibility
            try saveLegacyFormat(configuration)
            
            print("MTMR: Configuration saved successfully")
        } catch {
            lastError = .savingFailed(error)
            print("MTMR: Failed to save configuration: \(error)")
        }
    }
    
    private func saveLegacyFormat(_ configuration: TouchBarConfiguration) throws {
        let legacyItems = configuration.widgets.map { widget -> [String: Any] in
            var item: [String: Any] = ["type": widget.descriptor.identifier]
            
            // Convert AnyCodable back to regular values
            widget.configuration.forEach { key, value in
                item[key] = value.value
            }
            
            return item
        }
        
        let data = try JSONSerialization.data(withJSONObject: legacyItems, options: .prettyPrinted)
        try data.write(to: currentConfigurationURL)
    }
    
    // MARK: - Configuration Validation
    
    func validateConfiguration(_ configuration: TouchBarConfiguration) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check for duplicate widgets in same position
        let positions = configuration.widgets.map { $0.position }
        let duplicatePositions = positions.filter { position in
            positions.filter { $0 == position }.count > 1
        }
        
        if !duplicatePositions.isEmpty {
            errors.append(.duplicatePositions(duplicatePositions))
        }
        
        // Validate individual widgets
        for widget in configuration.widgets {
            let widgetValidation = validateWidget(widget)
            errors.append(contentsOf: widgetValidation.errors)
            warnings.append(contentsOf: widgetValidation.warnings)
        }
        
        // Check TouchBar capacity (max ~8-10 widgets recommended)
        if configuration.widgets.count > 10 {
            warnings.append(.tooManyWidgets(configuration.widgets.count))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func validateWidget(_ widget: WidgetConfiguration) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Validate required fields based on schema
        switch widget.descriptor.configurationSchema {
        case .simple(let fields), .advanced(let fields), .group(let fields):
            for field in fields {
                switch field {
                case .textField(let key, _):
                    let configKey = key.lowercased().replacingOccurrences(of: " ", with: "_")
                    if widget.configuration[configKey] == nil {
                        errors.append(.missingRequiredField(key, widget.descriptor.name))
                    }
                case .numberField(let key, _, let range):
                    let configKey = key.lowercased().replacingOccurrences(of: " ", with: "_")
                    if let value = widget.configuration[configKey]?.value as? Double,
                       let range = range,
                       !range.contains(value) {
                        errors.append(.valueOutOfRange(key, value, range))
                    }
                default:
                    break
                }
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Default Configuration
    
    private func createDefaultConfiguration() -> TouchBarConfiguration {
        let defaultWidgets = [
            WidgetConfiguration(
                descriptor: WidgetManager.shared.availableWidgets.first { $0.identifier == "escape" }!,
                configuration: ["title": "esc"],
                position: 0
            ),
            WidgetConfiguration(
                descriptor: WidgetManager.shared.availableWidgets.first { $0.identifier == "brightness" }!,
                configuration: ["type": "brightness"],
                position: 1
            ),
            WidgetConfiguration(
                descriptor: WidgetManager.shared.availableWidgets.first { $0.identifier == "volume" }!,
                configuration: ["type": "volume"],
                position: 2
            ),
            WidgetConfiguration(
                descriptor: WidgetManager.shared.availableWidgets.first { $0.identifier == "weather" }!,
                configuration: ["units": "metric", "update_interval": 30],
                position: 3
            )
        ]
        
        return TouchBarConfiguration(
            widgets: defaultWidgets,
            layout: LayoutConfiguration(),
            globalSettings: GlobalSettings()
        )
    }
    
    // MARK: - Utility Methods
    
    private func createConfigurationDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: configurationDirectoryURL.path) {
            try? fileManager.createDirectory(at: configurationDirectoryURL, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Error Types

enum ConfigurationError: Error, LocalizedError {
    case loadingFailed(Error)
    case savingFailed(Error)
    case invalidFormat
    case missingFile
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let error):
            return "Failed to load configuration: \(error.localizedDescription)"
        case .savingFailed(let error):
            return "Failed to save configuration: \(error.localizedDescription)"
        case .invalidFormat:
            return "Configuration file format is invalid"
        case .missingFile:
            return "Configuration file not found"
        }
    }
}

// MARK: - Validation Types

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
}

enum ValidationError: Error, LocalizedError {
    case duplicatePositions([Int])
    case missingRequiredField(String, String)
    case valueOutOfRange(String, Double, ClosedRange<Double>)
    case invalidWidgetType(String)
    
    var errorDescription: String? {
        switch self {
        case .duplicatePositions(let positions):
            return "Duplicate widgets at positions: \(positions.map(String.init).joined(separator: ", "))"
        case .missingRequiredField(let field, let widget):
            return "Missing required field '\(field)' in widget '\(widget)'"
        case .valueOutOfRange(let field, let value, let range):
            return "Value \(value) for field '\(field)' is outside valid range \(range)"
        case .invalidWidgetType(let type):
            return "Unknown widget type: \(type)"
        }
    }
}

enum ValidationWarning: LocalizedError {
    case tooManyWidgets(Int)
    case deprecatedField(String, String)
    case performanceImpact(String)
    
    var errorDescription: String? {
        switch self {
        case .tooManyWidgets(let count):
            return "You have \(count) widgets. Consider reducing to 8-10 for optimal performance."
        case .deprecatedField(let field, let widget):
            return "Field '\(field)' in widget '\(widget)' is deprecated"
        case .performanceImpact(let description):
            return "Performance impact: \(description)"
        }
    }
}
