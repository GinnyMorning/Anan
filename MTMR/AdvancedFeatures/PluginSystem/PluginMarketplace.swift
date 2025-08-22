//
//  PluginMarketplace.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 5B: Plugin System - Plugin Marketplace.
//

import Cocoa
import SwiftUI

// MARK: - Plugin Marketplace

@MainActor
final class PluginMarketplace: ObservableObject {
    static let shared = PluginMarketplace()
    
    @Published var isVisible = false
    @Published var selectedCategory: PluginCategory?
    @Published var searchQuery = ""
    @Published var sortOption: SortOption = .popularity
    
    private var marketplaceWindow: NSWindow?
    private let pluginManager = PluginManager.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    func showMarketplace() {
        isVisible = true
        
        if marketplaceWindow == nil {
            createMarketplaceWindow()
        }
        
        marketplaceWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Refresh available plugins
        Task {
            await pluginManager.refreshAvailablePlugins()
        }
    }
    
    // MARK: - Private Methods
    
    private func createMarketplaceWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "MTMR Plugin Marketplace"
        window.center()
        window.setFrameAutosaveName("PluginMarketplaceWindow")
        
        // Create SwiftUI view
        let marketplaceView = PluginMarketplaceView(
            selectedCategory: Binding(get: { self.selectedCategory }, set: { self.selectedCategory = $0 }),
            searchQuery: Binding(get: { self.searchQuery }, set: { self.searchQuery = $0 }),
            sortOption: Binding(get: { self.sortOption }, set: { self.sortOption = $0 }),
            onInstall: { [weak self] plugin in
                Task {
                    try await self?.pluginManager.installPlugin(plugin)
                }
            },
            onClose: { [weak self] in
                self?.closeMarketplaceWindow()
            }
        )
        
        let hostingView = NSHostingView(rootView: marketplaceView)
        window.contentView = hostingView
        
        self.marketplaceWindow = window
    }
    
    private func closeMarketplaceWindow() {
        marketplaceWindow?.close()
        marketplaceWindow = nil
        isVisible = false
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable {
    case popularity = "Popularity"
    case rating = "Rating"
    case newest = "Newest"
    case price = "Price"
    case downloads = "Downloads"
    
    var icon: String {
        switch self {
        case .popularity: return "flame"
        case .rating: return "star"
        case .newest: return "clock"
        case .price: return "dollarsign"
        case .downloads: return "arrow.down.circle"
        }
    }
}

// MARK: - SwiftUI Views

struct PluginMarketplaceView: View {
    @Binding var selectedCategory: PluginCategory?
    @Binding var searchQuery: String
    @Binding var sortOption: SortOption
    let onInstall: (Plugin) -> Void
    let onClose: () -> Void
    
    @StateObject private var pluginManager = PluginManager.shared
    @State private var showInstalledPlugins = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            marketplaceHeader
            
            Divider()
            
            // Content
            HSplitView {
                // Left Panel - Categories and Filters
                categoriesPanel
                    .frame(minWidth: 250, maxWidth: 300)
                
                // Right Panel - Plugin List
                pluginListPanel
                    .frame(minWidth: 600)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Installed") {
                    showInstalledPlugins = true
                }
                .keyboardShortcut("i")
                
                Button("Refresh") {
                    Task {
                        await pluginManager.refreshAvailablePlugins()
                    }
                }
                .keyboardShortcut("r")
                
                Divider()
                
                Button("Close") {
                    onClose()
                }
                .keyboardShortcut(.escape)
            }
        }
        .sheet(isPresented: $showInstalledPlugins) {
            InstalledPluginsSheet()
        }
    }
    
    private var marketplaceHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plugin Marketplace")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Discover and install amazing TouchBar widgets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(pluginManager.availablePlugins.count) Available")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    Text("\(pluginManager.installedPlugins.count) Installed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Search and Sort
            HStack(spacing: 16) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search plugins...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Sort
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                            }
                            .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding()
    }
    
    private var categoriesPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Categories")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Categories
            ScrollView {
                LazyVStack(spacing: 8) {
                    // All Categories
                    CategoryRow(
                        category: nil,
                        isSelected: selectedCategory == nil,
                        onTap: {
                            selectedCategory = nil
                        }
                    )
                    
                    // Individual Categories
                    ForEach(PluginCategory.allCases, id: \.self) { category in
                        CategoryRow(
                            category: category,
                            isSelected: selectedCategory == category,
                            onTap: {
                                selectedCategory = category
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var pluginListPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Available Plugins")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                if pluginManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // Plugin List
            if pluginManager.availablePlugins.isEmpty {
                emptyStateView
            } else {
                pluginListView
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "puzzlepiece")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No plugins found")
                .font(.headline)
            
            Text("Try adjusting your search or category filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var pluginListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredAndSortedPlugins) { plugin in
                    PluginCard(
                        plugin: plugin,
                        onInstall: {
                            onInstall(plugin)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var filteredAndSortedPlugins: [Plugin] {
        var plugins = pluginManager.availablePlugins
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            plugins = plugins.filter { $0.category == selectedCategory }
        }
        
        // Filter by search query
        if !searchQuery.isEmpty {
            plugins = plugins.filter { plugin in
                plugin.name.localizedCaseInsensitiveContains(searchQuery) ||
                plugin.description.localizedCaseInsensitiveContains(searchQuery) ||
                plugin.author.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Sort plugins
        switch sortOption {
        case .popularity:
            plugins.sort { $0.downloadCount > $1.downloadCount }
        case .rating:
            plugins.sort { $0.rating > $1.rating }
        case .newest:
            plugins.sort { $0.version > $1.version }
        case .price:
            plugins.sort { $0.price < $1.price }
        case .downloads:
            plugins.sort { $0.downloadCount > $1.downloadCount }
        }
        
        return plugins
    }
}

struct CategoryRow: View {
    let category: PluginCategory?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let category = category {
                    Image(systemName: category.icon)
                        .foregroundColor(Color(hex: category.color))
                        .font(.title3)
                } else {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
                
                Text(category?.rawValue ?? "All Categories")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                }
            }
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PluginCard: View {
    let plugin: Plugin
    let onInstall: () -> Void
    
    @State private var isInstalling = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Plugin Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: plugin.category.color).opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: plugin.category.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: plugin.category.color))
                }
                
                // Plugin Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plugin.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(plugin.formattedPrice)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(plugin.price == 0.0 ? .green : .primary)
                    }
                    
                    Text(plugin.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(plugin.formattedRating)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(plugin.formattedDownloads)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(plugin.author)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                // Category Badge
                HStack(spacing: 4) {
                    Image(systemName: plugin.category.icon)
                        .font(.caption)
                    Text(plugin.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: plugin.category.color).opacity(0.1))
                .foregroundColor(Color(hex: plugin.category.color))
                .cornerRadius(4)
                
                Spacer()
                
                // Version
                Text("v\(plugin.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Install Button
                Button(action: {
                    isInstalling = true
                    onInstall()
                }) {
                    HStack(spacing: 4) {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle")
                        }
                        Text(isInstalling ? "Installing..." : "Install")
                                    }
                .font(.subheadline)
            }
                .buttonStyle(.bordered)
                .disabled(isInstalling)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct InstalledPluginsSheet: View {
    @State private var isPresented = true
    @StateObject private var pluginManager = PluginManager.shared
    
    var body: some View {
        VStack {
            Text("Installed Plugins")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            if pluginManager.installedPlugins.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "puzzlepiece")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No plugins installed")
                        .font(.headline)
                    
                    Text("Install plugins from the marketplace to see them here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(pluginManager.installedPlugins) { plugin in
                            InstalledPluginRow(plugin: plugin)
                        }
                    }
                    .padding()
                }
            }
            
            Button("Close") {
                isPresented = false
            }
            .keyboardShortcut(.escape)
            .padding()
        }
        .frame(width: 600, height: 400)
    }
}

struct InstalledPluginRow: View {
    let plugin: Plugin
    @StateObject private var pluginManager = PluginManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Plugin Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: plugin.category.color).opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: plugin.category.icon)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: plugin.category.color))
            }
            
            // Plugin Info
            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("v\(plugin.version) • \(plugin.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(plugin.isEnabled ? "Disable" : "Enable") {
                    if plugin.isEnabled {
                        pluginManager.disablePlugin(plugin)
                    } else {
                        pluginManager.enablePlugin(plugin)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Uninstall") {
                    do {
                        try pluginManager.uninstallPlugin(plugin)
                    } catch {
                        print("MTMR: Error uninstalling plugin: \(error)")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
