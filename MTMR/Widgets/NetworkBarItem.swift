//
//  NetworkBarItem.swift
//  MTMR
//
//  Created by Anton Palgunov on 23/02/2019.
//  Copyright © 2019 Anton Palgunov. All rights reserved.
//

import Foundation

@MainActor
class NetworkBarItem: CustomButtonTouchBarItem, @preconcurrency Widget {
    static var name: String = "network"
    static var identifier: String = "com.toxblh.mtmr.network"
    
    private let flip: Bool
    private let units: String
    private var dataAvailableObserver: NSObjectProtocol?
    private var dataReadyObserver: NSObjectProtocol?
    
    init(identifier: NSTouchBarItem.Identifier, flip: Bool = false, units: String) {
        self.flip = flip
        self.units = units
        super.init(identifier: identifier, title: " ")
        startMonitoringProcess()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Note: Cannot access @MainActor properties in deinit
        // The observers will be cleaned up automatically when the object is deallocated
    }

    func startMonitoringProcess() {
        let pipe = Pipe()
        let bandwidthProcess = Process()
        bandwidthProcess.launchPath = "/usr/bin/env"
        bandwidthProcess.arguments = ["netstat", "-w1", "-l", "en0"]
        bandwidthProcess.standardOutput = pipe

        let outputHandle = pipe.fileHandleForReading
        outputHandle.waitForDataInBackgroundAndNotify(forModes: [RunLoop.Mode.common])

        // Capture weak self to avoid retain cycles
        dataAvailableObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: outputHandle,
            queue: nil
        ) { [weak self] _ -> Void in
            guard let self = self else { return }
            
            let data = pipe.fileHandleForReading.availableData
            if data.count > 0 {
                if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    // Process data in background and then update UI on main actor
                    let processedData = str
                        .replacingOccurrences(of: "  ", with: " ")
                        .split(separator: " ")
                    
                    if processedData.count >= 6,
                       let downSpeed = UInt64(processedData[2]),
                       let upSpeed = UInt64(processedData[5]) {
                        
                        // Update UI on main actor
                        DispatchQueue.main.async {
                            self.updateNetworkSpeeds(upSpeed: upSpeed, downSpeed: downSpeed)
                        }
                    }
                }
                outputHandle.waitForDataInBackgroundAndNotify()
            } else {
                // Clean up observer when no more data
                DispatchQueue.main.async {
                    self.cleanupDataAvailableObserver()
                }
            }
        }

        dataReadyObserver = NotificationCenter.default.addObserver(
            forName: Process.didTerminateNotification,
            object: outputHandle,
            queue: nil
        ) { [weak self] _ -> Void in
            print("Task terminated!")
            DispatchQueue.main.async {
                self?.cleanupDataReadyObserver()
            }
        }

        bandwidthProcess.launch()
    }
    
    private func updateNetworkSpeeds(upSpeed: UInt64, downSpeed: UInt64) {
        let upSpeedText = getHumanizeSize(speed: upSpeed)
        let downSpeedText = getHumanizeSize(speed: downSpeed)
        setTitle(up: upSpeedText, down: downSpeedText)
    }
    
    private func cleanupDataAvailableObserver() {
        if let observer = dataAvailableObserver {
            NotificationCenter.default.removeObserver(observer)
            dataAvailableObserver = nil
        }
    }
    
    private func cleanupDataReadyObserver() {
        if let observer = dataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
            dataReadyObserver = nil
        }
    }

    func getHumanizeSize(speed: UInt64) -> String {
        let humanText: String
        
        func speedB(speed: UInt64)-> String {
            return String(format: "%.0f", Double(speed)) + " B/s"
        }
        
        func speedKB(speed: UInt64)-> String {
            return String(format: "%.1f", Double(speed) / 1024) + " KB/s"
        }
        
        func speedMB(speed: UInt64)-> String {
            return String(format: "%.1f", Double(speed) / (1024 * 1024)) + " MB/s"
        }
        
        func speedGB(speed: UInt64)-> String {
            return String(format: "%.2f", Double(speed) / (1024 * 1024 * 1024)) + " GB/s"
        }
        
        switch self.units {
        case "B/s":
            humanText = speedB(speed: speed)
        case "KB/s":
            humanText = speedKB(speed: speed)
        case "MB/s":
            humanText = speedMB(speed: speed)
        case "GB/s":
            humanText = speedGB(speed: speed)
        default:
            if speed < 1024 {
                humanText = speedB(speed: speed)
            } else if speed < (1024 * 1024) {
                humanText = speedKB(speed: speed)
            } else if speed < (1024 * 1024 * 1024) {
                humanText = speedMB(speed: speed)
            } else {
                humanText = speedGB(speed: speed)
            }
        }

        return humanText
    }
    
    func appendUpSpeed(appendString: NSMutableAttributedString, up: String, titleFont: NSFont, newStr: Bool = false) {
        appendString.append(NSMutableAttributedString(
            string: newStr ? "\n↑" : "↑",
            attributes: [
                NSAttributedString.Key.foregroundColor: NSColor.blue,
                NSAttributedString.Key.font: titleFont,
                ]))
        
        appendString.append(NSMutableAttributedString(
            string: up,
            attributes: [
                NSAttributedString.Key.font: titleFont,
                ]))
    }
    
    func appendDownSpeed(appendString: NSMutableAttributedString, down: String, titleFont: NSFont, newStr: Bool = false) {
        appendString.append(NSMutableAttributedString(
            string: newStr ? "\n↓" : "↓",
            attributes: [
                NSAttributedString.Key.foregroundColor: NSColor.red,
                NSAttributedString.Key.font: titleFont,
                ]))
            
            appendString.append(NSMutableAttributedString(
                string: down,
                attributes: [
                    NSAttributedString.Key.font: titleFont
                ]))
    }
    
    func setTitle(up: String, down: String) {
        let titleFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: NSFont.Weight.light)
        
        let newTitle: NSMutableAttributedString = NSMutableAttributedString(string: "")
        
        if (self.flip) {
            appendUpSpeed(appendString: newTitle, up: up, titleFont: titleFont)
            appendDownSpeed(appendString: newTitle, down: down, titleFont: titleFont, newStr: true)
        } else {
            appendDownSpeed(appendString: newTitle, down: down, titleFont: titleFont)
            appendUpSpeed(appendString: newTitle, up: up, titleFont: titleFont, newStr: true)
        }
        
        
        self.attributedTitle = newTitle
    }
}
