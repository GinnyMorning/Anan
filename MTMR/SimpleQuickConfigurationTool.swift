//
//  SimpleQuickConfigurationTool.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Simple Quick Configuration Tool for widget management.
//

import Cocoa
import SwiftUI

@MainActor
final class SimpleQuickConfigurationTool: ObservableObject {
    static let shared = SimpleQuickConfigurationTool()
    
    @Published var isVisible = false
    @Published var currentWidget: SimpleWidgetConfiguration?
    @Published var quickActions: [SimpleQuickAction] = []
    
    private var toolWindow: NSWindow?
    
    private init() {
        setupQuickActions()
    }
    
    func showTool() {
        isVisible = true
        
        if toolWindow == nil {
            createToolWindow()
        }
        
        toolWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupQuickActions() {
        quickActions = [
            SimpleQuickAction(id: "duplicate", title: "Duplicate Widget", icon: "plus.square.on.square", action: duplicateWidget),
            SimpleQuickAction(id: "move", title: "Move Widget", icon: "arrow.up.arrow.down", action: moveWidget),
            SimpleQuickAction(id: "delete", title: "Delete Widget", icon: "trash", action: deleteWidget),
            SimpleQuickAction(id: "reset", title: "Reset to Default", icon: "arrow.clockwise", action: resetWidget),
            SimpleQuickAction(id: "export", title: "Export Configuration", icon: "square.and.arrow.up", action: exportWidget),
            SimpleQuickAction(id: "share", title: "Share Widget", icon: "square.and.arrow.up", action: shareWidget)
        ]
    }
    
    private func createToolWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Quick Configuration Tools"
        window.center()
        window.setFrameAutosaveName("SimpleQuickConfigurationToolWindow")
        
        let toolView = SimpleQuickConfigurationToolView(
            quickActions: quickActions,
            onAction: { [weak self] action in
                self?.executeAction(action)
            },
            onClose: { [weak self] in
                self?.toolWindow?.close()
            }
        )
        
        let hostingView = NSHostingView(rootView: toolView)
        window.contentView = hostingView
        
        self.toolWindow = window
    }
    
    private func executeAction(_ action: SimpleQuickAction) {
        switch action.id {
        case "duplicate":
            duplicateWidget()
        case "move":
            moveWidget()
        case "delete":
            deleteWidget()
        case "reset":
            resetWidget()
        case "export":
            exportWidget()
        case "share":
            shareWidget()
        default:
            break
        }
    }
    
    private func duplicateWidget() {
        if CentralizedPresetManager.shared.duplicateLastWidget() {
            showSuccessAlert(action: "duplicated")
        } else {
            showErrorAlert(message: "No widgets found to duplicate")
        }
    }
    
    private func moveWidget() {
        let alert = NSAlert()
        alert.messageText = "Move Widget"
        alert.informativeText = "Widget movement requires selecting a specific widget. Please use 'Edit Configuration' for precise widget positioning."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func deleteWidget() {
        if CentralizedPresetManager.shared.removeLastWidget() {
            showSuccessAlert(action: "deleted")
        } else {
            showErrorAlert(message: "No widgets found to delete")
        }
    }
    
    private func resetWidget() {
        let alert = NSAlert()
        alert.messageText = "Reset Widget"
        alert.informativeText = "Widget reset requires selecting a specific widget. Please use 'Edit Configuration' to reset individual widget settings."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func exportWidget() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "mtmr-configuration.json"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if CentralizedPresetManager.shared.exportCurrentConfiguration(to: url) {
                    DispatchQueue.main.async {
                        self.showSuccessAlert(action: "exported")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: "Failed to export configuration")
                    }
                }
            }
        }
    }
    
    private func shareWidget() {
        let alert = NSAlert()
        alert.messageText = "Share Widget"
        alert.informativeText = "Widget sharing requires selecting a specific widget. Please use 'Edit Configuration' to copy widget configurations."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showSuccessAlert(action: String) {
        let alert = NSAlert()
        alert.messageText = "Action Completed Successfully!"
        alert.informativeText = "Widget has been \(action). MTMR will automatically reload the configuration."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

struct SimpleWidgetConfiguration: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let description: String
    var configuration: [String: String] = [:]
    var position: Int = 0
}

class SimpleQuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    init(id: String, title: String, icon: String, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.icon = icon
        self.action = action
    }
}

struct SimpleQuickConfigurationToolView: View {
    let quickActions: [SimpleQuickAction]
    let onAction: (SimpleQuickAction) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            actionsGridView
            Spacer()
            closeButton
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .cornerRadius(4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Configuration Tools")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Powerful shortcuts for widget management")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("These tools provide quick access to common widget operations. Select an action to get started.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var actionsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
        ], spacing: 16) {
            ForEach(quickActions) { action in
                ActionCard(action: action, onAction: onAction)
            }
        }
    }
    
    private var closeButton: some View {
        HStack {
            Spacer()
            
            Button("Close") {
                onClose()
            }
            .keyboardShortcut(.escape)
        }
    }
}

struct ActionCard: View {
    let action: SimpleQuickAction
    let onAction: (SimpleQuickAction) -> Void
    
    var body: some View {
        Button(action: { onAction(action) }) {
            VStack(spacing: 12) {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .cornerRadius(4)
                
                Text(action.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(actionDescription(for: action.id))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding()
            .frame(width: 150, height: 120)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!action.isEnabled)
    }
    
    private func actionDescription(for actionId: String) -> String {
        switch actionId {
        case "duplicate":
            return "Create a copy of the selected widget"
        case "move":
            return "Change the position of the widget"
        case "delete":
            return "Remove the widget from configuration"
        case "reset":
            return "Restore widget to default settings"
        case "export":
            return "Export widget configuration to file"
        case "share":
            return "Share widget with other users"
        default:
            return "Quick action for widget management"
        }
    }
}
