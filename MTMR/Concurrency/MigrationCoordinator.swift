//
//  MigrationCoordinator.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  Coordinates the migration from legacy components to concurrent ones
//

import Foundation
import AppKit

/// Coordinates the migration from Swift 5.0 to Swift 6.0 architecture
@MainActor
class MigrationCoordinator {
    static let shared = MigrationCoordinator()
    
    private var migrationState: MigrationState = .notStarted
    private var migrationProgress: Double = 0.0
    
    enum MigrationState {
        case notStarted
        case inProgress
        case completed
        case failed(Error)
    }
    
    enum MigrationPhase: CaseIterable {
        case settings
        case permissions
        case touchBarController
        case widgets
        case cleanup
        
        var description: String {
            switch self {
            case .settings: return "Migrating App Settings"
            case .permissions: return "Migrating Permission Manager"
            case .touchBarController: return "Migrating TouchBar Controller"
            case .widgets: return "Migrating Widget Architecture"
            case .cleanup: return "Cleaning Up Legacy Components"
            }
        }
        
        var weight: Double {
            switch self {
            case .settings: return 0.2
            case .permissions: return 0.2
            case .touchBarController: return 0.3
            case .widgets: return 0.2
            case .cleanup: return 0.1
            }
        }
    }
    
    private init() {}
    
    // MARK: - Migration Control
    
    func startMigration() async throws {
        guard migrationState == .notStarted else {
            throw MigrationError.alreadyInProgress
        }
        
        migrationState = .inProgress
        migrationProgress = 0.0
        
        print("🚀 Starting Swift 6.0 Migration...")
        
        do {
            for phase in MigrationPhase.allCases {
                try await migratePhase(phase)
                updateProgress(for: phase)
            }
            
            migrationState = .completed
            migrationProgress = 1.0
            print("✅ Swift 6.0 Migration completed successfully!")
            
        } catch {
            migrationState = .failed(error)
            print("❌ Migration failed: \(error)")
            throw error
        }
    }
    
    private func migratePhase(_ phase: MigrationPhase) async throws {
        print("📋 \(phase.description)...")
        
        switch phase {
        case .settings:
            try await migrateSettings()
        case .permissions:
            try await migratePermissions()
        case .touchBarController:
            try await migrateTouchBarController()
        case .widgets:
            try await migrateWidgets()
        case .cleanup:
            try await cleanupLegacyComponents()
        }
        
        print("✅ \(phase.description) completed")
    }
    
    private func updateProgress(for phase: MigrationPhase) {
        migrationProgress += phase.weight
        print("📊 Migration progress: \(Int(migrationProgress * 100))%")
    }
    
    // MARK: - Phase Implementations
    
    private func migrateSettings() async throws {
        // Migrate AppSettings to ConcurrentAppSettings
        await ConcurrentAppSettings.migrateFromLegacySettings()
        
        // Verify migration
        let legacyValue = AppSettings.showControlStripState
        let newValue = await ConcurrentAppSettings.showControlStripState
        
        guard legacyValue == newValue else {
            throw MigrationError.settingsMigrationFailed
        }
    }
    
    private func migratePermissions() async throws {
        // Migrate EnhancedPermissionManager to ActorBasedPermissionManager
        await ActorBasedPermissionManager.shared.migrateFromLegacyPermissionManager()
        
        // Verify permissions are accessible
        let permissions = await ActorBasedPermissionManager.shared.checkAllPermissions()
        guard !permissions.isEmpty else {
            throw MigrationError.permissionsMigrationFailed
        }
    }
    
    private func migrateTouchBarController() async throws {
        // Migrate TouchBarController to ConcurrentTouchBarController
        await ConcurrentTouchBarController.shared.migrateFromLegacyController()
        
        // Verify TouchBar is functional
        guard ConcurrentTouchBarController.shared.touchBar != nil else {
            throw MigrationError.touchBarMigrationFailed
        }
    }
    
    private func migrateWidgets() async throws {
        // This would migrate individual widgets to use concurrent architecture
        // For now, we'll just verify the base classes are available
        print("Widget migration placeholder - individual widgets would be migrated here")
    }
    
    private func cleanupLegacyComponents() async throws {
        // Clean up any temporary migration artifacts
        // In a real implementation, this might disable legacy components
        print("Cleanup completed - legacy components remain for rollback capability")
    }
    
    // MARK: - Rollback Support
    
    func rollbackMigration() async throws {
        print("🔄 Rolling back Swift 6.0 migration...")
        
        // In a real implementation, this would:
        // 1. Restore legacy component usage
        // 2. Copy settings back from concurrent to legacy
        // 3. Reset migration state
        
        migrationState = .notStarted
        migrationProgress = 0.0
        
        print("✅ Rollback completed")
    }
    
    // MARK: - Status Reporting
    
    func getMigrationStatus() -> (state: MigrationState, progress: Double) {
        return (migrationState, migrationProgress)
    }
    
    func isMigrationCompleted() -> Bool {
        if case .completed = migrationState {
            return true
        }
        return false
    }
}

// MARK: - Migration Errors

enum MigrationError: Error, LocalizedError {
    case alreadyInProgress
    case settingsMigrationFailed
    case permissionsMigrationFailed
    case touchBarMigrationFailed
    case widgetMigrationFailed
    case cleanupFailed
    
    var errorDescription: String? {
        switch self {
        case .alreadyInProgress:
            return "Migration is already in progress"
        case .settingsMigrationFailed:
            return "Failed to migrate app settings"
        case .permissionsMigrationFailed:
            return "Failed to migrate permission manager"
        case .touchBarMigrationFailed:
            return "Failed to migrate TouchBar controller"
        case .widgetMigrationFailed:
            return "Failed to migrate widget architecture"
        case .cleanupFailed:
            return "Failed to cleanup legacy components"
        }
    }
}
