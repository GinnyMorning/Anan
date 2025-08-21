import Foundation
import AppKit
import CoreLocation

class EnhancedPermissionManager: NSObject {
    static let shared = EnhancedPermissionManager()
    
    private let userDefaults = UserDefaults.standard
    private let permissionCheckInterval: TimeInterval = 3600 // Check every hour instead of every launch
    
    // Permission keys
    private let lastPermissionCheckKey = "com.toxblh.mtmr.lastPermissionCheck"
    private let accessibilityPermissionKey = "com.toxblh.mtmr.accessibilityPermission"
    private let locationPermissionKey = "com.toxblh.mtmr.locationPermission"
    private let audioPermissionKey = "com.toxblh.mtmr.audioPermission"
    private let brightnessPermissionKey = "com.toxblh.mtmr.brightnessPermission"
    
    // Permission states
    enum PermissionState: String {
        case notDetermined = "notDetermined"
        case granted = "granted"
        case denied = "denied"
        case restricted = "restricted"
        case unavailable = "unavailable"
    }
    
    private override init() {
        super.init()
    }
    
    // MARK: - Smart Permission Checking
    
    func shouldCheckPermissions() -> Bool {
        let lastCheck = userDefaults.object(forKey: lastPermissionCheckKey) as? Date ?? Date.distantPast
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
        
        // Only check permissions if enough time has passed or if we haven't checked before
        return timeSinceLastCheck >= permissionCheckInterval || lastCheck == Date.distantPast
    }
    
    func checkAllPermissions() -> [String: PermissionState] {
        let permissions = [
            "accessibility": checkAccessibilityPermission(),
            "location": checkLocationPermission(),
            "audio": checkAudioPermission(),
            "brightness": checkBrightnessPermission()
        ]
        
        // Update last check time
        userDefaults.set(Date(), forKey: lastPermissionCheckKey)
        
        return permissions
    }
    
    // MARK: - Individual Permission Checks
    
    func checkAccessibilityPermission() -> PermissionState {
        let trusted = AXIsProcessTrusted()
        let state: PermissionState = trusted ? .granted : .denied
        
        // Cache the result
        userDefaults.set(state.rawValue, forKey: accessibilityPermissionKey)
        
        return state
    }
    
    func checkLocationPermission() -> PermissionState {
        let status = CLLocationManager().authorizationStatus
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
        
        return state
    }
    
    func checkAudioPermission() -> PermissionState {
        // Check if we can access audio system
        let canAccessAudio = canAccessAudioSystem()
        let state: PermissionState = canAccessAudio ? .granted : .denied
        
        // Cache the result
        userDefaults.set(state.rawValue, forKey: audioPermissionKey)
        
        return state
    }
    
    func checkBrightnessPermission() -> PermissionState {
        // Check if we can access display brightness
        let canAccessBrightness = canAccessBrightnessSystem()
        let state: PermissionState = canAccessBrightness ? .granted : .denied
        
        // Cache the result
        userDefaults.set(state.rawValue, forKey: brightnessPermissionKey)
        
        return state
    }
    
    // MARK: - Permission Request Methods
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func requestLocationPermission() {
        let locationManager = CLLocationManager()
        if #available(macOS 10.15, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // For older macOS versions, just start updates
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Permission Status Methods
    
    func getCachedPermissionState(for permission: String) -> PermissionState {
        let key = "com.toxblh.mtmr.\(permission)Permission"
        let rawValue = userDefaults.string(forKey: key) ?? PermissionState.notDetermined.rawValue
        return PermissionState(rawValue: rawValue) ?? .notDetermined
    }
    
    func isPermissionGranted(for permission: String) -> Bool {
        return getCachedPermissionState(for: permission) == .granted
    }
    
    // MARK: - Smart Permission Requests
    
    func smartRequestPermission(for permission: String) -> Bool {
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
            requestAccessibilityPermission()
        case "location":
            requestLocationPermission()
        default:
            return false
        }
        
        return true
    }
    
    // MARK: - Permission Status Display
    
    func getPermissionStatusSummary() -> String {
        let permissions = checkAllPermissions()
        var summary = "Permission Status:\n"
        
        for (permission, state) in permissions {
            let status = state == .granted ? "✅" : "❌"
            summary += "  \(permission.capitalized): \(status) \(state.rawValue)\n"
        }
        
        return summary
    }
    
    // MARK: - Helper Methods
    
    private func canAccessAudioSystem() -> Bool {
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
    
    private func canAccessBrightnessSystem() -> Bool {
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
    }
}
