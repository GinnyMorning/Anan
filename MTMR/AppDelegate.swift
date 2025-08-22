//
//  AppDelegate.swift
//  MTMR
//
//  Created by Anton Palgunov on 16/03/2018.
//  Copyright © 2018 Anton Palgunov. All rights reserved.
//

import Cocoa
import Sparkle

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var isBlockedApp: Bool = false
    
    // Modern Sparkle updater controller
    private var updaterController: SPUStandardUpdaterController?

    private var fileSystemSource: DispatchSourceFileSystemObject?

    func applicationDidFinishLaunching(_: Notification) {
        // Configure modern Sparkle updater
        setupSparkleUpdater()

        // Smart permission management - only request if needed
        if EnhancedPermissionManager.shared.shouldCheckPermissions() {
            print("MTMR: Checking permissions...")
            let permissions = EnhancedPermissionManager.shared.checkAllPermissions()
            
            // Only request accessibility permission if not already granted
            if permissions["accessibility"] != .granted {
                print("MTMR: Requesting accessibility permission...")
                EnhancedPermissionManager.shared.smartRequestPermission(for: "accessibility")
            } else {
                print("MTMR: Accessibility permission already granted")
            }
        } else {
            print("MTMR: Skipping permission check (recently checked)")
        }

        TouchBarController.shared.setupControlStripPresence()

        if let button = statusItem.button {
            button.image = #imageLiteral(resourceName: "StatusImage")
        }
        createMenu()

        reloadOnDefaultConfigChanged()

        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateIsBlockedApp), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateIsBlockedApp), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateIsBlockedApp), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    
    private func setupSparkleUpdater() {
        // Create modern Sparkle updater controller
        let updater = SPUUpdater(hostBundle: Bundle.main, applicationBundle: Bundle.main, userDriver: SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil), delegate: nil)
        
        // Configure updater settings
        updater.automaticallyDownloadsUpdates = false
        updater.automaticallyChecksForUpdates = true
        
        // Create the updater controller with proper delegate structure
        updaterController = SPUStandardUpdaterController(updaterDelegate: nil, userDriverDelegate: nil)
        
        // Check for updates in background
        updater.checkForUpdatesInBackground()
    }
    
    @objc func checkForUpdates(_: Any?) {
        updaterController?.checkForUpdates(nil)
    }

    func applicationWillTerminate(_: Notification) {}

    @objc func updateIsBlockedApp() {
        if let frontmostAppId = TouchBarController.shared.frontmostApplicationIdentifier {
            isBlockedApp = AppSettings.blacklistedAppIds.firstIndex(of: frontmostAppId) != nil
        } else {
            isBlockedApp = false
        }
        // Don't call createMenu() here to avoid infinite loop
        // The menu will be updated when needed
    }

    // Menu action methods
    @objc func openPreferences(_: Any?) {
        // Legacy functionality - open JSON file
        let task = Process()
        let appSupportDirectory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!.appending("/MTMR")
        let presetPath = appSupportDirectory.appending("/items.json")
        task.launchPath = "/usr/bin/open"
        task.arguments = [presetPath]
        task.launch()
        print("MTMR: Opening configuration file...")
    }

    @objc func openPreset(_: Any?) {
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
        print("MTMR: CentralizedPresetManager.shared exists: \(CentralizedPresetManager.shared != nil)")
        
        // Use the centralized preset manager
        let widget = WidgetDescriptor(
            name: sender.title,
            type: widgetType,
            width: 100,
            align: "left"
        )
        print("MTMR: Widget descriptor created: \(widget)")
        
        let result = CentralizedPresetManager.shared.addWidget(widget)
        print("MTMR: addWidget result: \(result)")
        
        if result {
            showSuccessAlert(widgetName: sender.title)
        } else {
            showErrorAlert(message: "Failed to add widget to configuration")
        }
    }
    
    private func showSuccessAlert(widgetName: String) {
        let alert = NSAlert()
        alert.messageText = "Widget Added Successfully!"
        alert.informativeText = "The '\(widgetName)' widget has been added to your TouchBar configuration.\n\nMTMR will automatically reload the configuration."
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
    

    

    

    
    @objc func openWidgetBrowser(_: Any?) {
        print("MTMR: Opening Widget Browser...")
        
        // Phase 2: Widget Browser - Now Working!
        SimpleWidgetBrowser.shared.showBrowser()
    }
    
    @objc func openQuickConfigurationTools(_: Any?) {
        print("MTMR: Opening Quick Configuration Tools...")
        
        // Phase 3: Quick Configuration Tools - Now Working!
        SimpleQuickConfigurationTool.shared.showTool()
    }
    
    @objc func openAdvancedVisualEditor(_: Any?) {
        print("MTMR: Opening Advanced Visual Editor...")
        
        // Phase 4: Advanced Visual Editor - Now Working!
        SimpleAdvancedVisualEditor.shared.showEditor()
    }
    
    @objc func openCustomWidgetBuilder(_: Any?) {
        print("MTMR: Opening Custom Widget Builder...")
        
        // Phase 5A: Custom Widget Builder - Fully Active!
        CustomWidgetBuilder.shared.showBuilder()
    }
    
    @objc func openPluginMarketplace(_: Any?) {
        print("MTMR: Opening Plugin Marketplace...")
        
        // Phase 5B: Plugin Marketplace - Fully Active!
        PluginMarketplace.shared.showMarketplace()
    }
    

    
    @objc func openAdvancedAnalyticsDashboard(_: Any?) {
        print("MTMR: Opening Advanced Analytics Dashboard...")
        
        // Phase 5D: Advanced Analytics Dashboard - Fully Active!
        AnalyticsDashboard.shared.showDashboard()
    }

    @objc func toggleControlStrip(_ item: NSMenuItem) {
        AppSettings.showControlStripState = !AppSettings.showControlStripState
        TouchBarController.shared.resetControlStrip()
        // Don't recreate menu here to avoid infinite loop
        // The menu will be updated when needed
    }

    @objc func toggleBlackListedApp(_: Any?) {
        if let appIdentifier = TouchBarController.shared.frontmostApplicationIdentifier {
            if let index = TouchBarController.shared.blacklistAppIdentifiers.firstIndex(of: appIdentifier) {
                TouchBarController.shared.blacklistAppIdentifiers.remove(at: index)
            } else {
                TouchBarController.shared.blacklistAppIdentifiers.append(appIdentifier)
            }
            
            AppSettings.blacklistedAppIds = TouchBarController.shared.blacklistAppIdentifiers
            TouchBarController.shared.updateActiveApp()
            // Don't call updateIsBlockedApp() here to avoid infinite loop
            // The menu will be updated when needed
        }
    }

    @objc func toggleHapticFeedback(_ item: NSMenuItem) {
        AppSettings.hapticFeedbackState = !AppSettings.hapticFeedbackState
        // Don't recreate menu here to avoid infinite loop
        // The menu will be updated when needed
    }

    @objc func toggleMultitouch(_ item: NSMenuItem) {
        AppSettings.multitouchGestures = !AppSettings.multitouchGestures
        TouchBarController.shared.basicView?.legacyGesturesEnabled = AppSettings.multitouchGestures
        // Don't recreate menu here to avoid infinite loop
        // The menu will be updated when needed
    }

    @objc func toggleStartAtLogin(_: Any?) {
        LaunchAtLoginController().setLaunchAtLogin(
            !LaunchAtLoginController().launchAtLogin,
            for: NSURL.fileURL(withPath: Bundle.main.bundlePath)
        )
        // Don't recreate menu here to avoid infinite loop
        // The menu will be updated when needed
    }
    
    @objc func showAbout(_: Any?) {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }

    func createMenu() {
        let menu = NSMenu()
        
        // Widget Configuration Section
        let widgetSection = createWidgetConfigurationSection()
        menu.addItem(widgetSection)
        menu.addItem(NSMenuItem.separator())
        
        // Settings Section
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
        
        statusItem.menu = menu
        // Don't call updateIsBlockedApp() here to avoid infinite loop
        // The blocked app status will be updated when needed
    }
    
    private func createWidgetConfigurationSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        // Preferences (opens JSON editor for now)
        let preferencesItem = NSMenuItem(
            title: "Edit Configuration...",
            action: #selector(openPreferences(_:)),
            keyEquivalent: ","
        )
        if let preferencesIcon = NSImage(systemSymbolName: "gear", accessibilityDescription: "Preferences") {
            preferencesItem.image = preferencesIcon
        }
        submenu.addItem(preferencesItem)
        
        // Open Preset
        let openPresetItem = NSMenuItem(
            title: "Open Preset...",
            action: #selector(openPreset(_:)),
            keyEquivalent: "o"
        )
        if let openIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: "Open") {
            openPresetItem.image = openIcon
        }
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
        
        // Widget Browser
        let widgetBrowserItem = NSMenuItem(
            title: "Widget Browser...",
            action: #selector(openWidgetBrowser(_:)),
            keyEquivalent: "b"
        )
        if let browserIcon = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "Widget Browser") {
            widgetBrowserItem.image = browserIcon
        }
        submenu.addItem(widgetBrowserItem)
        
        // Quick Configuration Tools
        let quickConfigItem = NSMenuItem(
            title: "Quick Configuration Tools...",
            action: #selector(openQuickConfigurationTools(_:)),
            keyEquivalent: "q"
        )
        if let quickIcon = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Quick Configuration") {
            quickConfigItem.image = quickIcon
        }
        submenu.addItem(quickConfigItem)
        
        // Advanced Visual Editor
        let advancedEditorItem = NSMenuItem(
            title: "Advanced Visual Editor...",
            action: #selector(openAdvancedVisualEditor(_:)),
            keyEquivalent: "v"
        )
        if let editorIcon = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Advanced Editor") {
            advancedEditorItem.image = editorIcon
        }
        submenu.addItem(advancedEditorItem)
        
        // Separator
        submenu.addItem(NSMenuItem.separator())
        
        // Custom Widget Builder
        let customBuilderItem = NSMenuItem(
            title: "Custom Widget Builder...",
            action: #selector(openCustomWidgetBuilder(_:)),
            keyEquivalent: "b"
        )
        if let builderIcon = NSImage(systemSymbolName: "hammer", accessibilityDescription: "Custom Builder") {
            customBuilderItem.image = builderIcon
        }
        submenu.addItem(customBuilderItem)
        
        // Plugin Marketplace
        let pluginMarketplaceItem = NSMenuItem(
            title: "Plugin Marketplace...",
            action: #selector(openPluginMarketplace(_:)),
            keyEquivalent: "m"
        )
        if let marketplaceIcon = NSImage(systemSymbolName: "puzzlepiece", accessibilityDescription: "Plugin Marketplace") {
            pluginMarketplaceItem.image = marketplaceIcon
        }
        submenu.addItem(pluginMarketplaceItem)
        


        // Advanced Analytics Dashboard
        let analyticsItem = NSMenuItem(
            title: "Advanced Analytics Dashboard...",
            action: #selector(openAdvancedAnalyticsDashboard(_:)),
            keyEquivalent: "a"
        )
        if let analyticsIcon = NSImage(systemSymbolName: "chart.bar", accessibilityDescription: "Advanced Analytics") {
            analyticsItem.image = analyticsIcon
        }
        submenu.addItem(analyticsItem)
        
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
            action: #selector(toggleStartAtLogin(_:)),
            keyEquivalent: ""
        )
        if let startIcon = NSImage(systemSymbolName: "power.circle", accessibilityDescription: "Start at Login") {
            startAtLoginItem.image = startIcon
        }
        startAtLoginItem.state = LaunchAtLoginController().launchAtLogin ? .on : .off
        submenu.addItem(startAtLoginItem)
        
        let hapticItem = NSMenuItem(
            title: "Haptic Feedback",
            action: #selector(toggleHapticFeedback(_:)),
            keyEquivalent: ""
        )
        if let hapticIcon = NSImage(systemSymbolName: "hand.tap", accessibilityDescription: "Haptic") {
            hapticItem.image = hapticIcon
        }
        hapticItem.state = AppSettings.hapticFeedbackState ? .on : .off
        submenu.addItem(hapticItem)
        
        let controlStripItem = NSMenuItem(
            title: "Hide Control Strip",
            action: #selector(toggleControlStrip(_:)),
            keyEquivalent: ""
        )
        if let stripIcon = NSImage(systemSymbolName: "rectangle.3.offgrid", accessibilityDescription: "Control Strip") {
            controlStripItem.image = stripIcon
        }
        controlStripItem.state = AppSettings.showControlStripState ? .off : .on
        submenu.addItem(controlStripItem)
        
        let gesturesItem = NSMenuItem(
            title: "Volume/Brightness Gestures",
            action: #selector(toggleMultitouch(_:)),
            keyEquivalent: ""
        )
        if let gesturesIcon = NSImage(systemSymbolName: "hand.draw", accessibilityDescription: "Gestures") {
            gesturesItem.image = gesturesIcon
        }
        gesturesItem.state = AppSettings.multitouchGestures ? .on : .off
        submenu.addItem(gesturesItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        let blacklistItem = NSMenuItem(
            title: "Toggle Current App in Blacklist",
            action: #selector(toggleBlackListedApp(_:)),
            keyEquivalent: ""
        )
        if let blacklistIcon = NSImage(systemSymbolName: "app.badge.checkmark", accessibilityDescription: "Blacklist") {
            blacklistItem.image = blacklistIcon
        }
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
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )
        if let updateIcon = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Updates") {
            updateItem.image = updateIcon
        }
        submenu.addItem(updateItem)
        
        let aboutItem = NSMenuItem(
            title: "About MTMR",
            action: #selector(showAbout(_:)),
            keyEquivalent: ""
        )
        if let aboutIcon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About") {
            aboutItem.image = aboutIcon
        }
        submenu.addItem(aboutItem)
        
        // Main item
        let mainItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        if let helpIcon = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Help") {
            mainItem.image = helpIcon
        }
        mainItem.submenu = submenu
        
        return mainItem
    }

    func reloadOnDefaultConfigChanged() {
        let file = NSURL.fileURL(withPath: standardConfigPath)

        let fd = open(file.path, O_EVTONLY)

        fileSystemSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: DispatchQueue(label: "DefaultConfigChanged"))

        fileSystemSource?.setEventHandler(handler: {
            print("Config changed, reloading...")
            DispatchQueue.main.async {
                TouchBarController.shared.reloadPreset(path: file.path)
            }
        })

        fileSystemSource?.setCancelHandler(handler: {
            close(fd)
        })

        fileSystemSource?.resume()
    }
}
