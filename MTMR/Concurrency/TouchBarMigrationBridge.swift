//
//  TouchBarMigrationBridge.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  Bridge between legacy TouchBarController and new ConcurrentTouchBarController
//

import Foundation
import Cocoa

/// Bridge class to facilitate migration from TouchBarController to ConcurrentTouchBarController
/// This allows both systems to coexist during the migration process
@MainActor
class TouchBarMigrationBridge {
    static let shared = TouchBarMigrationBridge()
    
    private var isMigrationComplete = false
    private var migrationStartTime: Date?
    private var legacyController: TouchBarController?
    private var concurrentController: ConcurrentTouchBarController?
    
    private init() {
        // Check if migration has already been completed
        isMigrationComplete = UserDefaults.standard.bool(forKey: "com.toxblh.mtmr.touchbar.migration.completed")
    }
    
    // MARK: - Migration Control
    
    /// Start the TouchBar migration process
    func startMigration() async {
        guard !isMigrationComplete else {
            print("MTMR: TouchBar migration already completed")
            return
        }
        
        print("MTMR: Starting TouchBar migration to Swift 6.0 architecture...")
        migrationStartTime = Date()
        
        do {
            // Perform the migration
            try await performTouchBarMigration()
            
            // Mark migration as complete
            isMigrationComplete = true
            UserDefaults.standard.set(true, forKey: "com.toxblh.mtmr.touchbar.migration.completed")
            
            print("MTMR: TouchBar migration completed successfully")
            
        } catch {
            print("MTMR: TouchBar migration failed: \(error)")
            // Migration failed, but we can continue using legacy TouchBar
        }
    }
    
    /// Perform the actual TouchBar migration
    private func performTouchBarMigration() async throws {
        // Step 1: Initialize the concurrent controller
        await initializeConcurrentController()
        
        // Step 2: Migrate state from legacy controller
        await migrateTouchBarState()
        
        // Step 3: Verify the migration was successful
        try await verifyTouchBarMigration()
        
        // Step 4: Log migration completion
        logTouchBarMigrationCompletion()
    }
    
    /// Initialize the concurrent TouchBar controller
    private func initializeConcurrentController() async {
        print("MTMR: Initializing ConcurrentTouchBarController...")
        
        concurrentController = ConcurrentTouchBarController.shared
        
        // Set up the concurrent controller with basic configuration
        await concurrentController?.reloadItems()
        
        print("MTMR: ConcurrentTouchBarController initialized successfully")
    }
    
    /// Migrate TouchBar state from legacy controller
    private func migrateTouchBarState() async {
        print("MTMR: Migrating TouchBar state...")
        
        guard let concurrentController = concurrentController else {
            print("MTMR: ConcurrentTouchBarController not available for migration")
            return
        }
        
        // Migrate the TouchBar state
        await concurrentController.migrateFromLegacyController()
        
        print("MTMR: TouchBar state migration completed")
    }
    
    /// Verify that the TouchBar migration was successful
    private func verifyTouchBarMigration() async throws {
        print("MTMR: Verifying TouchBar migration...")
        
        guard let concurrentController = concurrentController else {
            throw TouchBarMigrationError.concurrentControllerNotAvailable
        }
        
        // Verify that the concurrent controller has basic functionality
        guard concurrentController.touchBar != nil else {
            throw TouchBarMigrationError.touchBarNotInitialized
        }
        
        print("MTMR: TouchBar migration verification successful")
    }
    
    /// Log TouchBar migration completion details
    private func logTouchBarMigrationCompletion() {
        guard let startTime = migrationStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        print("MTMR: TouchBar migration completed in \(String(format: "%.2f", duration)) seconds")
    }
    
    // MARK: - TouchBar Access (Migration-Aware)
    
    /// Get the appropriate TouchBar controller based on migration status
    var activeTouchBarController: Any {
        if isMigrationComplete, let concurrentController = concurrentController {
            return concurrentController
        } else {
            // Fall back to legacy controller
            return TouchBarController.shared
        }
    }
    
    /// Get the TouchBar instance, using the new system if available
    var touchBar: NSTouchBar? {
        if isMigrationComplete, let concurrentController = concurrentController {
            return concurrentController.touchBar
        } else {
            return TouchBarController.shared.touchBar
        }
    }
    
    /// Reload TouchBar items using the appropriate controller
    func reloadTouchBarItems() async {
        if isMigrationComplete, let concurrentController = concurrentController {
            await concurrentController.reloadItems()
        } else {
            // Use legacy method
            TouchBarController.shared.reloadStandardConfig()
        }
    }
    
    /// Update TouchBar for active application
    func updateTouchBarForActiveApp() async {
        if isMigrationComplete, let concurrentController = concurrentController {
            await concurrentController.updateBlacklistStatus()
        } else {
            // Use legacy method
            TouchBarController.shared.updateActiveApp()
        }
    }
    
    /// Present the TouchBar using the appropriate controller
    func presentTouchBar() {
        if isMigrationComplete, let concurrentController = concurrentController {
            // Use concurrent controller method
            // This will be implemented based on the existing functionality
        } else {
            // Use legacy method
            // This will be implemented based on the existing functionality
        }
    }
    
    // MARK: - Status Information
    
    /// Check if TouchBar migration is complete
    var migrationStatus: TouchBarMigrationStatus {
        if isMigrationComplete {
            return .completed
        } else if migrationStartTime != nil {
            return .inProgress
        } else {
            return .notStarted
        }
    }
    
    /// Get TouchBar migration progress information
    var migrationProgress: TouchBarMigrationProgress {
        return TouchBarMigrationProgress(
            status: migrationStatus,
            startTime: migrationStartTime,
            isComplete: isMigrationComplete
        )
    }
    
    // MARK: - Legacy Controller Access
    
    /// Get the legacy TouchBar controller (for migration purposes)
    func getLegacyController() -> TouchBarController {
        return TouchBarController.shared
    }
    
    /// Check if legacy controller is still needed
    var needsLegacyController: Bool {
        return !isMigrationComplete
    }
}

// MARK: - Supporting Types

enum TouchBarMigrationStatus {
    case notStarted
    case inProgress
    case completed
}

struct TouchBarMigrationProgress {
    let status: TouchBarMigrationStatus
    let startTime: Date?
    let isComplete: Bool
}

enum TouchBarMigrationError: Error, LocalizedError {
    case concurrentControllerNotAvailable
    case touchBarNotInitialized
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .concurrentControllerNotAvailable:
            return "ConcurrentTouchBarController not available for migration"
        case .touchBarNotInitialized:
            return "TouchBar not properly initialized in concurrent controller"
        case .migrationFailed(let detail):
            return "TouchBar migration failed: \(detail)"
        }
    }
}

// MARK: - Migration Utilities

extension TouchBarMigrationBridge {
    
    /// Check if the app should use the new TouchBar system
    var shouldUseConcurrentTouchBar: Bool {
        return isMigrationComplete && concurrentController != nil
    }
    
    /// Get the current TouchBar configuration
    var currentConfiguration: [BarItemDefinition] {
        if isMigrationComplete, let concurrentController = concurrentController {
            // Return configuration from concurrent controller
            // This will be implemented once the concurrent controller is fully functional
            return []
        } else {
            // Return configuration from legacy controller
            return TouchBarController.shared.jsonItems
        }
    }
    
    /// Update TouchBar configuration
    func updateConfiguration(_ newItems: [BarItemDefinition]) async {
        if isMigrationComplete, let concurrentController = concurrentController {
            await concurrentController.createAndUpdatePreset(newJsonItems: newItems)
        } else {
            // Use legacy method
            TouchBarController.shared.createAndUpdatePreset(newJsonItems: newItems)
        }
    }
}
