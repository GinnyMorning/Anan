//
//  SimpleWidgetBrowser.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Simple Widget Browser for easy widget discovery.
//

import Cocoa
import SwiftUI

@MainActor
final class SimpleWidgetBrowser: ObservableObject {
    static let shared = SimpleWidgetBrowser()
    
    @Published var isVisible = false
    @Published var availableWidgets: [SimpleWidgetDescriptor] = []
    @Published var selectedCategory: SimpleWidgetCategory = .systemControls
    @Published var searchText = ""
    
    private var browserWindow: NSWindow?
    
    private init() {
        setupAvailableWidgets()
    }
    
    func showBrowser() {
        isVisible = true
        
        if browserWindow == nil {
            createBrowserWindow()
        }
        
        browserWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupAvailableWidgets() {
        availableWidgets = [
            SimpleWidgetDescriptor(name: "Escape Key", description: "Simple escape key button", category: .systemControls, icon: "escape", type: "escape"),
            SimpleWidgetDescriptor(name: "Volume Controls", description: "Volume slider and mute button", category: .systemControls, icon: "speaker.wave.3", type: "volume"),
            SimpleWidgetDescriptor(name: "Brightness Slider", description: "Display brightness control", category: .systemControls, icon: "sun.max", type: "brightness"),
            SimpleWidgetDescriptor(name: "Weather Widget", description: "Current weather information", category: .systemInfo, icon: "cloud.sun", type: "weather"),
            SimpleWidgetDescriptor(name: "CPU Monitor", description: "CPU usage indicator", category: .systemInfo, icon: "cpu", type: "cpu"),
            SimpleWidgetDescriptor(name: "Clock", description: "Current time display", category: .systemInfo, icon: "clock", type: "clock"),
            SimpleWidgetDescriptor(name: "Battery Status", description: "Battery level indicator", category: .systemInfo, icon: "battery.100", type: "battery"),
            SimpleWidgetDescriptor(name: "Network Status", description: "Network connection status", category: .systemInfo, icon: "network", type: "network")
        ]
    }
    
    private func createBrowserWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "MTMR Widget Browser"
        window.center()
        window.setFrameAutosaveName("SimpleWidgetBrowserWindow")
        
        let browserView = SimpleWidgetBrowserView(
            availableWidgets: availableWidgets,
            selectedCategory: Binding(get: { self.selectedCategory }, set: { self.selectedCategory = $0 }),
            searchText: Binding(get: { self.searchText }, set: { self.searchText = $0 }),
            onWidgetSelected: { [weak self] widget in
                self?.addWidgetToConfiguration(widget)
            },
            onClose: { [weak self] in
                self?.browserWindow?.close()
            }
        )
        
        let hostingView = NSHostingView(rootView: browserView)
        window.contentView = hostingView
        
        self.browserWindow = window
    }
    
    private func addWidgetToConfiguration(_ widget: SimpleWidgetDescriptor) {
        // Use the centralized preset manager
        let widgetDescriptor = WidgetDescriptor(
            name: widget.name,
            type: widget.type,
            width: 100,
            align: "left"
        )
        
        if CentralizedPresetManager.shared.addWidget(widgetDescriptor) {
            showSuccessAlert(widget: widget)
        } else {
            showErrorAlert(message: "Failed to add widget to configuration")
        }
    }
    
    private func showSuccessAlert(widget: SimpleWidgetDescriptor) {
        let alert = NSAlert()
        alert.messageText = "Widget Added Successfully!"
        alert.informativeText = "The '\(widget.name)' widget has been added to your TouchBar configuration.\n\nMTMR will automatically reload the configuration."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error Adding Widget"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

struct SimpleWidgetDescriptor: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: SimpleWidgetCategory
    let icon: String
    let type: String
}

enum SimpleWidgetCategory: String, CaseIterable {
    case systemControls = "System Controls"
    case systemInfo = "System Info"
    case productivity = "Productivity"
    case mediaApps = "Media & Apps"
    case custom = "Custom"
}

struct SimpleWidgetBrowserView: View {
    let availableWidgets: [SimpleWidgetDescriptor]
    @Binding var selectedCategory: SimpleWidgetCategory
    @Binding var searchText: String
    let onWidgetSelected: (SimpleWidgetDescriptor) -> Void
    let onClose: () -> Void
    
    var filteredWidgets: [SimpleWidgetDescriptor] {
        availableWidgets.filter { widget in
            let matchesCategory = selectedCategory == .custom || widget.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                widget.name.localizedCaseInsensitiveContains(searchText) ||
                widget.description.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchAndFilterView
            contentView
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Widget Browser")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Discover and add widgets to your TouchBar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Close") {
                onClose()
            }
            .keyboardShortcut(.escape)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var searchAndFilterView: some View {
        HStack(spacing: 16) {
            Picker("Category", selection: $selectedCategory) {
                ForEach(SimpleWidgetCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 150)
            
            HStack {
                TextField("Search widgets...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(width: 250)
            
            Spacer()
            
            Text("\(filteredWidgets.count) widgets available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredWidgets) { widget in
                    WidgetCard(widget: widget, onSelect: onWidgetSelected)
                }
            }
            .padding()
        }
    }
}

struct WidgetCard: View {
    let widget: SimpleWidgetDescriptor
    let onSelect: (SimpleWidgetDescriptor) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 48, height: 48)
                .cornerRadius(8)
            
            Text(widget.name)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(widget.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(widget.category.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Button("Add Widget") {
                onSelect(widget)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .frame(width: 200, height: 180)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}
