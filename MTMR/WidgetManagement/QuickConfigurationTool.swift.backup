//
//  QuickConfigurationTool.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 3: Quick Configuration Shortcuts and Quick Access Tools.
//

import Cocoa
import SwiftUI

// MARK: - Quick Configuration Tool

@MainActor
final class QuickConfigurationTool: ObservableObject {
    static let shared = QuickConfigurationTool()
    
    @Published var isVisible = false
    @Published var currentWidget: WidgetConfiguration?
    @Published var quickActions: [QuickAction] = []
    
    private var configurationWindow: NSWindow?
    private let configurationManager = ConfigurationManager.shared
    private let widgetManager = WidgetManager.shared
    
    private init() {
        setupQuickActions()
    }
    
    // MARK: - Public Methods
    
    func showQuickConfiguration(for widget: WidgetConfiguration) {
        currentWidget = widget
        isVisible = true
        
        if configurationWindow == nil {
            createConfigurationWindow()
        }
        
        configurationWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showQuickActions(for widget: WidgetConfiguration) {
        currentWidget = widget
        updateQuickActions(for: widget)
        
        let quickActionsWindow = createQuickActionsWindow()
        quickActionsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Private Methods
    
    private func setupQuickActions() {
        quickActions = [
            QuickAction(id: "duplicate", title: "Duplicate Widget", icon: "plus.square.on.square", action: duplicateWidget),
            QuickAction(id: "move", title: "Move Widget", icon: "arrow.up.arrow.down", action: moveWidget),
            QuickAction(id: "delete", title: "Delete Widget", icon: "trash", action: deleteWidget),
            QuickAction(id: "reset", title: "Reset to Default", icon: "arrow.clockwise", action: resetWidget),
            QuickAction(id: "export", title: "Export Configuration", icon: "square.and.arrow.up", action: exportWidget),
            QuickAction(id: "share", title: "Share Widget", icon: "square.and.arrow.up", action: shareWidget)
        ]
    }
    
    private func updateQuickActions(for widget: WidgetConfiguration) {
        // Update action availability based on widget type and current state
        for action in quickActions {
            action.isEnabled = isActionEnabled(action, for: widget)
        }
    }
    
    private func isActionEnabled(_ action: QuickAction, for widget: WidgetConfiguration) -> Bool {
        switch action.id {
        case "duplicate":
            return true // Always available
        case "move":
            return configurationManager.currentConfiguration?.widgets.count ?? 0 > 1
        case "delete":
            return true // Always available
        case "reset":
            return widget.configuration.count > 0
        case "export":
            return true // Always available
        case "share":
            return true // Always available
        default:
            return true
        }
    }
    
    private func createConfigurationWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Quick Widget Configuration"
        window.center()
        window.setFrameAutosaveName("QuickConfigurationWindow")
        
        // Create SwiftUI view
        let configurationView = QuickConfigurationView(
            widget: $currentWidget,
            onSave: { [weak self] in
                self?.saveConfiguration()
            },
            onCancel: { [weak self] in
                self?.closeConfigurationWindow()
            }
        )
        
        let hostingView = NSHostingView(rootView: configurationView)
        window.contentView = hostingView
        
        self.configurationWindow = window
    }
    
    private func createQuickActionsWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Quick Actions"
        window.center()
        
        let quickActionsView = QuickActionsView(
            actions: quickActions,
            onActionSelected: { [weak self] action in
                self?.executeAction(action)
            }
        )
        
        let hostingView = NSHostingView(rootView: quickActionsView)
        window.contentView = hostingView
        
        return window
    }
    
    private func closeConfigurationWindow() {
        configurationWindow?.close()
        configurationWindow = nil
        isVisible = false
        currentWidget = nil
    }
    
    private func saveConfiguration() {
        guard let widget = currentWidget else { return }
        
        // Update the widget in the current configuration
        if let config = configurationManager.currentConfiguration,
           let index = config.widgets.firstIndex(where: { $0.id == widget.id }) {
            config.widgets[index] = widget
            
            // Save configuration
            do {
                try configurationManager.saveConfiguration(config)
                print("MTMR: Widget configuration saved successfully")
                
                // Reload TouchBar
                TouchBarController.shared.reloadPreset(path: nil)
                
                // Show success feedback
                showSuccessAlert()
                
                // Close window
                closeConfigurationWindow()
            } catch {
                showErrorAlert(error: error)
            }
        }
    }
    
    // MARK: - Quick Actions Implementation
    
    private func duplicateWidget() {
        guard let widget = currentWidget else { return }
        
        let duplicatedWidget = WidgetConfiguration(
            descriptor: widget.descriptor,
            configuration: widget.configuration,
            position: widget.position + 1
        )
        
        // Add to configuration
        if let config = configurationManager.currentConfiguration {
            config.widgets.append(duplicatedWidget)
            
            // Save and reload
            do {
                try configurationManager.saveConfiguration(config)
                TouchBarController.shared.reloadPreset(path: nil)
                showSuccessAlert(message: "Widget duplicated successfully!")
            } catch {
                showErrorAlert(error: error)
            }
        }
    }
    
    private func moveWidget() {
        guard let widget = currentWidget else { return }
        
        let moveDialog = MoveWidgetDialog(widget: widget)
        moveDialog.show()
    }
    
    private func deleteWidget() {
        guard let widget = currentWidget else { return }
        
        let alert = NSAlert()
        alert.messageText = "Delete Widget"
        alert.informativeText = "Are you sure you want to delete '\(widget.descriptor.name)'? This action cannot be undone."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            deleteWidgetConfirmed(widget)
        }
    }
    
    private func deleteWidgetConfirmed(_ widget: WidgetConfiguration) {
        if let config = configurationManager.currentConfiguration,
           let index = config.widgets.firstIndex(where: { $0.id == widget.id }) {
            config.widgets.remove(at: index)
            
            // Save and reload
            do {
                try configurationManager.saveConfiguration(config)
                TouchBarController.shared.reloadPreset(path: nil)
                showSuccessAlert(message: "Widget deleted successfully!")
            } catch {
                showErrorAlert(error: error)
            }
        }
    }
    
    private func resetWidget() {
        guard let widget = currentWidget else { return }
        
        let alert = NSAlert()
        alert.messageText = "Reset Widget"
        alert.informativeText = "Are you sure you want to reset '\(widget.descriptor.name)' to its default configuration?"
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            resetWidgetConfirmed(widget)
        }
    }
    
    private func resetWidgetConfirmed(_ widget: WidgetConfiguration) {
        var resetWidget = widget
        resetWidget.configuration = [:]
        
        // Update in configuration
        if let config = configurationManager.currentConfiguration,
           let index = config.widgets.firstIndex(where: { $0.id == widget.id }) {
            config.widgets[index] = resetWidget
            
            // Save and reload
            do {
                try configurationManager.saveConfiguration(config)
                TouchBarController.shared.reloadPreset(path: nil)
                showSuccessAlert(message: "Widget reset to default!")
            } catch {
                showErrorAlert(error: error)
            }
        }
    }
    
    private func exportWidget() {
        guard let widget = currentWidget else { return }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export Widget Configuration"
        savePanel.nameFieldStringValue = "\(widget.descriptor.name)_config.json"
        savePanel.allowedContentTypes = [.json]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.exportWidgetToURL(widget, url: url)
            }
        }
    }
    
    private func exportWidgetToURL(_ widget: WidgetConfiguration, url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(widget)
            try data.write(to: url)
            
            showSuccessAlert(message: "Widget exported successfully!")
        } catch {
            showErrorAlert(error: error)
        }
    }
    
    private func shareWidget() {
        guard let widget = currentWidget else { return }
        
        // Create sharing content
        let sharingText = """
        MTMR Widget: \(widget.descriptor.name)
        
        Type: \(widget.descriptor.identifier)
        Description: \(widget.descriptor.description)
        
        Configuration:
        \(widget.configuration.map { "  \($0.key): \($0.value)" }.joined(separator: "\n"))
        """
        
        let sharingService = NSSharingServicePicker(items: [sharingText])
        sharingService.show(relativeTo: NSRect.zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
    }
    
    private func executeAction(_ action: QuickAction) {
        action.action()
    }
    
    // MARK: - Helper Methods
    
    private func showSuccessAlert(message: String = "Configuration saved successfully!") {
        let alert = NSAlert()
        alert.messageText = "Success"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = "Failed to save configuration: \(error.localizedDescription)"
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        alert.runModal()
    }
}

// MARK: - Quick Action Model

struct QuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let action: () -> Void
    var isEnabled: Bool = true
}

// MARK: - SwiftUI Views

struct QuickConfigurationView: View {
    @Binding var widget: WidgetConfiguration?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var configuration: [String: String] = [:]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Configuration fields
            configurationFieldsView
            
            Spacer()
            
            // Action buttons
            actionButtonsView
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            loadConfiguration()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            if let widget = widget {
                HStack {
                    if let icon = widget.descriptor.systemIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(widget.descriptor.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(widget.descriptor.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var configurationFieldsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let widget = widget {
                    ForEach(Array(widget.descriptor.configurationSchema.fields), id: \.displayName) { field in
                        ConfigurationFieldView(
                            field: field,
                            value: binding(for: field.displayName)
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var actionButtonsView: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            .keyboardShortcut(.escape)
            
            Spacer()
            
            Button("Save Configuration") {
                saveConfiguration()
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
    }
    
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { configuration[key] ?? "" },
            set: { configuration[key] = $0 }
        )
    }
    
    private func loadConfiguration() {
        guard let widget = widget else { return }
        
        // Convert AnyCodable to String for editing
        for (key, value) in widget.configuration {
            configuration[key] = String(describing: value.value)
        }
    }
    
    private func saveConfiguration() {
        guard let widget = widget else { return }
        
        // Convert String back to AnyCodable
        for (key, value) in configuration {
            widget.configuration[key] = AnyCodable(value)
        }
    }
}

struct QuickActionsView: View {
    let actions: [QuickAction]
    let onActionSelected: (QuickAction) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            // Actions list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(actions) { action in
                        QuickActionRow(
                            action: action,
                            onTap: { onActionSelected(action) }
                        )
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}

struct QuickActionRow: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                Text(action.title)
                    .font(.body)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
        .opacity(action.isEnabled ? 1.0 : 0.5)
        
        Divider()
    }
}

struct ConfigurationFieldView: View {
    let field: ConfigurationField
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(field.displayName)
                .font(.headline)
            
            switch field {
            case .textField(_, let defaultValue):
                TextField("Enter \(field.displayName)", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        if value.isEmpty {
                            value = defaultValue
                        }
                    }
                
            case .numberField(_, let defaultValue, _):
                TextField("Enter \(field.displayName)", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        if value.isEmpty {
                            value = String(defaultValue)
                        }
                    }
                
            case .toggle(_, let defaultValue):
                Toggle(field.displayName, isOn: Binding(
                    get: { value == "true" },
                    set: { value = $0 ? "true" : "false" }
                ))
                .onAppear {
                    if value.isEmpty {
                        value = String(defaultValue)
                    }
                }
                
            default:
                Text("Configuration type not yet implemented")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

// MARK: - SwiftUI Views

struct QuickConfigurationView: View {
    @Binding var widget: WidgetConfiguration?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var configuration: [String: String] = [:]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Configuration fields
            configurationFieldsView
            
            Spacer()
            
            // Action buttons
            actionButtonsView
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            loadConfiguration()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            if let widget = widget {
                HStack {
                    if let icon = widget.descriptor.systemIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(widget.descriptor.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(widget.descriptor.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var configurationFieldsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let widget = widget {
                    ForEach(Array(widget.descriptor.configurationSchema.fields), id: \.displayName) { field in
                        ConfigurationFieldView(
                            field: field,
                            value: binding(for: field.displayName)
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var actionButtonsView: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            .keyboardShortcut(.escape)
            
            Spacer()
            
            Button("Save Configuration") {
                saveConfiguration()
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
    }
    
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { configuration[key] ?? "" },
            set: { configuration[key] = $0 }
        )
    }
    
    private func loadConfiguration() {
        guard let widget = widget else { return }
        
        // Convert AnyCodable to String for editing
        for (key, value) in widget.configuration {
            configuration[key] = String(describing: value.value)
        }
    }
    
    private func saveConfiguration() {
        guard let widget = widget else { return }
        
        // Convert String back to AnyCodable
        for (key, value) in configuration {
            widget.configuration[key] = AnyCodable(value)
        }
    }
}

struct QuickActionsView: View {
    let actions: [QuickAction]
    let onActionSelected: (QuickAction) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            // Actions list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(actions) { action in
                        QuickActionRow(
                            action: action,
                            onTap: { onActionSelected(action) }
                        )
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}

struct QuickActionRow: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                Text(action.title)
                    .font(.body)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
        .opacity(action.isEnabled ? 1.0 : 0.5)
        
        Divider()
    }
}

struct ConfigurationFieldView: View {
    let field: ConfigurationField
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(field.displayName)
                .font(.headline)
            
            switch field {
            case .textField(_, let defaultValue):
                TextField("Enter \(field.displayName)", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        if value.isEmpty {
                            value = defaultValue
                        }
                    }
                
            case .numberField(_, let defaultValue, _):
                TextField("Enter \(field.displayName)", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        if value.isEmpty {
                            value = String(defaultValue)
                        }
                    }
                
            case .toggle(_, let defaultValue):
                Toggle(field.displayName, isOn: Binding(
                    get: { value == "true" },
                    set: { value = $0 ? "true" : "false" }
                ))
                .onAppear {
                    if value.isEmpty {
                        value = String(defaultValue)
                    }
                }
                
            default:
                Text("Configuration type not yet implemented")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

// MARK: - Move Widget Dialog

class MoveWidgetDialog: NSObject {
    private let widget: WidgetConfiguration
    private var dialog: NSAlert?
    
    init(widget: WidgetConfiguration) {
        self.widget = widget
        super.init()
    }
    
    func show() {
        let alert = NSAlert()
        alert.messageText = "Move Widget"
        alert.informativeText = "Select the new position for '\(widget.descriptor.name)'"
        
        // Add position selection
        let positionField = NSTextField()
        positionField.stringValue = String(widget.position)
        positionField.placeholderString = "Enter position (0-\(ConfigurationManager.shared.currentConfiguration?.widgets.count ?? 0))"
        
        alert.accessoryView = positionField
        alert.addButton(withTitle: "Move")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            moveWidget(to: Int(positionField.stringValue) ?? widget.position)
        }
        
        self.dialog = alert
    }
    
    private func moveWidget(to newPosition: Int) {
        guard let config = ConfigurationManager.shared.currentConfiguration,
              let currentIndex = config.widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        
        let widget = config.widgets.remove(at: currentIndex)
        var movedWidget = widget
        movedWidget.position = max(0, min(newPosition, config.widgets.count))
        
        config.widgets.insert(movedWidget, at: movedWidget.position)
        
        // Save and reload
        do {
            try ConfigurationManager.shared.saveConfiguration(config)
            TouchBarController.shared.reloadPreset(path: nil)
        } catch {
            print("MTMR: Failed to move widget: \(error)")
        }
    }
}

// MARK: - Extensions

extension ConfigurationSchema {
    var fields: [ConfigurationField] {
        switch self {
        case .simple(let fields):
            return fields
        case .advanced(let fields):
            return fields
        case .group(let fields):
            return fields
        }
    }
}
