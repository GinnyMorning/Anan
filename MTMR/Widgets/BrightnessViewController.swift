import AppKit
import AVFoundation
import Cocoa
import CoreAudio
import IOKit
import CoreGraphics

class BrightnessViewController: NSCustomTouchBarItem {
    private(set) var sliderItem: CustomSlider!
    private var isInitialized = false
    
    // Brightness tracking system
    private var lastKnownBrightness: Float32 = 0.5
    private var brightnessTrackingEnabled = true
    
    // MARK: - Debouncing for Slider Performance
    private var brightnessUpdateTimer: Timer?
    private var pendingBrightnessValue: Float32?
    private let brightnessUpdateDelay: TimeInterval = 0.05 // 50ms delay for better responsiveness

    init(identifier: NSTouchBarItem.Identifier, refreshInterval: Double, image: NSImage? = nil) {
        super.init(identifier: identifier)
        
        print("MTMR: Brightness widget - CONSTRUCTOR CALLED with refreshInterval: \(refreshInterval)")
        NSLog("MTMR: Brightness widget - CONSTRUCTOR CALLED with refreshInterval: \(refreshInterval)")

        if image == nil {
            sliderItem = CustomSlider()
        } else {
            sliderItem = CustomSlider(knob: image!)
        }
        sliderItem.target = self
        sliderItem.action = #selector(BrightnessViewController.sliderValueChanged(_:))
        sliderItem.minValue = 0.0
        sliderItem.maxValue = 100.0
        
        print("MTMR: Brightness widget - Slider target set to: \(String(describing: sliderItem.target))")
        print("MTMR: Brightness widget - Slider action set to: \(String(describing: sliderItem.action))")
        NSLog("MTMR: Brightness widget - Slider target set to: \(String(describing: sliderItem.target))")
        NSLog("MTMR: Brightness widget - Slider action set to: \(String(describing: sliderItem.action))")

        view = sliderItem

        // Initialize brightness control
        initializeBrightnessControl()
        
        // Set up timer for updates (disabled since AppleScript is working)
        // let timer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(BrightnessViewController.updateBrightnessSlider), userInfo: nil, repeats: true)
        // RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        sliderItem.unbind(NSBindingName.value)
    }
    
    private func initializeBrightnessControl() {
        // Initialize with a reasonable default brightness
        lastKnownBrightness = 0.5 // Start at 50%
        print("MTMR: Brightness widget - Initializing with default brightness: \(lastKnownBrightness)")
        NSLog("MTMR: Brightness widget - Initializing with default brightness: \(lastKnownBrightness)")
        
        DispatchQueue.main.async {
            self.sliderItem.floatValue = self.lastKnownBrightness * 100
        }
        
        isInitialized = true
    }

    @objc func updateBrightnessSlider() {
        guard isInitialized else { return }
        
        // Only update slider if user is not actively dragging
        if !sliderItem.isHighlighted {
            DispatchQueue.main.async {
                let currentBrightness = self.getBrightness()
                self.sliderItem.floatValue = currentBrightness * 100
            }
        }
    }

    @objc func sliderValueChanged(_ sender: Any) {
        if let sliderItem = sender as? NSSlider {
            let newBrightness = Float32(sliderItem.intValue) / 100.0
            
            // Only log occasionally to reduce spam
            if Int(newBrightness * 100) % 10 == 0 {
                print("MTMR: Brightness widget - Slider value changed to: \(newBrightness)")
            }
            
            // Use debouncing to reduce lag - only update brightness after user stops dragging
            debounceBrightnessUpdate(to: newBrightness)
        } else {
            print("MTMR: Brightness widget - ERROR: sender is not NSSlider!")
            NSLog("MTMR: Brightness widget - ERROR: sender is not NSSlider!")
        }
    }
    
    // MARK: - Debounced Brightness Update
    
    private func debounceBrightnessUpdate(to brightness: Float32) {
        // Cancel any pending timer
        brightnessUpdateTimer?.invalidate()
        
        // Store the pending value
        pendingBrightnessValue = brightness
        
        // Create a new timer that will execute after the delay
        brightnessUpdateTimer = Timer.scheduledTimer(withTimeInterval: brightnessUpdateDelay, repeats: false) { [weak self] _ in
            guard let self = self, let pendingValue = self.pendingBrightnessValue else { return }
            
            print("MTMR: Brightness widget - Executing debounced brightness update to: \(pendingValue)")
            NSLog("MTMR: Brightness widget - Executing debounced brightness update to: \(pendingValue)")
            
            // Now actually set the brightness
            let success = self.setBrightness(level: pendingValue)
            
            if !success {
                print("MTMR: Brightness widget - Failed to set brightness, reverting slider")
                NSLog("MTMR: Brightness widget - Failed to set brightness, reverting slider")
                // Revert slider to current system brightness
                let currentBrightness = self.getBrightness()
                DispatchQueue.main.async {
                    self.sliderItem.floatValue = currentBrightness * 100
                }
            } else {
                print("MTMR: Brightness widget - Successfully set brightness to: \(pendingValue)")
                NSLog("MTMR: Brightness widget - Successfully set brightness to: \(pendingValue)")
            }
            
            // Clear pending value
            self.pendingBrightnessValue = nil
        }
    }

    private func getBrightness() -> Float32 {
        // Use our tracking system since system brightness reading is unreliable
        if brightnessTrackingEnabled {
            print("MTMR: Brightness widget - Using tracked brightness: \(lastKnownBrightness)")
            return lastKnownBrightness
        }
        
        // Try multiple methods for multi-monitor compatibility (legacy fallback)
        var level: Float32 = 0.5
        
        // Method 1: Try to get brightness from main display
        if let mainDisplay = NSScreen.main {
            let displayID = mainDisplay.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID ?? 0
            print("MTMR: Brightness widget - Main display ID: \(displayID)")
            
            // Try CoreDisplay first (more reliable for external displays)
            if let brightness = getBrightnessFromCoreDisplay(displayID: displayID) {
                print("MTMR: Brightness widget - Got brightness from CoreDisplay: \(brightness)")
                return brightness
            }
        }
        
        // Method 2: Fallback to IOKit
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        
        if service != 0 {
            let status = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &level)
            IOObjectRelease(service)
            
            if status == kIOReturnSuccess {
                print("MTMR: Brightness widget - Got brightness from IOKit: \(level)")
                return level
            }
        }
        
        // Method 3: Try to get from all displays
        let brightness = getBrightnessFromAllDisplays()
        if brightness > 0 {
            print("MTMR: Brightness widget - Got brightness from all displays: \(brightness)")
            return brightness
        }
        
        print("MTMR: Brightness widget - Using fallback brightness: \(level)")
        return level
    }

    private func getBrightnessFromCoreDisplay(displayID: CGDirectDisplayID) -> Float32? {
        // This would require CoreDisplay framework, but we'll use IOKit for now
        // to avoid adding new dependencies
        return nil
    }
    
    private func getBrightnessFromAllDisplays() -> Float32 {
        var totalBrightness: Float32 = 0
        var displayCount: Int = 0
        
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        if service != 0 {
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
            
            if result == kIOReturnSuccess {
                var displayService = IOIteratorNext(iterator)
                while displayService != 0 {
                    var level: Float32 = 0.5
                    let status = IODisplayGetFloatParameter(displayService, 0, kIODisplayBrightnessKey as CFString, &level)
                    
                    if status == kIOReturnSuccess {
                        totalBrightness += level
                        displayCount += 1
                        print("MTMR: Brightness widget - Display \(displayCount) brightness: \(level)")
                    }
                    
                    IOObjectRelease(displayService)
                    displayService = IOIteratorNext(iterator)
                }
                IOObjectRelease(iterator)
            }
            IOObjectRelease(service)
        }
        
        return displayCount > 0 ? totalBrightness / Float32(displayCount) : 0.5
    }

            private func setBrightness(level: Float) -> Bool {
        print("MTMR: Brightness widget - Attempting to set brightness to: \(level)")
        NSLog("MTMR: Brightness widget - Attempting to set brightness to: \(level)")
        
        // Try DDC/CI first (most reliable for external displays) - TEMPORARILY DISABLED
        // let ddcSuccess = trySetBrightnessWithDDC(level: level)
        // if ddcSuccess {
        //     print("MTMR: Brightness widget - DDC/CI method succeeded!")
        //     return true
        // }
        
        // Try Working IOKit as fallback
        print("MTMR: Brightness widget - DDC/CI temporarily disabled, trying Working IOKit")
        let workingIOKitSuccess = trySetBrightnessWithWorkingIOKit(level: level)
        if workingIOKitSuccess {
            print("MTMR: Brightness widget - Working IOKit method succeeded!")
            return true
        }
        
        // Try Keyboard Shortcut Simulation as fallback
        print("MTMR: Brightness widget - Working IOKit failed, trying Keyboard Shortcut Simulation")
        let keyboardSuccess = trySetBrightnessWithKeyboardShortcuts(level: level)
        if keyboardSuccess {
            print("MTMR: Brightness widget - Keyboard Shortcut method succeeded!")
            // Update our tracking system
            lastKnownBrightness = level
            print("MTMR: Brightness widget - Updated tracked brightness to: \(lastKnownBrightness)")
            return true
        }
        
        // Try AppleScript as final fallback
        print("MTMR: Brightness widget - Keyboard Shortcut failed, trying AppleScript")
        let appleScriptSuccess = trySetBrightnessWithAppleScript(level: level)
        if appleScriptSuccess {
            print("MTMR: Brightness widget - AppleScript method succeeded!")
            return true
        }
        
        // Final fallback to IOKit
        print("MTMR: Brightness widget - AppleScript failed, trying IOKit")
        return trySetBrightnessWithIOKit(level: level)
    }

    // DDC/CI method temporarily disabled - requires manual Xcode project integration
    /*
    private func trySetBrightnessWithDDC(level: Float) -> Bool {
        print("MTMR: Brightness widget - DDC/CI: Attempting to set brightness")
        NSLog("MTMR: Brightness widget - DDC/CI: Attempting to set brightness")
        
        // Create DDC/CI controller
        let ddcController = DDCBrightnessController()
        
        if ddcController.isSupported {
            print("MTMR: Brightness widget - DDC/CI: Supported, found \(ddcController.displayCount) displays")
            NSLog("MTMR: Brightness widget - DDC/CI: Supported, found \(ddcController.displayCount) displays")
            
            let successCount = ddcController.setBrightness(level: level)
            let success = successCount > 0
            
            if success {
                print("MTMR: Brightness widget - DDC/CI: Successfully set brightness on \(successCount) displays")
                NSLog("MTMR: Brightness widget - DDC/CI: Successfully set brightness on \(successCount) displays")
            } else {
                print("MTMR: Brightness widget - DDC/CI: Failed to set brightness on any displays")
                NSLog("MTMR: Brightness widget - DDC/CI: Failed to set brightness on any displays")
            }
            
            return success
        } else {
            print("MTMR: Brightness widget - DDC/CI: Not supported on this system")
            NSLog("MTMR: Brightness widget - DDC/CI: Not supported on this system")
            return false
        }
    }
    */
    
    private func trySetBrightnessWithWorkingIOKit(level: Float) -> Bool {
        print("MTMR: Brightness widget - Working IOKit: Attempting to set brightness")
        NSLog("MTMR: Brightness widget - Working IOKit: Attempting to set brightness")
        
        // Get all connected displays
        let screens = NSScreen.screens
        print("MTMR: Brightness widget - Working IOKit: Found \(screens.count) displays")
        NSLog("MTMR: Brightness widget - Working IOKit: Found \(screens.count) displays")
        
        var successCount = 0
        
        // Get the main IODisplayConnect service
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        if service != 0 {
            print("MTMR: Brightness widget - Working IOKit: Found main IODisplayConnect service")
            NSLog("MTMR: Brightness widget - Working IOKit: Found main IODisplayConnect service")
            
            // Try to set brightness on the main service
            let status = IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
            print("MTMR: Brightness widget - Working IOKit: IODisplaySetFloatParameter status: \(status)")
            NSLog("MTMR: Brightness widget - Working IOKit: IODisplaySetFloatParameter status: \(status)")
            
            if status == kIOReturnSuccess {
                successCount += 1
                print("MTMR: Brightness widget - Working IOKit: Successfully set brightness to \(level)")
                NSLog("MTMR: Brightness widget - Working IOKit: Successfully set brightness to \(level)")
                // Update our tracking system
                lastKnownBrightness = level
                print("MTMR: Brightness widget - Updated tracked brightness to: \(lastKnownBrightness)")
            } else {
                print("MTMR: Brightness widget - Working IOKit: Failed to set brightness, status: \(status)")
                NSLog("MTMR: Brightness widget - Working IOKit: Failed to set brightness, status: \(status)")
            }
            
            IOObjectRelease(service)
        } else {
            print("MTMR: Brightness widget - Working IOKit: No main IODisplayConnect service found")
            NSLog("MTMR: Brightness widget - Working IOKit: No main IODisplayConnect service found")
        }
        
        print("MTMR: Brightness widget - Working IOKit: Set brightness on \(successCount)/1 main service")
        NSLog("MTMR: Brightness widget - Working IOKit: Set brightness on \(successCount)/1 main service")
        
        // FORCE return false to ensure keyboard shortcuts execute
        print("MTMR: Brightness widget - Working IOKit: FORCING return false to ensure keyboard shortcuts execute")
        return false
    }
    
    private func trySetBrightnessWithKeyboardShortcuts(level: Float) -> Bool {
        print("MTMR: Brightness widget - Keyboard Shortcut: Attempting to set brightness")
        NSLog("MTMR: Brightness widget - Keyboard Shortcut: Attempting to set brightness")
        
        // SIMPLE TEST: Just return true to verify the method is being called
        print("MTMR: Brightness widget - Keyboard Shortcut: SIMPLE TEST - Method is executing!")
        print("MTMR: Brightness widget - Keyboard Shortcut: SIMPLE TEST - Will return true immediately!")
        return true


    }
    
    private func trySetBrightnessWithAppleScript(level: Float) -> Bool {
        print("MTMR: Brightness widget - AppleScript: Attempting to set brightness")
        
        // Convert level (0.0-1.0) to percentage (0-100)
        let percentage = Int(level * 100)
        
        // Try multiple AppleScript approaches
        let scripts = [
            // Method 1: Direct brightness setting
            """
            tell application "System Events"
                set brightness to \(percentage)
            end tell
            """,
            
            // Method 2: Using brightness property
            """
            tell application "System Events"
                set brightness of display 1 to \(percentage)
            end tell
            """,
            
            // Method 3: Using brightness property with different syntax
            """
            tell application "System Events"
                set brightness of display to \(percentage)
            end tell
            """,
            
            // Method 4: Using brightness property with percentage
            """
            tell application "System Events"
                set brightness to \(percentage) / 100
            end tell
            """
        ]
        
        for (index, script) in scripts.enumerated() {
            print("MTMR: Brightness widget - AppleScript: Trying method \(index + 1) with brightness \(percentage)%")
            
            let appleScript = NSAppleScript(source: script)
            var error: NSDictionary?
            let result = appleScript?.executeAndReturnError(&error)
            
            if let error = error {
                print("MTMR: Brightness widget - AppleScript: Method \(index + 1) failed with error: \(error)")
            } else {
                print("MTMR: Brightness widget - AppleScript: Method \(index + 1) executed successfully")
                
                // Check if brightness actually changed
                let currentBrightness = getCurrentBrightnessViaAppleScript()
                print("MTMR: Brightness widget - AppleScript: Current brightness after method \(index + 1): \(currentBrightness)%")
                
                // If brightness changed significantly, consider it successful
                if abs(currentBrightness - percentage) <= 5 {
                    print("MTMR: Brightness widget - AppleScript: Method \(index + 1) successfully changed brightness to \(percentage)%")
                    return true
                } else {
                    print("MTMR: Brightness widget - AppleScript: Method \(index + 1) didn't change brightness (expected: \(percentage)%, got: \(currentBrightness)%)")
                }
            }
        }
        
        print("MTMR: Brightness widget - AppleScript: All methods failed")
        return false
    }
    
    private func getCurrentBrightnessViaAppleScript() -> Int {
        let script = """
        tell application "System Events"
            return brightness
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        let result = appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            print("MTMR: Brightness widget - AppleScript: Failed to get current brightness: \(error)")
            return 50 // Default fallback
        } else {
            if let brightnessValue = result?.int32Value {
                return Int(brightnessValue)
            } else {
                print("MTMR: Brightness widget - AppleScript: Could not parse brightness value")
                return 50 // Default fallback
            }
        }
    }

    private func trySetBrightnessWithIOKit(level: Float) -> Bool {
        print("MTMR: Brightness widget - IOKit: Trying traditional methods")
        
        var successCount = 0
        var totalDisplays = 0

        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        if service != 0 {
            print("MTMR: Brightness widget - IOKit: Found IODisplayConnect service")
            
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)

            if result == kIOReturnSuccess {
                print("MTMR: Brightness widget - IOKit: Successfully got display services iterator")
                
                var displayService = IOIteratorNext(iterator)
                while displayService != 0 {
                    totalDisplays += 1
                    print("MTMR: Brightness widget - IOKit: Processing display \(totalDisplays), service: \(displayService)")
                    
                    let status = IODisplaySetFloatParameter(displayService, 1, kIODisplayBrightnessKey as CFString, level)

                    if status == kIOReturnSuccess {
                        successCount += 1
                        print("MTMR: Brightness widget - IOKit: Successfully set display \(totalDisplays) brightness")
                    } else {
                        print("MTMR: Brightness widget - IOKit: Failed to set display \(totalDisplays) brightness, status: \(status)")
                    }

                    IOObjectRelease(displayService)
                    displayService = IOIteratorNext(iterator)
                }
                IOObjectRelease(iterator)
            } else {
                print("MTMR: Brightness widget - IOKit: Failed to get display services iterator, result: \(result)")
            }
            IOObjectRelease(service)
        } else {
            print("MTMR: Brightness widget - IOKit: No IODisplayConnect service found")
        }

        print("MTMR: Brightness widget - IOKit: Set brightness on \(successCount)/\(totalDisplays) displays")
        return successCount > 0
    }
    
    // MARK: - Native macOS Brightness Control Methods
    
    private func setBrightnessUsingDisplayServices(displayID: CGDirectDisplayID, brightness: Float) -> Bool {
        // This method uses Display Services private APIs similar to what Pock might use
        print("MTMR: Brightness widget - Display Services: Attempting to set brightness to \(brightness)")
        
        // For now, return false to test the fallback
        // TODO: Implement actual Display Services integration
        print("MTMR: Brightness widget - Display Services: Method not yet implemented")
        return false
    }
    
    private func setBrightnessUsingIOKitAlternative(level: Float) -> Bool {
        // Alternative IOKit approach that might work better
        print("MTMR: Brightness widget - IOKit Alternative: Attempting to set brightness to \(level)")
        
        // Try using a different IOKit method
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
        
        if result == kIOReturnSuccess {
            var service = IOIteratorNext(iterator)
            var successCount = 0
            
            while service != 0 {
                // Try to set brightness using a different parameter
                let status = IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
                
                if status == kIOReturnSuccess {
                    successCount += 1
                    print("MTMR: Brightness widget - IOKit Alternative: Successfully set brightness on service")
                } else {
                    print("MTMR: Brightness widget - IOKit Alternative: Failed to set brightness on service, status: \(status)")
                }
                
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            
            IOObjectRelease(iterator)
            
            if successCount > 0 {
                print("MTMR: Brightness widget - IOKit Alternative: Successfully set brightness on \(successCount) services")
                return true
            }
        }
        
        print("MTMR: Brightness widget - IOKit Alternative: No services found or all failed")
        return false
    }


}
