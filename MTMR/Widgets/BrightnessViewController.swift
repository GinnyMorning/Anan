import AppKit
import AVFoundation
import Cocoa
import CoreAudio

class BrightnessViewController: NSCustomTouchBarItem {
    private(set) var sliderItem: CustomSlider!
    private var isInitialized = false

    init(identifier: NSTouchBarItem.Identifier, refreshInterval: Double, image: NSImage? = nil) {
        super.init(identifier: identifier)

        if image == nil {
            sliderItem = CustomSlider()
        } else {
            sliderItem = CustomSlider(knob: image!)
        }
        sliderItem.target = self
        sliderItem.action = #selector(BrightnessViewController.sliderValueChanged(_:))
        sliderItem.minValue = 0.0
        sliderItem.maxValue = 100.0

        view = sliderItem

        // Initialize brightness control
        initializeBrightnessControl()
        
        // Set up timer for updates
        let timer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(BrightnessViewController.updateBrightnessSlider), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        sliderItem.unbind(NSBindingName.value)
    }
    
    private func initializeBrightnessControl() {
        let currentBrightness = getBrightness()
        
        DispatchQueue.main.async {
            self.sliderItem.floatValue = currentBrightness * 100
        }
        
        isInitialized = true
    }

    @objc func updateBrightnessSlider() {
        guard isInitialized else { return }
        
        DispatchQueue.main.async {
            let currentBrightness = self.getBrightness()
            self.sliderItem.floatValue = currentBrightness * 100
        }
    }

    @objc func sliderValueChanged(_ sender: Any) {
        if let sliderItem = sender as? NSSlider {
            let newBrightness = Float32(sliderItem.intValue) / 100.0
            let success = setBrightness(level: newBrightness)
            
            if !success {
                print("MTMR: Failed to set brightness, reverting slider")
                // Revert slider to current system brightness
                let currentBrightness = getBrightness()
                DispatchQueue.main.async {
                    self.sliderItem.floatValue = currentBrightness * 100
                }
            }
        }
    }

    private func getBrightness() -> Float32 {
        // Use only IOKit method to avoid CoreDisplay error spam
        var level: Float32 = 0.5
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        
        if service != 0 {
            let status = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &level)
            IOObjectRelease(service)
            
            if status == kIOReturnSuccess {
                return level
            }
        }
        
        // Return current slider value as fallback to prevent constant errors
        return sliderItem.floatValue / 100.0
    }

    private func setBrightness(level: Float) -> Bool {
        // Use only IOKit method to avoid CoreDisplay error spam
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        
        if service != 0 {
            let status = IODisplaySetFloatParameter(service, 1, kIODisplayBrightnessKey as CFString, level)
            IOObjectRelease(service)
            
            if status == kIOReturnSuccess {
                return true
            }
        }
        
        return false
    }
}
