import AppKit
import AVFoundation
import Cocoa
import CoreAudio

class VolumeViewController: NSCustomTouchBarItem {
    private(set) var sliderItem: CustomSlider!
    private var currentDeviceId: AudioObjectID = AudioObjectID(0)
    private var isInitialized = false

    init(identifier: NSTouchBarItem.Identifier, image: NSImage? = nil) {
        super.init(identifier: identifier)

        if image == nil {
            sliderItem = CustomSlider()
        } else {
            sliderItem = CustomSlider(knob: image!)
        }
        sliderItem.target = self
        sliderItem.action = #selector(VolumeViewController.sliderValueChanged(_:))
        sliderItem.minValue = 0.0
        sliderItem.maxValue = 100.0

        view = sliderItem
        
        // Initialize volume control
        initializeVolumeControl()
    }
    
    private func initializeVolumeControl() {
        currentDeviceId = defaultDeviceID
        
        if currentDeviceId != AudioObjectID(0) {
            print("MTMR: Volume control initialized with device ID: \(currentDeviceId)")
            isInitialized = true
            
            // Set initial slider value
            let currentVolume = getInputGain()
            DispatchQueue.main.async {
                self.sliderItem.floatValue = currentVolume * 100
            }
            
            // Add listeners
            self.addAudioRouteChangedListener()
            self.addCurrentAudioVolumeChangeListener()
        } else {
            print("MTMR: Failed to initialize volume control - no valid audio device")
            DispatchQueue.main.async {
                self.sliderItem.floatValue = 50.0 // Default to 50%
            }
        }
    }
    
    private func addAudioRouteChangedListener() {
        let audioId = AudioObjectID(bitPattern: kAudioObjectSystemObject)
        var forPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster)
        
        let status = AudioObjectAddPropertyListenerBlock(audioId, &forPropertyAddress, nil, audioRouteChanged)
        if status != noErr {
            print("MTMR: Failed to add audio route change listener: \(status)")
        }
    }
    

    func audioRouteChanged(numberAddresses _: UInt32, addresses _: UnsafePointer<AudioObjectPropertyAddress>) {
        print("MTMR: Audio route changed, reinitializing volume control")
        self.removeLastAudioVolumeChangeListener()
        currentDeviceId = defaultDeviceID
        self.addCurrentAudioVolumeChangeListener()
        
        let currentVolume = getInputGain()
        DispatchQueue.main.async {
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
        let currentVolume = getInputGain()
        DispatchQueue.main.async {
            self.sliderItem.floatValue = currentVolume * 100
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        sliderItem.unbind(NSBindingName.value)
    }

    @objc func sliderValueChanged(_ sender: Any) {
        if let sliderItem = sender as? NSSlider {
            let newVolume = Float32(sliderItem.intValue) / 100.0
            let status = setInputGain(newVolume)
            
            if status != noErr {
                print("MTMR: Failed to set volume: \(status)")
                // Revert slider to current system volume
                let currentVolume = getInputGain()
                DispatchQueue.main.async {
                    self.sliderItem.floatValue = currentVolume * 100
                }
            }
        }
    }

    private var defaultDeviceID: AudioObjectID {
        var deviceID: AudioObjectID = AudioObjectID(0)
        var size: UInt32 = UInt32(MemoryLayout<AudioObjectID>.size)
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice)
        address.mScope = AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal)
        address.mElement = AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        if status != noErr {
            print("MTMR: Failed to get default audio device: \(status)")
            return AudioObjectID(0)
        }
        
        return deviceID
    }

    private func getInputGain() -> Float32 {
        guard currentDeviceId != AudioObjectID(0) else { return 0.5 }
        
        var volume: Float32 = 0.5
        var size: UInt32 = UInt32(MemoryLayout.size(ofValue: volume))
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = AudioObjectPropertySelector(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
        address.mScope = AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput)
        address.mElement = AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        
        let status = AudioObjectGetPropertyData(currentDeviceId, &address, 0, nil, &size, &volume)
        if status != noErr {
            print("MTMR: Failed to get volume: \(status)")
            return 0.5
        }
        
        return volume
    }

    private func setInputGain(_ volume: Float32) -> OSStatus {
        guard currentDeviceId != AudioObjectID(0) else { return -1 }
        
        var inputVolume: Float32 = volume

        if inputVolume == 0.0 {
            _ = setMute(mute: 1)
        } else {
            _ = setMute(mute: 0)
        }

        let size: UInt32 = UInt32(MemoryLayout.size(ofValue: inputVolume))
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mScope = AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput)
        address.mElement = AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        address.mSelector = AudioObjectPropertySelector(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
        
        let status = AudioObjectSetPropertyData(currentDeviceId, &address, 0, nil, size, &inputVolume)
        if status != noErr {
            print("MTMR: Failed to set volume: \(status)")
        }
        
        return status
    }

    private func setMute(mute: Int) -> OSStatus {
        guard currentDeviceId != AudioObjectID(0) else { return -1 }
        
        var muteVal: Int = mute
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = AudioObjectPropertySelector(kAudioDevicePropertyMute)
        let size: UInt32 = UInt32(MemoryLayout.size(ofValue: muteVal))
        address.mScope = AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput)
        address.mElement = AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        
        let status = AudioObjectSetPropertyData(currentDeviceId, &address, 0, nil, size, &muteVal)
        if status != noErr {
            print("MTMR: Failed to set mute: \(status)")
        }
        
        return status
    }
}
