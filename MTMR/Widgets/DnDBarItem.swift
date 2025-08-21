//
//  DnDBarItem.swift
//  MTMR
//
//  Created by Anton Palgunov on 29/08/2018.
//  Copyright © 2018 Anton Palgunov. All rights reserved.
//

import Foundation

class DnDBarItem: CustomButtonTouchBarItem {
    private var timer: Timer!

    init(identifier: NSTouchBarItem.Identifier) {
        super.init(identifier: identifier, title: "")
        isBordered = false
        setWidth(value: 32)

        actions.append(ItemAction(trigger: .singleTap) { [weak self] in self?.DnDToggle() })

        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)

        refresh()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func DnDToggle() {
        print("MTMR: DND widget - Toggling DND status")
        NSLog("MTMR: DND widget - Toggling DND status")
        let newStatus = !DoNotDisturb.isEnabled
        DoNotDisturb.isEnabled = newStatus
        print("MTMR: DND widget - DND status set to: \(newStatus)")
        NSLog("MTMR: DND widget - DND status set to: \(newStatus)")
        refresh()
    }

    @objc func refresh() {
        let isEnabled = DoNotDisturb.isEnabled
        print("MTMR: DND widget - Refreshing, current status: \(isEnabled)")
        image = isEnabled ? #imageLiteral(resourceName: "dnd-on") : #imageLiteral(resourceName: "dnd-off")
    }
}

public struct DoNotDisturb {
    @MainActor private static let appId = "com.apple.notificationcenterui" as CFString
    private static let dndPref = "com.apple.notificationcenterui.dndprefs_changed"

    @MainActor private static func set(_ key: String, value: CFPropertyList?) {
        print("MTMR: DND widget - Setting preference '\(key)' to: \(String(describing: value))")
        CFPreferencesSetValue(key as CFString, value, appId, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
    }

    @MainActor private static func commitChanges() {
        print("MTMR: DND widget - Committing DND changes to system")
        
        // Synchronize preferences
        let syncResult = CFPreferencesSynchronize(appId, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        print("MTMR: DND widget - Preferences sync result: \(syncResult)")
        
        // Post notification to system
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(dndPref), object: nil, userInfo: nil, deliverImmediately: true)
        print("MTMR: DND widget - Posted DND change notification")
        
        // Restart notification center to apply changes
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: appId as String)
        if let notificationCenter = runningApps.first {
            print("MTMR: DND widget - Terminating notification center to apply changes")
            notificationCenter.terminate()
        } else {
            print("MTMR: DND widget - Notification center not running, changes will apply on next launch")
        }
    }

    @MainActor private static func enable() {
        print("MTMR: DND widget - Enabling Do Not Disturb")
        set("dndStart", value: nil)
        set("dndEnd", value: nil)
        set("doNotDisturb", value: true as CFPropertyList)
        set("doNotDisturbDate", value: Date() as CFPropertyList)
        commitChanges()
    }

    @MainActor private static func disable() {
        print("MTMR: DND widget - Disabling Do Not Disturb")
        set("dndStart", value: nil)
        set("dndEnd", value: nil)
        set("doNotDisturb", value: false as CFPropertyList)
        set("doNotDisturbDate", value: nil)
        commitChanges()
    }

    @MainActor static var isEnabled: Bool {
        get {
            let status = CFPreferencesGetAppBooleanValue("doNotDisturb" as CFString, appId, nil)
            print("MTMR: DND widget - Current DND status: \(status)")
            return status
        }
        set {
            print("MTMR: DND widget - Setting DND status to: \(newValue)")
            newValue ? enable() : disable()
        }
    }
}
