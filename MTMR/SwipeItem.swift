//
//  SwipeItem.swift
//  MTMR
//
//  Created by Fedor Zaitsev on 3/29/20.
//  Copyright © 2020 Anton Palgunov. All rights reserved.
//

import Foundation
import Foundation

@MainActor
class SwipeItem: NSCustomTouchBarItem {
    private var scriptApple: NSAppleScript?
    private var scriptBash: String?
    private var direction: String
    private var fingers: Int
    private var minOffset: Float
    init?(identifier: NSTouchBarItem.Identifier, direction: String, fingers: Int, minOffset: Float, sourceApple: SourceProtocol?, sourceBash: SourceProtocol?) {
        self.direction = direction
        self.fingers = fingers
        self.scriptBash = sourceBash?.string
        self.scriptApple = sourceApple?.appleScript
        self.minOffset = minOffset
        super.init(identifier: identifier)
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func processEvent(offset: CGFloat, fingers: Int) {
        if direction == "right" && Float(offset) > self.minOffset && self.fingers == fingers {
            self.execute()
        }
        if direction == "left" && Float(offset) < -self.minOffset && self.fingers == fingers {
            self.execute()
        }
    }

    func execute() {
        if let scriptApple = scriptApple {
            let script = scriptApple // Capture the value
            DispatchQueue.appleScriptQueue.async {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                if let error = error {
                    print("SwipeItem apple script error: \(error)")
                    return
                }
            }
        }
        if let scriptBash = scriptBash {
            let script = scriptBash // Capture the value
            DispatchQueue.shellScriptQueue.async {
                let task = Process()
                if let shell = getenv("SHELL") {
                    task.launchPath = String.init(cString: shell)
                } else {
                    task.launchPath = "/bin/bash"
                }
                task.arguments = ["-c", script]
                task.launch()
                task.waitUntilExit()

                
                if (task.terminationStatus != 0) {
                    print("SwipeItem bash script error. Status: \(task.terminationStatus)")
                }
            }
        }
    }
    
    func isEqual(_ object: AnyObject?) -> Bool {
        if let object = object as? SwipeItem {
            return self.scriptApple?.source as String? == object.scriptApple?.source as String? && self.scriptBash == object.scriptBash && self.direction == object.direction && self.fingers == object.fingers && self.minOffset == object.minOffset
        } else {
            return false
        }
    }
}
