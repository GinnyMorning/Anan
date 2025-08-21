//
//  ActorBasedPermissionManager.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  Actor-based permission manager for thread safety
//

import Foundation
import AppKit
import CoreLocation
import CoreAudio
import IOKit

/// Actor-based permission manager for Swift 6.0 concurrency
/// This provides thread-safe permission management using Swift actors
actor ActorBasedPermissionManager {
    
    // MARK: - Singleton Pattern (Actor-Isolated)
    
    static let shared = ActorBasedPermissionManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let permissionCheckInterval: TimeInterval = 3600 // Check every hour
    
    // Permission keys
    private let lastPermissionCheckKey = "com.toxblh.mtmr.lastPermissionCheck"
    private let accessibilityPermissionKey = "com.toxblh.mtmr.accessibilityPermission"
    private let locationPermissionKey = "com.toxblh.mtmr.locationPermission"
    private let audioPermissionKey = "com.toxblh.mtmr.audioPermission"
    private let brightnessPermissionKey = "com.toxblh.mtmr.brightnessPermission"
    
    // Permission states
    enum PermissionState: String, Sendable {
        case notDetermined = "notDetermined"
        case granted = "granted"
        case denied = "denied"
        case restricted = "restricted"
        case unavailable = "unavailable"
    }
    
    // Permission cache for performance
    private var permissionCache: [String: PermissionState] = [:]
    private var lastCheckTime: Date?
    
    private init() {
        // Load cached permissions on initialization
        loadCachedPermissions()
    }
    
    // MARK: - Smart Permission Checking
    
    func shouldCheckPermissions() -> Bool {
        let lastCheck = lastCheckTime ?? userDefaults.object(forKey: lastPermissionCheckKey) as? Date ?? Date.distantPast
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
        
        // Only check permissions if enough time has passed or if we haven't checked before
        return timeSinceLastCheck >= permissionCheckInterval || lastCheck == Date.distantPast
    }
    
    func checkAllPermissions() async -> [String: PermissionState] {
        let permissions = [
            "accessibility": await checkAccessibilityPermission(),
            "location": await checkLocationPermission(),
            "audio": await checkAudioPermission(),
            "brightness": await checkBrightnessPermission()
        ]
        
        // Update cache and last check time
        permissionCache = permissions
        lastCheckTime = Date()
        userDefaults.set(lastCheckTime, forKey: lastPermissionCheckKey)
        
        return permissions
    }
    
    // MARK: - Individual Permission Checks
    
    func checkAccessibilityPermission() async -> PermissionState {
        // Check if we have a cached result
        if let cached = permissionCache["accessibility"] {
            return cached
        }
        
        // Perform the check on the main actor since it involves UI operations
        let state = await MainActor.run {
            let trusted = AXIsProcessTrusted()
            let permissionState: PermissionState = trusted ? .granted : .denied
            
            // Cache the result
            userDefaults.set(permissionState.rawValue, forKey: accessibilityPermissionKey)
            
            return permissionState
        }
        
        // Update cache
        permissionCache["accessibility"] = state
        
        return state
    }
    
    func checkLocationPermission() async -> PermissionState {
        // Check if we have a cached result
        if let cached = permissionCache["location"] {
            return cached
        }
        
        let status = CLLocationManager.authorizationStatus()
        let state: PermissionState
        
        switch status {
        case .notDetermined:
            state = .notDetermined
        case .restricted:
            state = .restricted
        case .denied:
            state = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            state = .granted
        @unknown default:
            state = .unavailable
        }
        
        // Cache the result
        userDefaults.set(state.rawValue, forKey: locationPermissionKey)
        permissionCache["location"] = state
        
        return state
    }
    
    func checkAudioPermission() async -> PermissionState {
        // Check if we have a cached result
        if let cached = permissionCache["audio"] {
            return cached
        }
        
        let canAccessAudio = await canAccessAudioSystem()
        let state: PermissionState = canAccessAudio ? .granted : .denied
        
        // Cache the result
        userDefaults.set(state.rawValue, forKey: audioPermissionKey)
        permissionCache["audio"] = state
        
        return state
    }
    
    func checkBrightnessPermission() async -> PermissionState {
        // Check if we have a cached result
        if let cached = permissionCache["brightness"] {
            return cached
        }
        
        let canAccessBrightness = await canAccessBrightnessSystem()
        let state: PermissionState = canAccessBrightness ? .granted : .denied
        
        // Cache the result
        userDefaults.set(state.rawValue, forKey: brightnessPermissionKey)
        permissionCache["brightness"] = state
        
        return state
    }
    
    // MARK: - Permission Request Methods
    
    func requestAccessibilityPermission() async {
        await MainActor.run {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
    }
    
    func requestLocationPermission() async {
        await MainActor.run {
            let locationManager = CLLocationManager()
            if #available(macOS 10.15, *) {
                locationManager.requestWhenInUseAuthorization()
            } else {
                // For older macOS versions, just start updates
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    // MARK: - Permission Status Methods
    
    func getCachedPermissionState(for permission: String) -> PermissionState {
        // First check our in-memory cache
        if let cached = permissionCache[permission] {
            return cached
        }
        
        // Fall back to UserDefaults
        let key = "com.toxblh.mtmr.\(permission)Permission"
        let rawValue = userDefaults.string(forKey: key) ?? PermissionState.notDetermined.rawValue
        let state = PermissionState(rawValue: rawValue) ?? .notDetermined
        
        // Update cache
        permissionCache[permission] = state
        
        return state
    }
    
    func isPermissionGranted(for permission: String) -> Bool {
        return getCachedPermissionState(for: permission) == .granted
    }
    
    // MARK: - Smart Permission Requests
    
    func smartRequestPermission(for permission: String) async -> Bool {
        // Check if we already have permission
        if isPermissionGranted(for: permission) {
            return true
        }
        
        // Check if we should ask again (avoid spam)
        let lastRequestKey = "com.toxblh.mtmr.lastRequest.\(permission)"
        let lastRequest = userDefaults.object(forKey: lastRequestKey) as? Date ?? Date.distantPast
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
        
        // Only ask once per day
        if timeSinceLastRequest < 86400 { // 24 hours
            return false
        }
        
        // Update last request time
        userDefaults.set(Date(), forKey: lastRequestKey)
        
        // Request permission
        switch permission {
        case "accessibility":
            await requestAccessibilityPermission()
        case "location":
            await requestLocationPermission()
        default:
            return false
        }
        
        return true
    }
    
    // MARK: - Permission Status Display
    
    func getPermissionStatusSummary() async -> String {
        let permissions = await checkAllPermissions()
        var summary = "Permission Status:\n"
        
        for (permission, state) in permissions {
            let status = state == .granted ? "✅" : "❌"
            summary += "  \(permission.capitalized): \(status) \(state.rawValue)\n"
        }
        
        return summary
    }
    
    // MARK: - Helper Methods
    
    private func canAccessAudioSystem() async -> Bool {
        // Try to get the default audio device
        var deviceID: AudioObjectID = AudioObjectID(0)
        var size: UInt32 = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return status == noErr && deviceID != AudioObjectID(0)
    }
    
    private func canAccessBrightnessSystem() async -> Bool {
        if #available(OSX 10.13, *) {
            // Try CoreDisplay method
            let brightness = CoreDisplay_Display_GetUserBrightness(0)
            return brightness >= 0.0 && brightness <= 1.0
        } else {
            // Try IOKit method
            let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
            if service != 0 {
                IOObjectRelease(service)
                return true
            }
            return false
        }
    }
    
    // MARK: - Cache Management
    
    private func loadCachedPermissions() {
        // Load all cached permissions from UserDefaults
        let permissions = [
            "accessibility": accessibilityPermissionKey,
            "location": locationPermissionKey,
            "audio": audioPermissionKey,
            "brightness": brightnessPermissionKey
        ]
        
        for (key, userDefaultsKey) in permissions {
            if let rawValue = userDefaults.string(forKey: userDefaultsKey),
               let state = PermissionState(rawValue: rawValue) {
                permissionCache[key] = state
            }
        }
        
        // Load last check time
        lastCheckTime = userDefaults.object(forKey: lastPermissionCheckKey) as? Date
    }
    
    func refreshPermissionCache() async {
        // Clear cache and reload
        permissionCache.removeAll()
        await checkAllPermissions()
    }
    
    // MARK: - Permission Reset (for testing)
    
    func resetPermissionCache() {
        let keys = [
            lastPermissionCheckKey,
            accessibilityPermissionKey,
            locationPermissionKey,
            audioPermissionKey,
            brightnessPermissionKey
        ]
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
        
        // Also reset last request times
        let lastRequestKeys = [
            "com.toxblh.mtmr.lastRequest.accessibility",
            "com.toxblh.mtmr.lastRequest.location"
        ]
        
        for key in lastRequestKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        // Clear in-memory cache
        permissionCache.removeAll()
        lastCheckTime = nil
    }
    
    // MARK: - Performance Monitoring
    
    func getCacheStats() -> (cachedPermissions: Int, lastCheck: Date?) {
        return (permissionCache.count, lastCheckTime)
    }
    
    func isCacheValid() -> Bool {
        guard let lastCheck = lastCheckTime else { return false }
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
        return timeSinceLastCheck < permissionCheckInterval
    }
}

// MARK: - Migration Support

extension ActorBasedPermissionManager {
    
    /// Migrate from legacy EnhancedPermissionManager
    func migrateFromLegacy(_ legacyManager: EnhancedPermissionManager) async {
        print("MTMR: Migrating permission manager to actor-based version...")
        
        // Copy all cached permissions
        let permissions = legacyManager.checkAllPermissions()
        
        // Update our cache with legacy data
        for (permission, state) in permissions {
            permissionCache[permission] = state
        }
        
        // Copy last check time
        if let lastCheck = UserDefaults.standard.object(forKey: lastPermissionCheckKey) as? Date {
            lastCheckTime = lastCheck
        }
        
        print("MTMR: Permission manager migration completed")
    }
    
    /// Check if migration is needed
    var needsMigration: Bool {
        return permissionCache.isEmpty && lastCheckTime == nil
    }
}
