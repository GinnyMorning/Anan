//
//  ConcurrentTouchBarController.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  MainActor-isolated TouchBar controller for thread safety
//

import Cocoa

/// Thread-safe TouchBar controller using MainActor isolation
@MainActor
class ConcurrentTouchBarController: NSObject, NSTouchBarDelegate {
    static let shared = ConcurrentTouchBarController()
    
    var touchBar: NSTouchBar!
    
    private var lastPresetPath = ""
    private var jsonItems: [BarItemDefinition] = []
    private var itemDefinitions: [NSTouchBarItem.Identifier: BarItemDefinition] = [:]
    private var items: [NSTouchBarItem.Identifier: NSTouchBarItem] = [:]
    private var leftIdentifiers: [NSTouchBarItem.Identifier] = []
    private var centerIdentifiers: [NSTouchBarItem.Identifier] = []
    private var rightIdentifiers: [NSTouchBarItem.Identifier] = []
    private var basicViewIdentifier = NSTouchBarItem.Identifier("com.toxblh.mtmr.scrollView.".appending(UUID().uuidString))
    private var basicView: BasicView?
    private var swipeItems: [SwipeItem] = []
    
    private var blacklistAppIdentifiers: [String] = []
    
    // Thread-safe access to frontmost application
    nonisolated var frontmostApplicationIdentifier: String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
    
    private override init() {
        super.init()
        setupTouchBar()
    }
    
    // MARK: - TouchBar Setup
    
    private func setupTouchBar() {
        touchBar = NSTouchBar()
        touchBar.delegate = self
        // Note: customizationIdentifier is deprecated in newer macOS versions
        // We'll handle this in a compatibility-aware way
        if #available(macOS 10.13, *) {
            touchBar.defaultItemIdentifiers = []
        }
    }
    
    func setupControlStripPresence() {
        if #available(macOS 10.14, *) {
            DFRSystemModalShowsCloseBoxWhenFrontMost(false)
        }
        
        let item = NSCustomTouchBarItem(identifier: .controlStripItem)
        // Use a system image for now - StatusImage will be added during migration
        let button = NSButton()
        button.image = NSImage(named: NSImage.touchBarViewOnTemplateName)
        button.target = self
        button.action = #selector(controlStripTapped)
        item.view = button
        NSTouchBar.presentSystemModalTouchBar(touchBar, placement: .controlStrip, systemTrayItemIdentifier: .controlStripItem)
    }
    
    @objc private func controlStripTapped() {
        presentTouchBar()
    }
    
    private func presentTouchBar() {
        NSTouchBar.presentSystemModalTouchBar(touchBar, systemTrayItemIdentifier: .controlStripItem)
    }
    
    // MARK: - Configuration Management
    
    func reloadItems() async {
        await loadConfiguration()
        updateTouchBarItems()
    }
    
    private func loadConfiguration() async {
        // Load configuration from file
        let configPath = standardConfigPath
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            print("Configuration file not found at: \(configPath)")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let decoder = JSONDecoder()
            jsonItems = try decoder.decode([BarItemDefinition].self, from: data)
            lastPresetPath = configPath
        } catch {
            print("Error loading configuration: \(error)")
        }
    }
    
    private func updateTouchBarItems() {
        // Clear existing items
        items.removeAll()
        itemDefinitions.removeAll()
        leftIdentifiers.removeAll()
        centerIdentifiers.removeAll()
        rightIdentifiers.removeAll()
        
        // Process new items
        for item in jsonItems {
            let identifier = createIdentifier(for: item)
            itemDefinitions[identifier] = item
            
            // Categorize by alignment
            switch item.align {
            case .left:
                leftIdentifiers.append(identifier)
            case .center:
                centerIdentifiers.append(identifier)
            case .right:
                rightIdentifiers.append(identifier)
            }
        }
        
        // Update TouchBar
        updateTouchBarLayout()
    }
    
    private func updateTouchBarLayout() {
        var allIdentifiers: [NSTouchBarItem.Identifier] = []
        allIdentifiers.append(contentsOf: leftIdentifiers)
        allIdentifiers.append(contentsOf: centerIdentifiers)
        allIdentifiers.append(contentsOf: rightIdentifiers)
        
        touchBar.defaultItemIdentifiers = allIdentifiers
        touchBar.customizationAllowedItemIdentifiers = allIdentifiers
    }
    
    private func createIdentifier(for item: BarItemDefinition) -> NSTouchBarItem.Identifier {
        let baseId = item.type.identifierBase
        return NSTouchBarItem.Identifier(baseId.appending(UUID().uuidString))
    }
    
    // MARK: - NSTouchBarDelegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard let itemDefinition = itemDefinitions[identifier] else { return nil }
        
        // Create appropriate touch bar item based on type
        let item = createTouchBarItem(for: itemDefinition, with: identifier)
        items[identifier] = item
        
        return item
    }
    
    private func createTouchBarItem(for definition: BarItemDefinition, with identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        // This would contain the logic to create specific touch bar items
        // For now, return a basic button as placeholder
        let item = NSCustomTouchBarItem(identifier: identifier)
        item.view = NSButton(title: "Item", target: nil, action: nil)
        return item
    }
    
    // MARK: - App State Management
    
    func updateBlacklistStatus() async {
        guard let frontmostAppId = frontmostApplicationIdentifier else { return }
        
        // Use concurrent settings access
        let blacklistedApps = await ConcurrentAppSettings.blacklistedAppIds
        let isBlocked = blacklistedApps.contains(frontmostAppId)
        
        if isBlocked {
            hideTouchBar()
        } else {
            showTouchBar()
        }
    }
    
    private func hideTouchBar() {
        // Hide touch bar for blacklisted apps
        touchBar.defaultItemIdentifiers = []
    }
    
    private func showTouchBar() {
        // Show touch bar for allowed apps
        updateTouchBarLayout()
    }
    
    // MARK: - Migration Helper
    
    func migrateFromLegacyController() async {
        // This will be called during migration to preserve existing state
        // Implementation would copy over configuration and state from TouchBarController
        print("Migrating TouchBar state from legacy controller")
        
        // Load existing configuration
        await loadConfiguration()
    }
}

// MARK: - Extensions

extension NSTouchBarItem.Identifier {
    static let controlStripItem = NSTouchBarItem.Identifier("com.toxblh.mtmr.controlStrip")
}
