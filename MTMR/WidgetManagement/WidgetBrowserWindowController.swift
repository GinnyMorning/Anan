//
//  WidgetBrowserWindowController.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Widget Browser for easy widget discovery and addition.
//

import Cocoa
import SwiftUI

@MainActor
final class WidgetBrowserWindowController: NSWindowController {
    
    // MARK: - Properties
    
    private var widgetBrowserView: WidgetBrowserView?
    private let widgetManager = WidgetManager.shared
    
    // MARK: - Initialization
    
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "MTMR Widget Browser"
        window.center()
        window.setFrameAutosaveName("WidgetBrowserWindow")
        
        // Create the SwiftUI view
        let widgetBrowserView = WidgetBrowserView(
            onWidgetSelected: { [weak self] widget in
                self?.addWidgetToConfiguration(widget)
            },
            onClose: { [weak self] in
                self?.close()
            }
        )
        
        // Wrap in NSHostingView
        let hostingView = NSHostingView(rootView: widgetBrowserView)
        window.contentView = hostingView
        
        self.window = window
        self.widgetBrowserView = widgetBrowserView
    }
    
    // MARK: - Public Methods
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Private Methods
    
    private func addWidgetToConfiguration(_ widget: WidgetDescriptor) {
        // Create a basic configuration for the widget
        let configuration = WidgetConfiguration(
            descriptor: widget,
            configuration: [:],
            position: widgetManager.currentConfiguration?.widgets.count ?? 0
        )
        
        // Add to current configuration
        if widgetManager.currentConfiguration == nil {
            widgetManager.currentConfiguration = TouchBarConfiguration()
        }
        
        widgetManager.currentConfiguration?.widgets.append(configuration)
        
        // Show success feedback
        showSuccessAlert(for: widget)
        
        // Reload TouchBar if needed
        TouchBarController.shared.reloadPreset(path: nil)
    }
    
    private func showSuccessAlert(for widget: WidgetDescriptor) {
        let alert = NSAlert()
        alert.messageText = "Widget Added Successfully!"
        alert.informativeText = "The '\(widget.name)' widget has been added to your TouchBar configuration.\n\nYou can now customize it using 'Edit Configuration' from the MTMR menu."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Edit Configuration")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Open configuration editor
            openConfigurationEditor()
        }
    }
    
    private func openConfigurationEditor() {
        // This will be implemented in Phase 3
        let alert = NSAlert()
        alert.messageText = "Configuration Editor"
        alert.informativeText = "The visual configuration editor will be available in Phase 3.\n\nFor now, please use 'Edit Configuration' from the MTMR menu to customize your widgets."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - SwiftUI Widget Browser View

struct WidgetBrowserView: View {
    let onWidgetSelected: (WidgetDescriptor) -> Void
    let onClose: () -> Void
    
    @StateObject private var widgetManager = WidgetManager.shared
    @State private var selectedCategory: WidgetCategory?
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Search and Filter
            searchAndFilterView
            
            // Content
            contentView
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Header View
    
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
    
    // MARK: - Search and Filter View
    
    private var searchAndFilterView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search widgets...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WidgetCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredWidgets) { widget in
                    WidgetCard(
                        widget: widget,
                        onAdd: {
                            onWidgetSelected(widget)
                        }
                    )
                }
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Computed Properties
    
    private var filteredWidgets: [WidgetDescriptor] {
        var widgets = widgetManager.availableWidgets
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            widgets = widgets.filter { $0.category == selectedCategory }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            widgets = widgets.filter { widget in
                widget.name.localizedCaseInsensitiveContains(searchText) ||
                widget.description.localizedCaseInsensitiveContains(searchText) ||
                widget.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return widgets
    }
}

// MARK: - Supporting Views

struct CategoryFilterButton: View {
    let category: WidgetCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct WidgetCard: View {
    let widget: WidgetDescriptor
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Widget icon and name
            HStack {
                if let icon = widget.systemIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(widget.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(widget.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Description
            Text(widget.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Configuration preview
            if case .advanced(let fields) = widget.configurationSchema {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configuration Options:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(Array(fields.prefix(3)), id: \.displayName) { field in
                        HStack {
                            Image(systemName: "gear")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(field.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if fields.count > 3 {
                        Text("+ \(fields.count - 3) more options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Add button
            Button("Add to TouchBar") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(height: 200)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct WidgetBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetBrowserView(
            onWidgetSelected: { _ in },
            onClose: {}
        )
    }
}
#endif
