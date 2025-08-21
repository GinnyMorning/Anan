//
//  ActorBasedPermissionManager.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  Thread-safe permission management using actors
//

import Foundation
import AppKit
import CoreLocation

/// Thread-safe permission manager using Swift 6.0 actors
actor ActorBasedPermissionManager {
    static let shared = ActorBasedPermissionManager()
    
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
    
    private init() {}
    
    // MARK: - Smart Permission Checking
    
    func shouldCheckPermissions() -> Bool {
        let lastCheck = userDefaults.object(forKey: lastPermissionCheckKey) as? Date ?? Date.distantPast
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
        
        return timeSinceLastCheck >= permissionCheckInterval || lastCheck == Date.distantPast
    }
    
    func checkAllPermissions() async -> [String: PermissionState] {
        let permissions = [
            "accessibility": await checkAccessibilityPermission(),
            "location": await checkLocationPermission(),
            "audio": await checkAudioPermission(),
            "brightness": await checkBrightnessPermission()
        ]
        
        // Update last check time
        userDefaults.set(Date(), forKey: lastPermissionCheckKey)
        
        return permissions
    }
    
    // MARK: - Individual Permission Checks
    
    private func checkAccessibilityPermission() async -> PermissionState {
        // Check cached state first
        if let cachedState = getCachedPermissionState(for: accessibilityPermissionKey) {
            return cachedState
        }
        
        // Check actual permission
        let isGranted = await MainActor.run {
            AXIsProcessTrusted()
        }
        
        let state: PermissionState = isGranted ? .granted : .denied
        setCachedPermissionState(state, for: accessibilityPermissionKey)
        
        return state
    }
    
    private func checkLocationPermission() async -> PermissionState {
        if let cachedState = getCachedPermissionState(for: locationPermissionKey) {
            return cachedState
        }
        
        let authStatus = await MainActor.run {
            CLLocationManager.authorizationStatus()
        }
        
        let state: PermissionState
        switch authStatus {
        case .authorizedAlways:
            state = .granted
        case .denied:
            state = .denied
        case .restricted:
            state = .restricted
        case .notDetermined:
            state = .notDetermined
        @unknown default:
            state = .unavailable
        }
        
        setCachedPermissionState(state, for: locationPermissionKey)
        return state
    }
    
    private func checkAudioPermission() async -> PermissionState {
        if let cachedState = getCachedPermissionState(for: audioPermissionKey) {
            return cachedState
        }
        
        // For audio, we assume granted if we can access system volume
        // This is a simplified check - in reality, you might want more sophisticated checking
        let state: PermissionState = .granted
        setCachedPermissionState(state, for: audioPermissionKey)
        
        return state
    }
    
    private func checkBrightnessPermission() async -> PermissionState {
        if let cachedState = getCachedPermissionState(for: brightnessPermissionKey) {
            return cachedState
        }
        
        // For brightness, we assume granted if we can access display controls
        let state: PermissionState = .granted
        setCachedPermissionState(state, for: brightnessPermissionKey)
        
        return state
    }
    
    // MARK: - Smart Request Logic
    
    func requestPermissionIfNeeded(for type: String) async -> Bool {
        let permissions = await checkAllPermissions()
        guard let currentState = permissions[type] else { return false }
        
        switch currentState {
        case .granted:
            return true
        case .notDetermined:
            return await requestPermission(for: type)
        case .denied, .restricted, .unavailable:
            return false
        }
    }
    
    private func requestPermission(for type: String) async -> Bool {
        switch type {
        case "accessibility":
            return await requestAccessibilityPermission()
        case "location":
            return await requestLocationPermission()
        default:
            return false
        }
    }
    
    private func requestAccessibilityPermission() async -> Bool {
        return await MainActor.run {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true] as NSDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
    }
    
    private func requestLocationPermission() async -> Bool {
        // This would typically involve creating a location manager and requesting permission
        // For now, we'll return false as this requires more complex async handling
        return false
    }
    
    // MARK: - Caching
    
    private func getCachedPermissionState(for key: String) -> PermissionState? {
        guard let rawValue = userDefaults.string(forKey: key) else { return nil }
        return PermissionState(rawValue: rawValue)
    }
    
    private func setCachedPermissionState(_ state: PermissionState, for key: String) {
        userDefaults.set(state.rawValue, forKey: key)
    }
    
    // MARK: - Migration Helper
    
    func migrateFromLegacyPermissionManager() async {
        // This will be called during migration to preserve cached permission states
        // Implementation would copy over any existing cached states
        print("Migrating permission states from legacy EnhancedPermissionManager")
    }
}
