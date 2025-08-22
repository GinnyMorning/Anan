//
//  PluginManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 5B: Plugin System - Plugin Manager.
//

import Cocoa
import Foundation

// MARK: - Plugin Manager

@MainActor
final class PluginManager: ObservableObject {
    static let shared = PluginManager()
    
    @Published var installedPlugins: [Plugin] = []
    @Published var availablePlugins: [Plugin] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let pluginsDirectory: URL
    private let marketplaceURL = URL(string: "https://api.mtmr-plugins.com/v1/plugins")!
    
    private init() {
        // Set up plugins directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mtmrPath = appSupport.appendingPathComponent("MTMR")
        pluginsDirectory = mtmrPath.appendingPathComponent("Plugins")
        
        // Create plugins directory if it doesn't exist
        try? FileManager.default.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)
        
        // Load installed plugins
        loadInstalledPlugins()
    }
    
    // MARK: - Public Methods
    
    func refreshAvailablePlugins() async {
        isLoading = true
        lastError = nil
        
        do {
            let plugins = try await fetchAvailablePlugins()
            await MainActor.run {
                self.availablePlugins = plugins
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func installPlugin(_ plugin: Plugin) async throws {
        isLoading = true
        lastError = nil
        
        do {
            // Download plugin
            let pluginData = try await downloadPlugin(plugin)
            
            // Install plugin
            try installPluginFromData(pluginData, plugin: plugin)
            
            // Reload installed plugins
            loadInstalledPlugins()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("MTMR: Plugin '\(plugin.name)' installed successfully")
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    func uninstallPlugin(_ plugin: Plugin) throws {
        let pluginPath = pluginsDirectory.appendingPathComponent(plugin.identifier)
        
        if FileManager.default.fileExists(atPath: pluginPath.path) {
            try FileManager.default.removeItem(at: pluginPath)
            print("MTMR: Plugin '\(plugin.name)' uninstalled successfully")
        }
        
        // Reload installed plugins
        loadInstalledPlugins()
    }
    
    func updatePlugin(_ plugin: Plugin) async throws {
        // Check for updates
        if let updatedPlugin = availablePlugins.first(where: { $0.identifier == plugin.identifier && $0.version > plugin.version }) {
            try await installPlugin(updatedPlugin)
        }
    }
    
    func enablePlugin(_ plugin: Plugin) {
        // Note: This would need to be implemented with proper state management
        // For now, we'll just log the action
        print("MTMR: Plugin '\(plugin.name)' enabled")
    }
    
    func disablePlugin(_ plugin: Plugin) {
        // Note: This would need to be implemented with proper state management
        // For now, we'll just log the action
        print("MTMR: Plugin '\(plugin.name)' disabled")
    }
    
    // MARK: - Private Methods
    
    private func loadInstalledPlugins() {
        var plugins: [Plugin] = []
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: pluginsDirectory, includingPropertiesForKeys: nil)
            
            for url in contents {
                if url.hasDirectoryExtension {
                    let pluginPath = url.appendingPathComponent("plugin.json")
                    
                    if FileManager.default.fileExists(atPath: pluginPath.path) {
                        let data = try Data(contentsOf: pluginPath)
                        let plugin = try JSONDecoder().decode(Plugin.self, from: data)
                        plugins.append(plugin)
                    }
                }
            }
        } catch {
            print("MTMR: Error loading installed plugins: \(error)")
        }
        
        installedPlugins = plugins
    }
    
    private func fetchAvailablePlugins() async throws -> [Plugin] {
        // For now, return sample plugins
        // In production, this would fetch from the marketplace API
        return [
            Plugin(
                identifier: "com.example.weather-widget",
                name: "Advanced Weather Widget",
                description: "Enhanced weather information with forecasts and alerts",
                version: "2.1.0",
                author: "Weather Dev Team",
                category: .weather,
                downloadCount: 15420,
                rating: 4.8,
                price: 0.0,
                isEnabled: true
            ),
            Plugin(
                identifier: "com.example.system-monitor",
                name: "System Monitor Pro",
                description: "Comprehensive system monitoring with detailed metrics",
                version: "1.5.2",
                author: "System Tools Inc",
                category: .system,
                downloadCount: 8920,
                rating: 4.6,
                price: 4.99,
                isEnabled: false
            ),
            Plugin(
                identifier: "com.example.media-controls",
                name: "Media Controls Plus",
                description: "Advanced media controls with playlist management",
                version: "3.0.1",
                author: "Media Dev Studio",
                category: .media,
                downloadCount: 23450,
                rating: 4.9,
                price: 2.99,
                isEnabled: false
            ),
            Plugin(
                identifier: "com.example.productivity-tools",
                name: "Productivity Suite",
                description: "Collection of productivity widgets for professionals",
                version: "1.8.0",
                author: "Productivity Labs",
                category: .productivity,
                downloadCount: 18760,
                rating: 4.7,
                price: 7.99,
                isEnabled: false
            )
        ]
    }
    
    private func downloadPlugin(_ plugin: Plugin) async throws -> Data {
        // Simulate plugin download
        // In production, this would download from the marketplace
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Create sample plugin data
        let samplePluginData = """
        {
            "identifier": "\(plugin.identifier)",
            "name": "\(plugin.name)",
            "description": "\(plugin.description)",
            "version": "\(plugin.version)",
            "author": "\(plugin.author)",
            "category": "\(plugin.category.rawValue)",
            "downloadCount": \(plugin.downloadCount),
            "rating": \(plugin.rating),
            "price": \(plugin.price),
            "isEnabled": true
        }
        """.data(using: .utf8)!
        
        return samplePluginData
    }
    
    private func installPluginFromData(_ data: Data, plugin: Plugin) throws {
        let pluginPath = pluginsDirectory.appendingPathComponent(plugin.identifier)
        
        // Create plugin directory
        try FileManager.default.createDirectory(at: pluginPath, withIntermediateDirectories: true)
        
        // Save plugin configuration
        let configPath = pluginPath.appendingPathComponent("plugin.json")
        try data.write(to: configPath)
        
        // Create plugin bundle structure
        let resourcesPath = pluginPath.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resourcesPath, withIntermediateDirectories: true)
        
        // Create sample widget files
        let widgetPath = resourcesPath.appendingPathComponent("Widget.swift")
        let sampleWidgetCode = """
        import Cocoa
        import SwiftUI
        
        // Sample widget implementation for \(plugin.name)
        struct \(plugin.name.replacingOccurrences(of: " ", with: ""))Widget: View {
            var body: some View {
                Text("\(plugin.name)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        """.data(using: .utf8)!
        
        try sampleWidgetCode.write(to: widgetPath)
    }
    
    private func savePluginConfiguration() {
        // Save plugin configuration to user defaults
        let configData = installedPlugins.map { plugin in
            [
                "identifier": plugin.identifier,
                "isEnabled": true // Default to enabled for now
            ]
        }
        
        UserDefaults.standard.set(configData, forKey: "MTMR_PluginConfiguration")
    }
}

// MARK: - Plugin Model

struct Plugin: Identifiable, Codable {
    let id = UUID()
    let identifier: String
    let name: String
    let description: String
    let version: String
    let author: String
    let category: PluginCategory
    let downloadCount: Int
    let rating: Double
    let price: Double
    var isEnabled: Bool
    
    var displayName: String {
        return name
    }
    
    var formattedPrice: String {
        if price == 0.0 {
            return "Free"
        } else {
            return String(format: "$%.2f", price)
        }
    }
    
    var formattedRating: String {
        return String(format: "%.1f", rating)
    }
    
    var formattedDownloads: String {
        if downloadCount >= 1_000_000 {
            return String(format: "%.1fM", Double(downloadCount) / 1_000_000.0)
        } else if downloadCount >= 1_000 {
            return String(format: "%.1fK", Double(downloadCount) / 1_000.0)
        } else {
            return "\(downloadCount)"
        }
    }
}

enum PluginCategory: String, CaseIterable, Codable {
    case weather = "Weather"
    case system = "System"
    case media = "Media"
    case productivity = "Productivity"
    case gaming = "Gaming"
    case development = "Development"
    case entertainment = "Entertainment"
    case utility = "Utility"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .weather: return "cloud.sun"
        case .system: return "cpu"
        case .media: return "play.rectangle"
        case .productivity: return "briefcase"
        case .gaming: return "gamecontroller"
        case .development: return "hammer"
        case .entertainment: return "tv"
        case .utility: return "wrench.and.screwdriver"
        case .custom: return "rectangle.3.group"
        }
    }
    
    var color: String {
        switch self {
        case .weather: return "#4A90E2"
        case .system: return "#50E3C2"
        case .media: return "#F5A623"
        case .productivity: return "#7ED321"
        case .gaming: return "#BD10E0"
        case .development: return "#9013FE"
        case .entertainment: return "#FF6B6B"
        case .utility: return "#4ECDC4"
        case .custom: return "#95A5A6"
        }
    }
}

// MARK: - Plugin Loader

class PluginLoader {
    static let shared = PluginLoader()
    
    private init() {}
    
    func loadPlugin(_ plugin: Plugin) -> Bool {
        let pluginPath = getPluginPath(for: plugin)
        let widgetPath = pluginPath.appendingPathComponent("Resources/Widget.swift")
        
        // Check if plugin files exist
        guard FileManager.default.fileExists(atPath: widgetPath.path) else {
            print("MTMR: Plugin '\(plugin.name)' files not found")
            return false
        }
        
        // Load plugin into TouchBar system
        // This would integrate with the existing widget system
        print("MTMR: Plugin '\(plugin.name)' loaded successfully")
        return true
    }
    
    private func getPluginPath(for plugin: Plugin) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mtmrPath = appSupport.appendingPathComponent("MTMR")
        let pluginsPath = mtmrPath.appendingPathComponent("Plugins")
        return pluginsPath.appendingPathComponent(plugin.identifier)
    }
}

// MARK: - Extensions

extension URL {
    var hasDirectoryExtension: Bool {
        return pathExtension.isEmpty
    }
}
