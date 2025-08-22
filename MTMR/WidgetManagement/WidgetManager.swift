//
//  WidgetManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Modern widget management with type safety and configuration support.
//

import Cocoa
import SwiftUI

@MainActor
final class WidgetManager: ObservableObject {
    static let shared = WidgetManager()
    
    @Published var availableWidgets: [WidgetDescriptor] = []
    @Published var currentConfiguration: TouchBarConfiguration?
    
    private init() {
        loadAvailableWidgets()
    }
    
    // MARK: - Widget Discovery
    
    private func loadAvailableWidgets() {
        availableWidgets = [
            // System Controls
            WidgetDescriptor(
                identifier: "escape",
                name: "Escape Key",
                description: "Essential escape key for your TouchBar",
                category: .systemControls,
                icon: "escape",
                configurationSchema: .simple([
                    .title("Escape")
                ])
            ),
            
            WidgetDescriptor(
                identifier: "volume",
                name: "Volume Controls",
                description: "Volume up, down, and mute controls",
                category: .systemControls,
                icon: "speaker.wave.3",
                configurationSchema: .group([
                    .title("Volume"),
                    .layout(.horizontal)
                ])
            ),
            
            WidgetDescriptor(
                identifier: "brightness",
                name: "Brightness Controls",
                description: "Screen brightness adjustment with slider",
                category: .systemControls,
                icon: "sun.max",
                configurationSchema: .advanced([
                    .slider("Brightness", range: 0...1, step: 0.1),
                    .toggle("Show percentage", defaultValue: false)
                ])
            ),
            
            WidgetDescriptor(
                identifier: "dnd",
                name: "Do Not Disturb",
                description: "Toggle Do Not Disturb mode",
                category: .systemControls,
                icon: "moon",
                configurationSchema: .simple([
                    .toggle("DND", defaultValue: false)
                ])
            ),
            
            // Productivity
            WidgetDescriptor(
                identifier: "weather",
                name: "Weather Widget",
                description: "Current weather conditions and temperature",
                category: .productivity,
                icon: "cloud.sun",
                configurationSchema: .advanced([
                    .locationPicker("Location"),
                    .segmentedControl("Units", options: ["Metric", "Imperial"]),
                    .numberField("Update Interval (minutes)", defaultValue: 30, range: 5...120),
                    .dropdown("Display Style", options: ["Compact", "Detailed", "Icon Only"])
                ])
            ),
            
            WidgetDescriptor(
                identifier: "clock",
                name: "Clock",
                description: "Current time display with customizable format",
                category: .productivity,
                icon: "clock",
                configurationSchema: .advanced([
                    .textField("Format", defaultValue: "HH:mm"),
                    .dropdown("Style", options: ["Digital", "Analog"]),
                    .toggle("Show seconds", defaultValue: false),
                    .toggle("24-hour format", defaultValue: true)
                ])
            ),
            
            WidgetDescriptor(
                identifier: "pomodoro",
                name: "Pomodoro Timer",
                description: "Productivity timer with work/break cycles",
                category: .productivity,
                icon: "timer",
                configurationSchema: .advanced([
                    .numberField("Work Duration (minutes)", defaultValue: 25, range: 1...120),
                    .numberField("Break Duration (minutes)", defaultValue: 5, range: 1...60),
                    .toggle("Show notifications", defaultValue: true),
                    .dropdown("Sound", options: ["Default", "Chime", "Bell", "None"])
                ])
            ),
            
            WidgetDescriptor(
                identifier: "cpu",
                name: "CPU Monitor",
                description: "Real-time CPU usage monitoring",
                category: .systemInfo,
                icon: "cpu",
                configurationSchema: .advanced([
                    .dropdown("Display Style", options: ["Percentage", "Graph", "Bar"]),
                    .numberField("Update Interval (seconds)", defaultValue: 2, range: 1...10),
                    .toggle("Show temperature", defaultValue: false),
                    .colorPicker("Color", defaultValue: .systemBlue)
                ])
            ),
            
            // Media & Apps
            WidgetDescriptor(
                identifier: "media",
                name: "Media Controls",
                description: "Play, pause, skip controls for media",
                category: .mediaApps,
                icon: "play.circle",
                configurationSchema: .group([
                    .title("Media Controls"),
                    .layout(.horizontal)
                ])
            ),
            
            WidgetDescriptor(
                identifier: "appLauncher",
                name: "App Launcher",
                description: "Quick launch button for applications",
                category: .mediaApps,
                icon: "app.badge",
                configurationSchema: .advanced([
                    .appPicker("Application"),
                    .textField("Display Name", defaultValue: ""),
                    .imagePicker("Custom Icon"),
                    .toggle("Show in dock", defaultValue: false)
                ])
            ),
            
            // Custom
            WidgetDescriptor(
                identifier: "appleScript",
                name: "AppleScript Widget",
                description: "Custom widget powered by AppleScript",
                category: .custom,
                icon: "applescript",
                configurationSchema: .advanced([
                    .textField("Title", defaultValue: "Script"),
                    .codeEditor("AppleScript", language: .applescript),
                    .numberField("Execution Interval (seconds)", defaultValue: 0, range: 0...3600),
                    .toggle("Run on startup", defaultValue: false)
                ])
            ),
            
            WidgetDescriptor(
                identifier: "shellScript",
                name: "Shell Script Widget",
                description: "Custom widget powered by shell commands",
                category: .custom,
                icon: "terminal",
                configurationSchema: .advanced([
                    .textField("Title", defaultValue: "Shell"),
                    .filePicker("Script File", allowedTypes: ["sh", "py", "rb"]),
                    .textField("Arguments", defaultValue: ""),
                    .numberField("Execution Interval (seconds)", defaultValue: 5, range: 1...3600),
                    .toggle("Show output", defaultValue: true)
                ])
            )
        ]
    }
    
    // MARK: - Quick Widget Addition
    
    func addQuickWidget(_ type: QuickWidgetType) {
        let widgetDescriptor = getDescriptor(for: type)
        let defaultConfiguration = createDefaultConfiguration(for: widgetDescriptor)
        
        print("MTMR: Adding quick widget: \(widgetDescriptor.name)")
        
        // Create the widget with default configuration
        let newWidget = WidgetConfiguration(
            id: UUID(),
            descriptor: widgetDescriptor,
            configuration: defaultConfiguration,
            position: getNextAvailablePosition()
        )
        
        // Add to current configuration
        addWidgetToCurrentConfiguration(newWidget)
        
        // Notify TouchBar to reload
        TouchBarController.shared.reloadFromWidgetManager()
    }
    
    private func getDescriptor(for type: QuickWidgetType) -> WidgetDescriptor {
        let identifier: String
        switch type {
        case .escape: identifier = "escape"
        case .volumeControls: identifier = "volume"
        case .brightnessControls: identifier = "brightness"
        case .dndToggle: identifier = "dnd"
        case .weather: identifier = "weather"
        case .clock: identifier = "clock"
        case .pomodoro: identifier = "pomodoro"
        case .cpu: identifier = "cpu"
        case .mediaControls: identifier = "media"
        case .appLauncher: identifier = "appLauncher"
        case .dock: identifier = "dock"
        }
        
        return availableWidgets.first { $0.identifier == identifier } ??
               availableWidgets.first!
    }
    
    private func createDefaultConfiguration(for descriptor: WidgetDescriptor) -> [String: Any] {
        var config: [String: Any] = [:]
        
        // Generate default configuration based on schema
        switch descriptor.configurationSchema {
        case .simple(let fields):
            for field in fields {
                if case .title(let title) = field {
                    config["title"] = title
                }
            }
        case .advanced(let fields):
            for field in fields {
                switch field {
                case .textField(let key, let defaultValue):
                    config[key.lowercased().replacingOccurrences(of: " ", with: "_")] = defaultValue
                case .numberField(let key, let defaultValue, _):
                    config[key.lowercased().replacingOccurrences(of: " ", with: "_")] = defaultValue
                case .toggle(let key, let defaultValue):
                    config[key.lowercased().replacingOccurrences(of: " ", with: "_")] = defaultValue
                case .dropdown(let key, let options):
                    config[key.lowercased().replacingOccurrences(of: " ", with: "_")] = options.first ?? ""
                default:
                    break
                }
            }
        case .group(let fields):
            for field in fields {
                if case .title(let title) = field {
                    config["title"] = title
                }
            }
        }
        
        return config
    }
    
    private func getNextAvailablePosition() -> Int {
        guard let currentConfig = currentConfiguration else { return 0 }
        return currentConfig.widgets.count
    }
    
    private func addWidgetToCurrentConfiguration(_ widget: WidgetConfiguration) {
        if currentConfiguration == nil {
            currentConfiguration = TouchBarConfiguration(
                widgets: [widget],
                layout: LayoutConfiguration(),
                globalSettings: GlobalSettings()
            )
        } else {
            currentConfiguration?.widgets.append(widget)
        }
        
        // Save configuration
        ConfigurationManager.shared.saveConfiguration(currentConfiguration!)
    }
}

// MARK: - Widget Management Extensions

extension WidgetManager {
    func getAvailableWidgets() -> [WidgetDescriptor] {
        return availableWidgets
    }
    
    func getWidgets(for category: WidgetCategory) -> [WidgetDescriptor] {
        return availableWidgets.filter { $0.category == category }
    }
    
    func searchWidgets(_ query: String) -> [WidgetDescriptor] {
        guard !query.isEmpty else { return availableWidgets }
        
        return availableWidgets.filter { widget in
            widget.name.localizedCaseInsensitiveContains(query) ||
            widget.description.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - TouchBar Integration Extension

extension TouchBarController {
    func reloadFromWidgetManager() {
        print("MTMR: Reloading TouchBar from WidgetManager...")
        
        // Get current configuration from WidgetManager
        guard let configuration = WidgetManager.shared.currentConfiguration else {
            print("MTMR: No configuration available from WidgetManager")
            return
        }
        
        // Convert WidgetConfiguration to JSON format for existing system
        let jsonItems = configuration.widgets.compactMap { widget -> [String: Any]? in
            var item: [String: Any] = [
                "type": widget.descriptor.identifier
            ]
            
            // Merge widget configuration
            widget.configuration.forEach { key, value in
                item[key] = value
            }
            
            return item
        }
        
        // Save to items.json for compatibility
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonItems, options: .prettyPrinted)
        let configPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!.appending("/MTMR/items.json")
        
        if let jsonData = jsonData {
            try? jsonData.write(to: URL(fileURLWithPath: configPath))
            print("MTMR: Saved configuration to \(configPath)")
        }
        
        // Reload using existing system
        reloadPreset(path: configPath)
    }
}
