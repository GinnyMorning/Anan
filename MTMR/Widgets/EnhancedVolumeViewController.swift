import AppKit
import AVFoundation
import Cocoa
import CoreAudio

class EnhancedVolumeViewController: EnhancedWidgetBase {
    private(set) var sliderItem: CustomSlider!
    private var currentDeviceId: AudioObjectID = AudioObjectID(0)
    private var audioDeviceCache: [String: AudioObjectID] = [:]
    
    init(identifier: NSTouchBarItem.Identifier, image: NSImage? = nil) {
        super.init(identifier: identifier)
        
        if image == nil {
            sliderItem = CustomSlider()
        } else {
            sliderItem = CustomSlider(knob: image!)
        }
        sliderItem.target = self
        sliderItem.action = #selector(EnhancedVolumeViewController.sliderValueChanged(_:))
        sliderItem.minValue = 0.0
        sliderItem.maxValue = 100.0

        view = sliderItem
        
        // Setup the widget
        setupWidget()
        
        // Start updates with smart interval
        startUpdates(interval: 2.0) // Update every 2 seconds instead of constantly
    }
    
    override func setupWidget() {
        // Check permissions first
        if !checkPermission(for: "audio") {
            print("MTMR: Audio permission not granted, requesting...")
            if smartRequestPermission(for: "accessibility") {
                // Wait a bit for permission to be granted
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.initializeVolumeControl()
                }
            } else {
                print("MTMR: Audio permission request failed or was recently requested")
                setDefaultState()
            }
        } else {
            initializeVolumeControl()
        }
    }
    
    private func initializeVolumeControl() {
        currentDeviceId = getDefaultAudioDevice()
        
        if currentDeviceId != AudioObjectID(0) {
            print("MTMR: Enhanced volume control initialized with device ID: \(currentDeviceId)")
            
            // Cache the device ID
            cacheValue(currentDeviceId, forKey: "currentAudioDevice", expiry: 3600) // Cache for 1 hour
            
            // Set initial slider value
            let currentVolume = getCurrentVolume()
            performOnMainThread {
                self.sliderItem.floatValue = currentVolume * 100
            }
            
            // Add listeners
            addAudioRouteChangedListener()
            addCurrentAudioVolumeChangedListener()
        } else {
            print("MTMR: Failed to initialize volume control - no valid audio device")
            setDefaultState()
        }
    }
    
    private func setDefaultState() {
        performOnMainThread {
            self.sliderItem.floatValue = 50.0 // Default to 50%
        }
    }
    
    private func getDefaultAudioDevice() -> AudioObjectID {
        // Check cache first
        if let cachedDeviceId = getCachedValue(forKey: "defaultAudioDevice") as? AudioObjectID,
           cachedDeviceId != AudioObjectID(0) {
            return cachedDeviceId
        }
        
        var deviceID: AudioObjectID = AudioObjectID(0)
        var size: UInt32 = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        
        if status == noErr && deviceID != AudioObjectID(0) {
            // Cache the result
            cacheValue(deviceID, forKey: "defaultAudioDevice", expiry: 3600)
            return deviceID
        } else {
            print("MTMR: Failed to get default audio device: \(status)")
            return AudioObjectID(0)
        }
    }
    
    private func addAudioRouteChangedListener() {
        let audioId = AudioObjectID(bitPattern: kAudioObjectSystemObject)
        var forPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        let status = AudioObjectAddPropertyListenerBlock(audioId, &forPropertyAddress, nil, audioRouteChanged)
        if status != noErr {
            print("MTMR: Failed to add audio route change listener: \(status)")
        }
    }
    
    func audioRouteChanged(numberAddresses _: UInt32, addresses _: UnsafePointer<AudioObjectPropertyAddress>) {
        print("MTMR: Audio route changed, reinitializing volume control")
        
        // Clear audio device cache
        audioDeviceCache.removeAll()
        
        removeLastAudioVolumeChangeListener()
        currentDeviceId = getDefaultAudioDevice()
        addCurrentAudioVolumeChangedListener()
        
        let currentVolume = getCurrentVolume()
        performOnMainThread {
            self.sliderItem.floatValue = currentVolume * 100
        }
    }
    
    private func addCurrentAudioVolumeChangeListener() {
        guard currentDeviceId != AudioObjectID(0) else { return }
        
        var forPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )

        let status = AudioObjectAddPropertyListenerBlock(currentDeviceId, &forPropertyAddress, nil, audioObjectPropertyListenerBlock)
        if status != noErr {
            print("MTMR: Failed to add volume change listener: \(status)")
        }
    }
    
    private func removeLastAudioVolumeChangeListener() {
        guard currentDeviceId != AudioObjectID(0) else { return }
        
        var forPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )

        AudioObjectRemovePropertyListenerBlock(currentDeviceId, &forPropertyAddress, nil, audioObjectPropertyListenerBlock)
    }

    func audioObjectPropertyListenerBlock(numberAddresses _: UInt32, addresses _: UnsafePointer<AudioObjectPropertyAddress>) {
        let currentVolume = getCurrentVolume()
        performOnMainThread {
            self.sliderItem.floatValue = currentVolume * 100
        }
    }

    @objc func sliderValueChanged(_ sender: Any) {
        if let sliderItem = sender as? NSSlider {
            let newVolume = Float32(sliderItem.intValue) / 100.0
            
            // Cache the new volume value
            cacheValue(newVolume, forKey: "lastSetVolume", expiry: 60) // Cache for 1 minute
            
            let status = setVolume(newVolume)
            
            if status != noErr {
                print("MTMR: Failed to set volume: \(status)")
                // Revert slider to current system volume
                let currentVolume = getCurrentVolume()
                performOnMainThread {
                    self.sliderItem.floatValue = currentVolume * 100
                }
            }
        }
    }
    
    private func getCurrentVolume() -> Float32 {
        guard currentDeviceId != AudioObjectID(0) else { return 0.5 }
        
        // Check cache first
        if let cachedVolume = getCachedValue(forKey: "currentVolume") as? Float32 {
            return cachedVolume
        }
        
        var volume: Float32 = 0.5
        var size: UInt32 = UInt32(MemoryLayout.size(ofValue: volume))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        let status = AudioObjectGetPropertyData(currentDeviceId, &address, 0, nil, &size, &volume)
        
        if status == noErr {
            // Cache the result
            cacheValue(volume, forKey: "currentVolume", expiry: 30) // Cache for 30 seconds
            return volume
        } else {
            print("MTMR: Failed to get volume: \(status)")
            return 0.5
        }
    }

    private func setVolume(_ volume: Float32) -> OSStatus {
        guard currentDeviceId != AudioObjectID(0) else { return -1 }
        
        var inputVolume: Float32 = volume

        if inputVolume == 0.0 {
            _ = setMute(mute: 1)
        } else {
            _ = setMute(mute: 0)
        }

        let size: UInt32 = UInt32(MemoryLayout.size(ofValue: inputVolume))
        var address = AudioObjectPropertyAddress(
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster,
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume
        )
        
        let status = AudioObjectSetPropertyData(currentDeviceId, &address, 0, nil, size, &inputVolume)
        
        if status == noErr {
            // Update cache
            cacheValue(volume, forKey: "currentVolume", expiry: 30)
        } else {
            print("MTMR: Failed to set volume: \(status)")
        }
        
        return status
    }

    private func setMute(mute: Int) -> OSStatus {
        guard currentDeviceId != AudioObjectID(0) else { return -1 }
        
        var muteVal: Int = mute
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyMute)
        )
        let size: UInt32 = UInt32(MemoryLayout.size(ofValue: muteVal))
        address.mScope = AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput)
        address.mElement = AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        
        let status = AudioObjectSetPropertyData(currentDeviceId, &address, 0, nil, size, &muteVal)
        
        if status != noErr {
            print("MTMR: Failed to set mute: \(status)")
        }
        
        return status
    }
    
    // MARK: - Enhanced Widget Base Override
    
    override func updateWidget() {
        // Only update if we have a valid device
        guard currentDeviceId != AudioObjectID(0) else { return }
        
        let currentVolume = getCurrentVolume()
        performOnMainThread {
            self.sliderItem.floatValue = currentVolume * 100
        }
    }
    
    override func cleanup() {
        removeLastAudioVolumeChangeListener()
        audioDeviceCache.removeAll()
    }
}
