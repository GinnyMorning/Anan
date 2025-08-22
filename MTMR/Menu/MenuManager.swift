//
//  MenuManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Modern menu management with widget configuration support.
//

import Cocoa
import SwiftUI

@MainActor
final class MenuManager: ObservableObject {
    static let shared = MenuManager()
    
    @Published var isWidgetBrowserOpen = false
    @Published var isConfigurationOpen = false
    @Published var currentMenuState = MenuState()
    
    private init() {}
    
    // MARK: - Menu Creation
    
    func createEnhancedMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Widget Configuration Section
        menu.addItem(createWidgetConfigurationSection())
        menu.addItem(NSMenuItem.separator())
        
        // Preset Management Section
        menu.addItem(createPresetManagementSection())
        menu.addItem(NSMenuItem.separator())
        
        // Settings Section
        menu.addItem(createSettingsSection())
        menu.addItem(NSMenuItem.separator())
        
        // Help & Updates Section
        menu.addItem(createHelpSection())
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit MTMR", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")
        menu.addItem(quitItem)
        
        return menu
    }
    
    // MARK: - Widget Configuration Section
    
    private func createWidgetConfigurationSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        // Add New Widget
        let addWidgetItem = NSMenuItem(
            title: "Add New Widget...",
            action: #selector(openWidgetBrowser),
            keyEquivalent: "w"
        )
        addWidgetItem.image = NSImage(systemSymbolName: "plus.square", accessibilityDescription: "Add Widget")
        addWidgetItem.target = self
        submenu.addItem(addWidgetItem)
        
        // Edit Current Layout
        let editLayoutItem = NSMenuItem(
            title: "Edit Current Layout...",
            action: #selector(openLayoutEditor),
            keyEquivalent: "l"
        )
        editLayoutItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Edit Layout")
        editLayoutItem.target = self
        submenu.addItem(editLayoutItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        // Quick Widget Access
        let quickAccessSubmenu = createQuickWidgetAccessSubmenu()
        let quickAccessItem = NSMenuItem(title: "Quick Add", action: nil, keyEquivalent: "")
        quickAccessItem.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Quick Add")
        quickAccessItem.submenu = quickAccessSubmenu
        submenu.addItem(quickAccessItem)
        
        // Widget Browser
        let browserItem = NSMenuItem(
            title: "Widget Browser...",
            action: #selector(openWidgetBrowser),
            keyEquivalent: "b"
        )
        browserItem.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "Widget Browser")
        browserItem.target = self
        submenu.addItem(browserItem)
        
        // Main menu item
        let mainItem = NSMenuItem(title: "Widget Configuration", action: nil, keyEquivalent: "")
        mainItem.image = NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: "Widget Configuration")
        mainItem.submenu = submenu
        
        return mainItem
    }
    
    private func createQuickWidgetAccessSubmenu() -> NSMenu {
        let submenu = NSMenu()
        
        let commonWidgets = [
            ("System Controls", "gear", [
                ("Escape Key", "escape", #selector(addEscapeWidget)),
                ("Volume Controls", "speaker.wave.3", #selector(addVolumeControls)),
                ("Brightness Controls", "sun.max", #selector(addBrightnessControls)),
                ("DND Toggle", "moon", #selector(addDNDToggle))
            ]),
            ("Productivity", "briefcase", [
                ("Weather", "cloud.sun", #selector(addWeatherWidget)),
                ("Clock", "clock", #selector(addClockWidget)),
                ("Pomodoro Timer", "timer", #selector(addPomodoroWidget)),
                ("CPU Monitor", "cpu", #selector(addCPUWidget))
            ]),
            ("Media & Apps", "play.rectangle", [
                ("Media Controls", "play.circle", #selector(addMediaControls)),
                ("App Launcher", "app.badge", #selector(addAppLauncher)),
                ("Dock", "dock.rectangle", #selector(addDockWidget))
            ])
        ]
        
        for (categoryName, categoryIcon, widgets) in commonWidgets {
            let categorySubmenu = NSMenu()
            
            for (widgetName, widgetIcon, action) in widgets {
                let item = NSMenuItem(title: widgetName, action: action, keyEquivalent: "")
                item.image = NSImage(systemSymbolName: widgetIcon, accessibilityDescription: widgetName)
                item.target = self
                categorySubmenu.addItem(item)
            }
            
            let categoryItem = NSMenuItem(title: categoryName, action: nil, keyEquivalent: "")
            categoryItem.image = NSImage(systemSymbolName: categoryIcon, accessibilityDescription: categoryName)
            categoryItem.submenu = categorySubmenu
            submenu.addItem(categoryItem)
        }
        
        return submenu
    }
    
    // MARK: - Preset Management Section
    
    private func createPresetManagementSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        // Open Preset
        let openItem = NSMenuItem(
            title: "Open Preset...",
            action: #selector(openPreset),
            keyEquivalent: "o"
        )
        openItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "Open Preset")
        openItem.target = self
        submenu.addItem(openItem)
        
        // Save Current as Preset
        let saveItem = NSMenuItem(
            title: "Save Current as Preset...",
            action: #selector(saveAsPreset),
            keyEquivalent: "s"
        )
        saveItem.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Save Preset")
        saveItem.target = self
        submenu.addItem(saveItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        // Manage Presets
        let manageItem = NSMenuItem(
            title: "Manage Presets...",
            action: #selector(managePresets),
            keyEquivalent: "m"
        )
        manageItem.image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: "Manage Presets")
        manageItem.target = self
        submenu.addItem(manageItem)
        
        // Import/Export
        let importItem = NSMenuItem(
            title: "Import Preset...",
            action: #selector(importPreset),
            keyEquivalent: ""
        )
        importItem.image = NSImage(systemSymbolName: "square.and.arrow.down.on.square", accessibilityDescription: "Import")
        importItem.target = self
        submenu.addItem(importItem)
        
        let exportItem = NSMenuItem(
            title: "Export Current...",
            action: #selector(exportPreset),
            keyEquivalent: ""
        )
        exportItem.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Export")
        exportItem.target = self
        submenu.addItem(exportItem)
        
        // Main menu item
        let mainItem = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        mainItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Presets")
        mainItem.submenu = submenu
        
        return mainItem
    }
    
    // MARK: - Settings Section
    
    private func createSettingsSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        // General Settings
        let generalSubmenu = createGeneralSettingsSubmenu()
        let generalItem = NSMenuItem(title: "General", action: nil, keyEquivalent: "")
        generalItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General Settings")
        generalItem.submenu = generalSubmenu
        submenu.addItem(generalItem)
        
        // Appearance
        let appearanceItem = NSMenuItem(
            title: "Appearance...",
            action: #selector(openAppearanceSettings),
            keyEquivalent: ""
        )
        appearanceItem.image = NSImage(systemSymbolName: "paintbrush", accessibilityDescription: "Appearance")
        appearanceItem.target = self
        submenu.addItem(appearanceItem)
        
        // Permissions
        let permissionsItem = NSMenuItem(
            title: "Permissions...",
            action: #selector(openPermissionsSettings),
            keyEquivalent: ""
        )
        permissionsItem.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "Permissions")
        permissionsItem.target = self
        submenu.addItem(permissionsItem)
        
        // Main menu item
        let mainItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        mainItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings")
        mainItem.submenu = submenu
        
        return mainItem
    }
    
    private func createGeneralSettingsSubmenu() -> NSMenu {
        let submenu = NSMenu()
        
        // Start at Login
        let startAtLoginItem = NSMenuItem(
            title: "Start at Login",
            action: #selector(toggleStartAtLogin),
            keyEquivalent: ""
        )
        startAtLoginItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Start at Login")
        startAtLoginItem.target = self
        startAtLoginItem.state = LaunchAtLoginController().launchAtLogin ? .on : .off
        submenu.addItem(startAtLoginItem)
        
        // Haptic Feedback
        let hapticItem = NSMenuItem(
            title: "Haptic Feedback",
            action: #selector(toggleHapticFeedback),
            keyEquivalent: ""
        )
        hapticItem.image = NSImage(systemSymbolName: "hand.tap", accessibilityDescription: "Haptic Feedback")
        hapticItem.target = self
        hapticItem.state = AppSettings.hapticFeedbackState ? .on : .off
        submenu.addItem(hapticItem)
        
        // Hide Control Strip
        let controlStripItem = NSMenuItem(
            title: "Hide Control Strip",
            action: #selector(toggleControlStrip),
            keyEquivalent: ""
        )
        controlStripItem.image = NSImage(systemSymbolName: "rectangle.3.offgrid", accessibilityDescription: "Control Strip")
        controlStripItem.target = self
        controlStripItem.state = AppSettings.showControlStripState ? .off : .on
        submenu.addItem(controlStripItem)
        
        // Volume/Brightness Gestures
        let gesturesItem = NSMenuItem(
            title: "Volume/Brightness Gestures",
            action: #selector(toggleMultitouch),
            keyEquivalent: ""
        )
        gesturesItem.image = NSImage(systemSymbolName: "hand.draw", accessibilityDescription: "Gestures")
        gesturesItem.target = self
        gesturesItem.state = AppSettings.multitouchGestures ? .on : .off
        submenu.addItem(gesturesItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        // Blacklist Current App
        let blacklistItem = NSMenuItem(
            title: "Toggle Current App in Blacklist",
            action: #selector(toggleBlackListedApp),
            keyEquivalent: ""
        )
        blacklistItem.image = NSImage(systemSymbolName: "app.badge.checkmark", accessibilityDescription: "Blacklist")
        blacklistItem.target = self
        submenu.addItem(blacklistItem)
        
        return submenu
    }
    
    // MARK: - Help Section
    
    private func createHelpSection() -> NSMenuItem {
        let submenu = NSMenu()
        
        // Check for Updates
        let updateItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: "Updates")
        updateItem.target = self
        submenu.addItem(updateItem)
        
        // Documentation
        let docsItem = NSMenuItem(
            title: "Documentation",
            action: #selector(openDocumentation),
            keyEquivalent: ""
        )
        docsItem.image = NSImage(systemSymbolName: "book", accessibilityDescription: "Documentation")
        docsItem.target = self
        submenu.addItem(docsItem)
        
        // Report Issue
        let reportItem = NSMenuItem(
            title: "Report Issue...",
            action: #selector(reportIssue),
            keyEquivalent: ""
        )
        reportItem.image = NSImage(systemSymbolName: "exclamationmark.bubble", accessibilityDescription: "Report Issue")
        reportItem.target = self
        submenu.addItem(reportItem)
        
        submenu.addItem(NSMenuItem.separator())
        
        // About
        let aboutItem = NSMenuItem(
            title: "About MTMR",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")
        aboutItem.target = self
        submenu.addItem(aboutItem)
        
        // Main menu item
        let mainItem = NSMenuItem(title: "Help & Updates", action: nil, keyEquivalent: "")
        mainItem.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Help")
        mainItem.submenu = submenu
        
        return mainItem
    }
}

// MARK: - Menu Actions
extension MenuManager {
    
    // MARK: Widget Configuration Actions
    
    @objc func openWidgetBrowser() {
        print("MTMR: Opening Widget Browser...")
        // TODO: Implement widget browser window
        isWidgetBrowserOpen = true
    }
    
    @objc func openLayoutEditor() {
        print("MTMR: Opening Layout Editor...")
        // TODO: Implement layout editor
    }
    
    // MARK: Quick Widget Actions
    
    @objc func addEscapeWidget() {
        WidgetManager.shared.addQuickWidget(.escape)
    }
    
    @objc func addVolumeControls() {
        WidgetManager.shared.addQuickWidget(.volumeControls)
    }
    
    @objc func addBrightnessControls() {
        WidgetManager.shared.addQuickWidget(.brightnessControls)
    }
    
    @objc func addDNDToggle() {
        WidgetManager.shared.addQuickWidget(.dndToggle)
    }
    
    @objc func addWeatherWidget() {
        WidgetManager.shared.addQuickWidget(.weather)
    }
    
    @objc func addClockWidget() {
        WidgetManager.shared.addQuickWidget(.clock)
    }
    
    @objc func addPomodoroWidget() {
        WidgetManager.shared.addQuickWidget(.pomodoro)
    }
    
    @objc func addCPUWidget() {
        WidgetManager.shared.addQuickWidget(.cpu)
    }
    
    @objc func addMediaControls() {
        WidgetManager.shared.addQuickWidget(.mediaControls)
    }
    
    @objc func addAppLauncher() {
        WidgetManager.shared.addQuickWidget(.appLauncher)
    }
    
    @objc func addDockWidget() {
        WidgetManager.shared.addQuickWidget(.dock)
    }
    
    // MARK: Preset Actions
    
    @objc func openPreset() {
        print("MTMR: Opening preset...")
        PresetManager.shared.openPresetDialog()
    }
    
    @objc func saveAsPreset() {
        print("MTMR: Saving as preset...")
        PresetManager.shared.saveAsPresetDialog()
    }
    
    @objc func managePresets() {
        print("MTMR: Managing presets...")
        PresetManager.shared.openPresetManager()
    }
    
    @objc func importPreset() {
        print("MTMR: Importing preset...")
        PresetManager.shared.importPresetDialog()
    }
    
    @objc func exportPreset() {
        print("MTMR: Exporting preset...")
        PresetManager.shared.exportPresetDialog()
    }
    
    // MARK: Settings Actions
    
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
    
    @objc func openAppearanceSettings() {
        print("MTMR: Opening appearance settings...")
        // TODO: Implement appearance settings
    }
    
    @objc func openPermissionsSettings() {
        print("MTMR: Opening permissions settings...")
        // TODO: Implement permissions settings
    }
    
    // MARK: Help Actions
    
    @objc func checkForUpdates() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.checkForUpdates(nil)
        }
    }
    
    @objc func openDocumentation() {
        if let url = URL(string: "https://github.com/Toxblh/MTMR/wiki") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func reportIssue() {
        if let url = URL(string: "https://github.com/Toxblh/MTMR/issues/new") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }
    
    // MARK: - State Management
    
    func updateMenuState() {
        objectWillChange.send()
        // Notify AppDelegate to recreate menu with updated state
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.createMenu()
        }
    }
}

// MARK: - Supporting Types

struct MenuState {
    var startAtLogin: Bool = false
    var hapticFeedback: Bool = false
    var showControlStrip: Bool = true
    var multitouchGestures: Bool = false
    var isBlacklisted: Bool = false
}

enum QuickWidgetType {
    case escape, volumeControls, brightnessControls, dndToggle
    case weather, clock, pomodoro, cpu
    case mediaControls, appLauncher, dock
}
