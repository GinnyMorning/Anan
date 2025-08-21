//
//  ConcurrentUserDefault.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  Thread-safe UserDefaults property wrapper
//

import Foundation

// Forward declaration for migration - will be resolved when both files are in the same module

/// Thread-safe UserDefaults property wrapper for Swift 6.0 concurrency
@propertyWrapper
struct ConcurrentUserDefault<T: Sendable> {
    private let key: String
    private let defaultValue: T
    private let queue = DispatchQueue(label: "userdefaults.\(UUID().uuidString)", attributes: .concurrent)
    
    var wrappedValue: T {
        get {
            queue.sync {
                UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
            }
        }
        set {
            queue.async(flags: .barrier) {
                UserDefaults.standard.set(newValue, forKey: key)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

/// Settings-specific global actor for centralized settings management
@globalActor
actor SettingsActor {
    static let shared = SettingsActor()
    
    private init() {}
}

/// Thread-safe settings access with actor isolation
@SettingsActor
struct ConcurrentAppSettings {
    @ConcurrentUserDefault(key: "com.toxblh.mtmr.settings.showControlStrip", defaultValue: false)
    static var showControlStripState: Bool
    
    @ConcurrentUserDefault(key: "com.toxblh.mtmr.settings.hapticFeedback", defaultValue: true)
    static var hapticFeedbackState: Bool
    
    @ConcurrentUserDefault(key: "com.toxblh.mtmr.settings.multitouchGestures", defaultValue: true)
    static var multitouchGestures: Bool
    
    @ConcurrentUserDefault(key: "com.toxblh.mtmr.blackListedApps", defaultValue: [])
    static var blacklistedAppIds: [String]
    
    @ConcurrentUserDefault(key: "com.toxblh.mtmr.dock.persistent", defaultValue: [])
    static var dockPersistentAppIds: [String]
    
    /// Migration helper: Copy values from old AppSettings
    /// Note: This function will be uncommented after AppSettings migration
    /*
    static func migrateFromLegacySettings() async {
        // This will be called during migration to preserve user settings
        let legacySettings = AppSettings.self
        
        showControlStripState = legacySettings.showControlStripState
        hapticFeedbackState = legacySettings.hapticFeedbackState
        multitouchGestures = legacySettings.multitouchGestures
        blacklistedAppIds = legacySettings.blacklistedAppIds
        dockPersistentAppIds = legacySettings.dockPersistentAppIds
    }
    */
}
