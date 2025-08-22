//
//  PresetManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Modern preset management with import/export capabilities.
//

import Cocoa
import UniformTypeIdentifiers

@MainActor
final class PresetManager: ObservableObject {
    static let shared = PresetManager()
    
    @Published var availablePresets: [PresetDescriptor] = []
    @Published var isLoading = false
    
    private let fileManager = FileManager.default
    private let presetsDirectoryURL: URL
    
    private init() {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        presetsDirectoryURL = appSupportURL.appendingPathComponent("MTMR/Presets")
        
        createPresetsDirectoryIfNeeded()
        loadAvailablePresets()
    }
    
    // MARK: - Preset Loading
    
    func loadAvailablePresets() {
        isLoading = true
        availablePresets = []
        
        do {
            let presetFiles = try fileManager.contentsOfDirectory(at: presetsDirectoryURL, includingPropertiesForKeys: [.creationDateKey, .modificationDateKey])
            
            for file in presetFiles where file.pathExtension == "json" {
                if let preset = loadPresetDescriptor(from: file) {
                    availablePresets.append(preset)
                }
            }
            
            // Sort by modification date (newest first)
            availablePresets.sort { $0.modificationDate > $1.modificationDate }
            
        } catch {
            print("MTMR: Failed to load presets: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadPresetDescriptor(from url: URL) -> PresetDescriptor? {
        do {
            let data = try Data(contentsOf: url)
            let configuration = try ConfigurationManager.shared.loadConfiguration(from: url)
            
            // Get file attributes
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            let modificationDate = attributes[.modificationDate] as? Date ?? Date()
            
            return PresetDescriptor(
                id: UUID(),
                name: url.deletingPathExtension().lastPathComponent,
                description: generatePresetDescription(configuration),
                url: url,
                configuration: configuration,
                creationDate: creationDate,
                modificationDate: modificationDate,
                widgetCount: configuration.widgets.count
            )
        } catch {
            print("MTMR: Failed to load preset from \(url): \(error)")
            return nil
        }
    }
    
    private func generatePresetDescription(_ configuration: TouchBarConfiguration) -> String {
        let widgetTypes = configuration.widgets.map { $0.descriptor.name }
        let uniqueTypes = Array(Set(widgetTypes)).sorted()
        
        if uniqueTypes.count <= 3 {
            return uniqueTypes.joined(separator: ", ")
        } else {
            let first = uniqueTypes.prefix(3).joined(separator: ", ")
            return "\(first) and \(uniqueTypes.count - 3) more"
        }
    }
    
    // MARK: - Dialog Methods
    
    func openPresetDialog() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Preset"
        panel.showsResizeIndicator = true
        panel.showsHiddenFiles = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType.json]
        panel.directoryURL = presetsDirectoryURL
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.loadPreset(from: url)
            }
        }
    }
    
    func saveAsPresetDialog() {
        guard let currentConfig = ConfigurationManager.shared.currentConfiguration else {
            showAlert(title: "No Configuration", message: "There is no current configuration to save.")
            return
        }
        
        let panel = NSSavePanel()
        panel.title = "Save Preset As"
        panel.showsResizeIndicator = true
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [UTType.json]
        panel.directoryURL = presetsDirectoryURL
        panel.nameFieldStringValue = "My TouchBar Preset"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.savePreset(currentConfig, to: url)
            }
        }
    }
    
    func importPresetDialog() {
        let panel = NSOpenPanel()
        panel.title = "Import Preset"
        panel.showsResizeIndicator = true
        panel.showsHiddenFiles = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [UTType.json]
        
        panel.begin { [weak self] response in
            if response == .OK {
                for url in panel.urls {
                    self?.importPreset(from: url)
                }
                self?.loadAvailablePresets()
            }
        }
    }
    
    func exportPresetDialog() {
        guard let currentConfig = ConfigurationManager.shared.currentConfiguration else {
            showAlert(title: "No Configuration", message: "There is no current configuration to export.")
            return
        }
        
        let panel = NSSavePanel()
        panel.title = "Export Current Configuration"
        panel.showsResizeIndicator = true
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "MTMR-\(Date().formatted(.iso8601.day().month().year()))"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.exportPreset(currentConfig, to: url)
            }
        }
    }
    
    // MARK: - Preset Operations
    
    func loadPreset(from url: URL) {
        do {
            let configuration = try ConfigurationManager.shared.loadConfiguration(from: url)
            
            // Validate configuration
            let validation = ConfigurationManager.shared.validateConfiguration(configuration)
            if !validation.isValid {
                let errors = validation.errors.map { $0.localizedDescription }.joined(separator: "\n")
                showAlert(title: "Invalid Preset", message: "The preset contains errors:\n\n\(errors)")
                return
            }
            
            // Show warnings if any
            if !validation.warnings.isEmpty {
                let warnings = validation.warnings.map { $0.localizedDescription }.joined(separator: "\n")
                showAlert(title: "Preset Warnings", message: "The preset loaded successfully but has warnings:\n\n\(warnings)")
            }
            
            // Apply configuration
            ConfigurationManager.shared.saveConfiguration(configuration)
            TouchBarController.shared.reloadFromWidgetManager()
            
            print("MTMR: Preset loaded successfully from \(url.lastPathComponent)")
            
        } catch {
            showAlert(title: "Load Failed", message: "Failed to load preset: \(error.localizedDescription)")
        }
    }
    
    func savePreset(_ configuration: TouchBarConfiguration, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(configuration)
            try data.write(to: url)
            
            loadAvailablePresets()
            print("MTMR: Preset saved successfully to \(url.lastPathComponent)")
            
        } catch {
            showAlert(title: "Save Failed", message: "Failed to save preset: \(error.localizedDescription)")
        }
    }
    
    func importPreset(from url: URL) {
        do {
            let fileName = url.lastPathComponent
            let destinationURL = presetsDirectoryURL.appendingPathComponent(fileName)
            
            // Check if file already exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                let alert = NSAlert()
                alert.messageText = "Preset Already Exists"
                alert.informativeText = "A preset named '\(fileName)' already exists. Do you want to replace it?"
                alert.addButton(withTitle: "Replace")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .warning
                
                if alert.runModal() != .alertFirstButtonReturn {
                    return
                }
            }
            
            // Copy file to presets directory
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            
            print("MTMR: Preset imported successfully: \(fileName)")
            
        } catch {
            showAlert(title: "Import Failed", message: "Failed to import preset: \(error.localizedDescription)")
        }
    }
    
    func exportPreset(_ configuration: TouchBarConfiguration, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(configuration)
            try data.write(to: url)
            
            print("MTMR: Preset exported successfully to \(url.lastPathComponent)")
            
        } catch {
            showAlert(title: "Export Failed", message: "Failed to export preset: \(error.localizedDescription)")
        }
    }
    
    func deletePreset(_ preset: PresetDescriptor) {
        let alert = NSAlert()
        alert.messageText = "Delete Preset"
        alert.informativeText = "Are you sure you want to delete the preset '\(preset.name)'? This action cannot be undone."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .critical
        
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try fileManager.removeItem(at: preset.url)
                loadAvailablePresets()
                print("MTMR: Preset deleted: \(preset.name)")
            } catch {
                showAlert(title: "Delete Failed", message: "Failed to delete preset: \(error.localizedDescription)")
            }
        }
    }
    
    func duplicatePreset(_ preset: PresetDescriptor) {
        let newName = "\(preset.name) Copy"
        let newURL = presetsDirectoryURL.appendingPathComponent("\(newName).json")
        
        do {
            try fileManager.copyItem(at: preset.url, to: newURL)
            loadAvailablePresets()
            print("MTMR: Preset duplicated: \(newName)")
        } catch {
            showAlert(title: "Duplicate Failed", message: "Failed to duplicate preset: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Preset Manager Window
    
    func openPresetManager() {
        print("MTMR: Opening preset manager...")
        // TODO: Implement preset manager window
        // This would show a nice interface with:
        // - Grid of preset thumbnails
        // - Search and filter options
        // - Preview of preset contents
        // - Quick actions (load, duplicate, delete, export)
    }
    
    // MARK: - Utility Methods
    
    private func createPresetsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: presetsDirectoryURL.path) {
            try? fileManager.createDirectory(at: presetsDirectoryURL, withIntermediateDirectories: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}

// MARK: - Preset Descriptor

struct PresetDescriptor: Identifiable, Sendable {
    let id: UUID
    let name: String
    let description: String
    let url: URL
    let configuration: TouchBarConfiguration
    let creationDate: Date
    let modificationDate: Date
    let widgetCount: Int
    
    var formattedModificationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }
    
    var previewText: String {
        let widgets = configuration.widgets.prefix(3).map { $0.descriptor.name }
        if configuration.widgets.count > 3 {
            return widgets.joined(separator: ", ") + " +\(configuration.widgets.count - 3)"
        } else {
            return widgets.joined(separator: ", ")
        }
    }
}
