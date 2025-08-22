//
//  MenuManager.swift
//  MTMR
//
//  Simple menu manager for Phase 1 implementation
//

import Cocoa

@MainActor
final class MenuManager {
    static let shared = MenuManager()
    
    private init() {}
    
    func createEnhancedMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Widget Configuration Section
        let widgetSection = createWidgetConfigurationSection()
        menu.addItem(widgetSection)
        menu.addItem(NSMenuItem.separator())
        
        // Settings Section - using existing functionality
        let settingsSection = createSettingsSection()
        menu.addItem(settingsSection)
        menu.addItem(NSMenuItem.separator())
        
        // Help Section
        let helpSection = createHelpSection()
        menu.addItem(helpSection)
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit MTMR", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        if let quitIcon = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit") {
            quitItem.image = quitIcon
        }
        menu.addItem(quitItem)
        
        return menu
    }
    
    private func createWidgetConfigurationSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        // Preferences (opens JSON editor for now)
        let preferencesItem = NSMenuItem(
            title: "Edit Configuration...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        if let preferencesIcon = NSImage(systemSymbolName: "gear", accessibilityDescription: "Preferences") {
            preferencesItem.image = preferencesIcon
        }
        preferencesItem.target = self
        submenu.addItem(preferencesItem)
        
        // Open Preset
        let openPresetItem = NSMenuItem(
            title: "Open Preset...",
            action: #selector(openPreset),
            keyEquivalent: "o"
        )
        if let openIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: "Open") {
            openPresetItem.image = openIcon
        }
        openPresetItem.target = self
        submenu.addItem(openPresetItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        // Quick Add submenu
        let quickAddSubmenu = createQuickAddSubmenu()
        let quickAddItem = NSMenuItem(title: "Quick Add", action: nil, keyEquivalent: "")
        if let quickIcon = NSImage(systemSymbolName: "plus.circle", accessibilityDescription: "Quick Add") {
            quickAddItem.image = quickIcon
        }
        quickAddItem.submenu = quickAddSubmenu
        submenu.addItem(quickAddItem)
        
        // Main item
        let mainItem = NSMenuItem(title: "Widget Configuration", action: nil, keyEquivalent: "")
        if let configIcon = NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: "Configuration") {
            mainItem.image = configIcon
        }
        mainItem.submenu = submenu
        
        return mainItem
    }
    
    private func createQuickAddSubmenu() -> NSMenu {
        let submenu = NSMenu()
        
        // Common widgets with their configurations
        let commonWidgets = [
            ("Escape Key", "escape", "escape"),
            ("Volume Controls", "speaker.wave.3", "volume"),
            ("Brightness Slider", "sun.max", "brightness"),
            ("Weather Widget", "cloud.sun", "weather"),
            ("CPU Monitor", "cpu", "cpu"),
            ("Clock", "clock", "clock")
        ]
        
        for (name, icon, type) in commonWidgets {
            let item = NSMenuItem(title: name, action: #selector(addQuickWidget(_:)), keyEquivalent: "")
            if let itemIcon = NSImage(systemSymbolName: icon, accessibilityDescription: name) {
                item.image = itemIcon
            }
            item.target = self
            item.representedObject = type
            submenu.addItem(item)
        }
        
        return submenu
    }
    
    private func createSettingsSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        // General Settings
        let startAtLoginItem = NSMenuItem(
            title: "Start at Login",
            action: #selector(toggleStartAtLogin),
            keyEquivalent: ""
        )
        if let startIcon = NSImage(systemSymbolName: "power.circle", accessibilityDescription: "Start at Login") {
            startAtLoginItem.image = startIcon
        }
        startAtLoginItem.target = self
        startAtLoginItem.state = LaunchAtLoginController().launchAtLogin ? .on : .off
        submenu.addItem(startAtLoginItem)
        
        let hapticItem = NSMenuItem(
            title: "Haptic Feedback",
            action: #selector(toggleHapticFeedback),
            keyEquivalent: ""
        )
        if let hapticIcon = NSImage(systemSymbolName: "hand.tap", accessibilityDescription: "Haptic") {
            hapticItem.image = hapticIcon
        }
        hapticItem.target = self
        hapticItem.state = AppSettings.hapticFeedbackState ? .on : .off
        submenu.addItem(hapticItem)
        
        let controlStripItem = NSMenuItem(
            title: "Hide Control Strip",
            action: #selector(toggleControlStrip),
            keyEquivalent: ""
        )
        if let stripIcon = NSImage(systemSymbolName: "rectangle.3.offgrid", accessibilityDescription: "Control Strip") {
            controlStripItem.image = stripIcon
        }
        controlStripItem.target = self
        controlStripItem.state = AppSettings.showControlStripState ? .off : .on
        submenu.addItem(controlStripItem)
        
        let gesturesItem = NSMenuItem(
            title: "Volume/Brightness Gestures",
            action: #selector(toggleMultitouch),
            keyEquivalent: ""
        )
        if let gesturesIcon = NSImage(systemSymbolName: "hand.draw", accessibilityDescription: "Gestures") {
            gesturesItem.image = gesturesIcon
        }
        gesturesItem.target = self
        gesturesItem.state = AppSettings.multitouchGestures ? .on : .off
        submenu.addItem(gesturesItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        let blacklistItem = NSMenuItem(
            title: "Toggle Current App in Blacklist",
            action: #selector(toggleBlackListedApp),
            keyEquivalent: ""
        )
        if let blacklistIcon = NSImage(systemSymbolName: "app.badge.checkmark", accessibilityDescription: "Blacklist") {
            blacklistItem.image = blacklistIcon
        }
        blacklistItem.target = self
        submenu.addItem(blacklistItem)
        
        // Main item
        let mainItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        if let settingsIcon = NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings") {
            mainItem.image = settingsIcon
        }
        mainItem.submenu = submenu
        
        return mainItem
    }
    
    private func createHelpSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        let updateItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        if let updateIcon = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Updates") {
            updateItem.image = updateIcon
        }
        updateItem.target = self
        submenu.addItem(updateItem)
        
        let aboutItem = NSMenuItem(
            title: "About MTMR",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        if let aboutIcon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About") {
            aboutItem.image = aboutIcon
        }
        aboutItem.target = self
        submenu.addItem(aboutItem)
        
        // Main item
        let mainItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        if let helpIcon = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Help") {
            mainItem.image = helpIcon
        }
        mainItem.submenu = submenu
        
        return mainItem
    }
}

// MARK: - Menu Actions
extension MenuManager {
    
    @objc func openPreferences() {
        // Legacy functionality - open JSON file
        let task = Process()
        let appSupportDirectory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!.appending("/MTMR")
        let presetPath = appSupportDirectory.appending("/items.json")
        task.launchPath = "/usr/bin/open"
        task.arguments = [presetPath]
        task.launch()
        print("MTMR: Opening configuration file...")
    }
    
    @objc func openPreset() {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a items.json file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = true
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = ["json"]
        dialog.directoryURL = NSURL.fileURL(withPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!.appending("/MTMR"), isDirectory: true)

        if dialog.runModal() == .OK, let path = dialog.url?.path {
            TouchBarController.shared.reloadPreset(path: path)
        }
        print("MTMR: Opening preset dialog...")
    }
    
    @objc func addQuickWidget(_ sender: NSMenuItem) {
        guard let widgetType = sender.representedObject as? String else { return }
        print("MTMR: Adding quick widget: \(widgetType)")
        // TODO: Implement actual widget addition in Phase 2
        
        // For now, show an alert with next steps
        let alert = NSAlert()
        alert.messageText = "Quick Widget Addition"
        alert.informativeText = "Adding '\(sender.title)' widget.\n\nThis feature will be fully implemented in Phase 2. For now, please use 'Edit Configuration' to add widgets manually."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func toggleStartAtLogin() {
        LaunchAtLoginController().setLaunchAtLogin(
            !LaunchAtLoginController().launchAtLogin,
            for: NSURL.fileURL(withPath: Bundle.main.bundlePath)
        )
        updateMenuState()
    }
    
    @objc func toggleHapticFeedback() {
        AppSettings.hapticFeedbackState = !AppSettings.hapticFeedbackState
        updateMenuState()
    }
    
    @objc func toggleControlStrip() {
        AppSettings.showControlStripState = !AppSettings.showControlStripState
        TouchBarController.shared.resetControlStrip()
        updateMenuState()
    }
    
    @objc func toggleMultitouch() {
        AppSettings.multitouchGestures = !AppSettings.multitouchGestures
        TouchBarController.shared.basicView?.legacyGesturesEnabled = AppSettings.multitouchGestures
        updateMenuState()
    }
    
    @objc func toggleBlackListedApp() {
        if let appIdentifier = TouchBarController.shared.frontmostApplicationIdentifier {
            if let index = TouchBarController.shared.blacklistAppIdentifiers.firstIndex(of: appIdentifier) {
                TouchBarController.shared.blacklistAppIdentifiers.remove(at: index)
            } else {
                TouchBarController.shared.blacklistAppIdentifiers.append(appIdentifier)
            }
            
            AppSettings.blacklistedAppIds = TouchBarController.shared.blacklistAppIdentifiers
            TouchBarController.shared.updateActiveApp()
            updateMenuState()
        }
    }
    
    @objc func checkForUpdates() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.checkForUpdates(nil)
        }
    }
    
    @objc func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }
    
    func updateMenuState() {
        // Notify AppDelegate to recreate menu with updated state
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            DispatchQueue.main.async {
                appDelegate.createMenu()
            }
        }
    }
}
