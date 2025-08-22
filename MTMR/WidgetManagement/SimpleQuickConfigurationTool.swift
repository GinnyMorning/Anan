//
//  SimpleQuickConfigurationTool.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Simple Quick Configuration Tool for widget management.
//

import Cocoa
import SwiftUI

// MARK: - Simple Quick Configuration Tool

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
    
    // MARK: - Public Methods
    
    func showTool() {
        isVisible = true
        
        if toolWindow == nil {
            createToolWindow()
        }
        
        toolWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Private Methods
    
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
        let alert = NSAlert()
        alert.messageText = "Duplicate Widget"
        alert.informativeText = "Widget duplication will be implemented in a future update.\n\nFor now, please use 'Edit Configuration' from the MTMR menu to duplicate widgets manually."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func moveWidget() {
        let alert = NSAlert()
        alert.messageText = "Move Widget"
        alert.informativeText = "Widget movement will be implemented in a future update.\n\nFor now, please use 'Edit Configuration' from the MTMR menu to move widgets manually."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func deleteWidget() {
        let alert = NSAlert()
        alert.messageText = "Delete Widget"
        alert.informativeText = "Widget deletion will be implemented in a future update.\n\nFor now, please use 'Edit Configuration' from the MTMR menu to delete widgets manually."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func resetWidget() {
        let alert = NSAlert()
        alert.messageText = "Reset Widget"
        alert.informativeText = "Widget reset will be implemented in a future update.\n\nFor now, please use 'Edit Configuration' from the MTMR menu to reset widgets manually."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func exportWidget() {
        let alert = NSAlert()
        alert.messageText = "Export Widget"
        alert.informativeText = "Widget export will be implemented in a future update.\n\nFor now, please use 'Edit Configuration' from the MTMR menu to export widgets manually."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func shareWidget() {
        let alert = NSAlert()
        alert.messageText = "Share Widget"
        alert.informativeText = "Widget sharing will be implemented in a future update.\n\nFor now, please use 'Edit Configuration' from the MTMR menu to share widgets manually."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Simple Widget Configuration

struct SimpleWidgetConfiguration: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let description: String
    var configuration: [String: String] = [:]
    var position: Int = 0
}

// MARK: - Simple Quick Action

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

// MARK: - SwiftUI Tool View

struct SimpleQuickConfigurationToolView: View {
    let quickActions: [SimpleQuickAction]
    let onAction: (SimpleQuickAction) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Actions grid
            actionsGridView
            
            Spacer()
            
            // Close button
            closeButton
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemSymbolName: "slider.horizontal.3")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.accentColor)
                
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

// MARK: - Action Card

struct ActionCard: View {
    let action: SimpleQuickAction
    let onAction: (SimpleQuickAction) -> Void
    
    var body: some View {
        Button(action: { onAction(action) }) {
            VStack(spacing: 12) {
                // Icon
                if let icon = NSImage(systemSymbolName: action.icon, accessibilityDescription: action.title) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.accentColor)
                }
                
                // Title
                Text(action.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                // Description
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
