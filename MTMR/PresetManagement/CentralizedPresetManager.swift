//
//  CentralizedPresetManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Centralized preset management with one main configuration file.
//

import Cocoa
import Foundation

@MainActor
final class CentralizedPresetManager: ObservableObject {
    static let shared = CentralizedPresetManager()
    
    // MARK: - Configuration Paths
    private let appSupportDirectory: String
    private let mainConfigurationPath: String
    private let presetsDirectory: String
    
    // MARK: - Current State
    @Published var currentPresetName: String = "Main Configuration"
    @Published var availablePresets: [String] = []
    
    private init() {
        // Use the standard MTMR configuration path
        self.appSupportDirectory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!.appending("/MTMR")
        self.mainConfigurationPath = appSupportDirectory.appending("/items.json")
        self.presetsDirectory = appSupportDirectory.appending("/Presets")
        
        createDirectoriesIfNeeded()
        loadAvailablePresets()
        ensureMainConfigurationExists()
    }
    
    // MARK: - Directory Management
    
    private func createDirectoriesIfNeeded() {
        let fileManager = FileManager.default
        
        // Create main MTMR directory
        if !fileManager.fileExists(atPath: appSupportDirectory) {
            try? fileManager.createDirectory(atPath: appSupportDirectory, withIntermediateDirectories: true)
        }
        
        // Create presets directory
        if !fileManager.fileExists(atPath: presetsDirectory) {
            try? fileManager.createDirectory(atPath: presetsDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Main Configuration Management
    
    private func ensureMainConfigurationExists() {
        let fileManager = FileManager.default
        
        // If main configuration doesn't exist, create it from default preset
        if !fileManager.fileExists(atPath: mainConfigurationPath) {
            if let defaultPreset = Bundle.main.path(forResource: "defaultPreset", ofType: "json") {
                try? fileManager.copyItem(atPath: defaultPreset, toPath: mainConfigurationPath)
                print("MTMR: Created main configuration from default preset")
            } else {
                // Create empty configuration if no default preset
                let emptyConfig: [String: Any] = ["items": []]
                if let data = try? JSONSerialization.data(withJSONObject: emptyConfig, options: .prettyPrinted) {
                    try? data.write(to: URL(fileURLWithPath: mainConfigurationPath))
                    print("MTMR: Created empty main configuration")
                }
            }
        }
    }
    
    // MARK: - Widget Addition (Main Function)
    
    func addWidget(_ widget: WidgetDescriptor) -> Bool {
        print("MTMR: Adding widget '\(widget.name)' to main configuration")
        
        // Read current main configuration
        guard let currentConfig = readMainConfiguration() else {
            print("MTMR: Failed to read main configuration")
            return false
        }
        
        // Create widget configuration
        let widgetConfig = createWidgetConfiguration(from: widget)
        
        // Add widget to configuration
        var updatedConfig = currentConfig
        if var items = updatedConfig["items"] as? [[String: Any]] {
            items.append(widgetConfig)
            updatedConfig["items"] = items
        } else {
            updatedConfig["items"] = [widgetConfig]
        }
        
        // Write updated configuration
        if writeMainConfiguration(updatedConfig) {
            // Reload TouchBar
            TouchBarController.shared.reloadPreset(path: mainConfigurationPath)
            print("MTMR: Widget added successfully and TouchBar reloaded")
            return true
        } else {
            print("MTMR: Failed to write main configuration")
            return false
        }
    }
    
    // MARK: - Widget Removal
    
    func removeLastWidget() -> Bool {
        print("MTMR: Removing last widget from main configuration")
        
        guard let currentConfig = readMainConfiguration() else {
            return false
        }
        
        var updatedConfig = currentConfig
        if var items = updatedConfig["items"] as? [[String: Any]], !items.isEmpty {
            items.removeLast()
            updatedConfig["items"] = items
            
            if writeMainConfiguration(updatedConfig) {
                TouchBarController.shared.reloadPreset(path: mainConfigurationPath)
                print("MTMR: Widget removed successfully and TouchBar reloaded")
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Widget Duplication
    
    func duplicateLastWidget() -> Bool {
        print("MTMR: Duplicating last widget in main configuration")
        
        guard let currentConfig = readMainConfiguration() else {
            return false
        }
        
        var updatedConfig = currentConfig
        if var items = updatedConfig["items"] as? [[String: Any]], !items.isEmpty {
            let lastWidget = items.last!
            items.append(lastWidget)
            updatedConfig["items"] = items
            
            if writeMainConfiguration(updatedConfig) {
                TouchBarController.shared.reloadPreset(path: mainConfigurationPath)
                print("MTMR: Widget duplicated successfully and TouchBar reloaded")
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Preset Management
    
    func loadPreset(_ presetName: String) -> Bool {
        let presetPath = presetsDirectory.appending("/\(presetName).json")
        
        guard FileManager.default.fileExists(atPath: presetPath) else {
            print("MTMR: Preset not found: \(presetPath)")
            return false
        }
        
        // Copy preset to main configuration
        do {
            try FileManager.default.copyItem(atPath: presetPath, toPath: mainConfigurationPath)
            currentPresetName = presetName
            
            // Reload TouchBar
            TouchBarController.shared.reloadPreset(path: mainConfigurationPath)
            print("MTMR: Preset '\(presetName)' loaded successfully")
            return true
        } catch {
            print("MTMR: Failed to load preset: \(error)")
            return false
        }
    }
    
    func saveCurrentAsPreset(_ presetName: String) -> Bool {
        let presetPath = presetsDirectory.appending("/\(presetName).json")
        
        guard let currentConfig = readMainConfiguration() else {
            return false
        }
        
        if writeConfiguration(currentConfig, to: presetPath) {
            loadAvailablePresets()
            print("MTMR: Current configuration saved as preset '\(presetName)'")
            return true
        }
        
        return false
    }
    
    func exportCurrentConfiguration(to url: URL) -> Bool {
        guard let currentConfig = readMainConfiguration() else {
            return false
        }
        
        return writeConfiguration(currentConfig, to: url.path)
    }
    
    // MARK: - Helper Methods
    
    private func readMainConfiguration() -> [String: Any]? {
        return readConfiguration(from: mainConfigurationPath)
    }
    
    private func writeMainConfiguration(_ config: [String: Any]) -> Bool {
        return writeConfiguration(config, to: mainConfigurationPath)
    }
    
    private func readConfiguration(from path: String) -> [String: Any]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return config
    }
    
    private func writeConfiguration(_ config: [String: Any], to path: String) -> Bool {
        guard let data = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted) else {
            return false
        }
        
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            print("MTMR: Failed to write configuration: \(error)")
            return false
        }
    }
    
    private func createWidgetConfiguration(from widget: WidgetDescriptor) -> [String: Any] {
        var config: [String: Any] = [
            "type": widget.type,
            "title": widget.name,
            "width": widget.width ?? 100,
            "align": widget.align ?? "left"
        ]
        
        // Add any additional configuration
        widget.additionalConfig?.forEach { key, value in
            config[key] = value
        }
        
        return config
    }
    
    private func loadAvailablePresets() {
        let fileManager = FileManager.default
        availablePresets = []
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: presetsDirectory)
            for file in files where file.hasSuffix(".json") {
                let presetName = String(file.dropLast(5)) // Remove .json extension
                availablePresets.append(presetName)
            }
        } catch {
            print("MTMR: Failed to load presets: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    func getMainConfigurationPath() -> String {
        return mainConfigurationPath
    }
    
    func reloadTouchBar() {
        TouchBarController.shared.reloadPreset(path: mainConfigurationPath)
    }
}

// MARK: - Widget Descriptor

struct WidgetDescriptor {
    let name: String
    let type: String
    let width: Int?
    let align: String?
    let additionalConfig: [String: Any]?
    
    init(name: String, type: String, width: Int? = 100, align: String? = "left", additionalConfig: [String: Any]? = nil) {
        self.name = name
        self.type = type
        self.width = width
        self.align = align
        self.additionalConfig = additionalConfig
    }
}
