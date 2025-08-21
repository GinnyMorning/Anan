//
//  SettingsMigrationBridge.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  Bridge between legacy AppSettings and new ConcurrentAppSettings
//

import Foundation

/// Bridge class to facilitate migration from AppSettings to ConcurrentAppSettings
/// This allows both systems to coexist during the migration process
@MainActor
class SettingsMigrationBridge {
    static let shared = SettingsMigrationBridge()
    
    private var isMigrationComplete = false
    private var migrationStartTime: Date?
    
    private init() {
        // Check if migration has already been completed
        isMigrationComplete = UserDefaults.standard.bool(forKey: "com.toxblh.mtmr.migration.completed")
    }
    
    // MARK: - Migration Control
    
    /// Start the migration process
    func startMigration() async {
        guard !isMigrationComplete else {
            print("MTMR: Settings migration already completed")
            return
        }
        
        print("MTMR: Starting settings migration to Swift 6.0 architecture...")
        migrationStartTime = Date()
        
        do {
            // Perform the migration
            try await performMigration()
            
            // Mark migration as complete
            isMigrationComplete = true
            UserDefaults.standard.set(true, forKey: "com.toxblh.mtmr.migration.completed")
            
            print("MTMR: Settings migration completed successfully")
            
        } catch {
            print("MTMR: Settings migration failed: \(error)")
            // Migration failed, but we can continue using legacy settings
        }
    }
    
    /// Perform the actual migration
    private func performMigration() async throws {
        // Step 1: Copy all values from legacy AppSettings to ConcurrentAppSettings
        await copyLegacySettings()
        
        // Step 2: Verify the migration was successful
        try await verifyMigration()
        
        // Step 3: Log migration completion
        logMigrationCompletion()
    }
    
    /// Copy settings from legacy AppSettings to ConcurrentAppSettings
    private func copyLegacySettings() async {
        print("MTMR: Copying legacy settings...")
        
        // Access legacy settings (these are the old static properties)
        let legacySettings = AppSettings.self
        
        // Copy to new concurrent settings using the migration function
        await ConcurrentAppSettings.migrateFromLegacySettings()
        
        print("MTMR: Legacy settings copied successfully")
    }
    
    /// Verify that the migration was successful
    private func verifyMigration() async throws {
        print("MTMR: Verifying migration...")
        
        let legacySettings = AppSettings.self
        
        // Verify each setting was copied correctly
        let showControlStrip = await ConcurrentAppSettings.showControlStripState
        let hapticFeedback = await ConcurrentAppSettings.hapticFeedbackState
        let multitouchGestures = await ConcurrentAppSettings.multitouchGestures
        let blacklistedApps = await ConcurrentAppSettings.blacklistedAppIds
        let dockPersistentApps = await ConcurrentAppSettings.dockPersistentAppIds
        
        guard showControlStrip == legacySettings.showControlStripState else {
            throw MigrationError.verificationFailed("showControlStripState mismatch")
        }
        
        guard hapticFeedback == legacySettings.hapticFeedbackState else {
            throw MigrationError.verificationFailed("hapticFeedbackState mismatch")
        }
        
        guard multitouchGestures == legacySettings.multitouchGestures else {
            throw MigrationError.verificationFailed("multitouchGestures mismatch")
        }
        
        guard blacklistedApps == legacySettings.blacklistedAppIds else {
            throw MigrationError.verificationFailed("blacklistedAppIds mismatch")
        }
        
        guard dockPersistentApps == legacySettings.dockPersistentAppIds else {
            throw MigrationError.verificationFailed("dockPersistentAppIds mismatch")
        }
        
        print("MTMR: Migration verification successful")
    }
    
    /// Log migration completion details
    private func logMigrationCompletion() {
        guard let startTime = migrationStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        print("MTMR: Settings migration completed in \(String(format: "%.2f", duration)) seconds")
    }
    
    // MARK: - Settings Access (Migration-Aware)
    
    /// Get a setting value, using the new system if available, falling back to legacy
    func getSetting<T>(_ key: String, defaultValue: T) async -> T {
        if isMigrationComplete {
            // Use new concurrent settings
            switch key {
            case "showControlStrip":
                return await ConcurrentAppSettings.showControlStripState as! T
            case "hapticFeedback":
                return await ConcurrentAppSettings.hapticFeedbackState as! T
            case "multitouchGestures":
                return await ConcurrentAppSettings.multitouchGestures as! T
            case "blacklistedApps":
                return await ConcurrentAppSettings.blacklistedAppIds as! T
            case "dockPersistentApps":
                return await ConcurrentAppSettings.dockPersistentAppIds as! T
            default:
                return defaultValue
            }
        } else {
            // Use legacy settings
            switch key {
            case "showControlStrip":
                return AppSettings.showControlStripState as! T
            case "hapticFeedback":
                return AppSettings.hapticFeedbackState as! T
            case "multitouchGestures":
                return AppSettings.multitouchGestures as! T
            case "blacklistedApps":
                return AppSettings.blacklistedAppIds as! T
            case "dockPersistentApps":
                return AppSettings.dockPersistentAppIds as! T
            default:
                return defaultValue
            }
        }
    }
    
    /// Set a setting value, updating both systems during migration
    func setSetting<T>(_ key: String, value: T) async {
        if isMigrationComplete {
            // Update new concurrent settings
            switch key {
            case "showControlStrip":
                await ConcurrentAppSettings.showControlStripState = value as! Bool
            case "hapticFeedback":
                await ConcurrentAppSettings.hapticFeedbackState = value as! Bool
            case "multitouchGestures":
                await ConcurrentAppSettings.multitouchGestures = value as! Bool
            case "blacklistedApps":
                await ConcurrentAppSettings.blacklistedAppIds = value as! [String]
            case "dockPersistentApps":
                await ConcurrentAppSettings.dockPersistentAppIds = value as! [String]
            default:
                break
            }
        } else {
            // Update legacy settings
            switch key {
            case "showControlStrip":
                AppSettings.showControlStripState = value as! Bool
            case "hapticFeedback":
                AppSettings.hapticFeedbackState = value as! Bool
            case "multitouchGestures":
                AppSettings.multitouchGestures = value as! Bool
            case "blacklistedApps":
                AppSettings.blacklistedAppIds = value as! [String]
            case "dockPersistentApps":
                AppSettings.dockPersistentAppIds = value as! [String]
            default:
                break
            }
        }
    }
    
    // MARK: - Status Information
    
    /// Check if migration is complete
    var migrationStatus: MigrationStatus {
        if isMigrationComplete {
            return .completed
        } else if migrationStartTime != nil {
            return .inProgress
        } else {
            return .notStarted
        }
    }
    
    /// Get migration progress information
    var migrationProgress: MigrationProgress {
        return MigrationProgress(
            status: migrationStatus,
            startTime: migrationStartTime,
            isComplete: isMigrationComplete
        )
    }
}

// MARK: - Supporting Types

enum MigrationStatus {
    case notStarted
    case inProgress
    case completed
}

struct MigrationProgress {
    let status: MigrationStatus
    let startTime: Date?
    let isComplete: Bool
}

enum MigrationError: Error, LocalizedError {
    case verificationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed(let detail):
            return "Migration verification failed: \(detail)"
        }
    }
}
