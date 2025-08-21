//
//  PermissionMigrationBridge.swift
//  MTMR
//
//  Created for Swift 6.0 Migration
//  Bridge between legacy EnhancedPermissionManager and new ActorBasedPermissionManager
//

import Foundation

/// Bridge class to facilitate migration from EnhancedPermissionManager to ActorBasedPermissionManager
/// This allows both systems to coexist during the migration process
@MainActor
class PermissionMigrationBridge {
    static let shared = PermissionMigrationBridge()
    
    private var isMigrationComplete = false
    private var migrationStartTime: Date?
    private var legacyManager: EnhancedPermissionManager?
    private var concurrentManager: ActorBasedPermissionManager?
    
    private init() {
        // Check if migration has already been completed
        isMigrationComplete = UserDefaults.standard.bool(forKey: "com.toxblh.mtmr.permissions.migration.completed")
    }
    
    // MARK: - Migration Control
    
    /// Start the permission manager migration process
    func startMigration() async {
        guard !isMigrationComplete else {
            print("MTMR: Permission manager migration already completed")
            return
        }
        
        print("MTMR: Starting permission manager migration to Swift 6.0 architecture...")
        migrationStartTime = Date()
        
        do {
            // Perform the migration
            try await performPermissionMigration()
            
            // Mark migration as complete
            isMigrationComplete = true
            UserDefaults.standard.set(true, forKey: "com.toxblh.mtmr.permissions.migration.completed")
            
            print("MTMR: Permission manager migration completed successfully")
            
        } catch {
            print("MTMR: Permission manager migration failed: \(error)")
            // Migration failed, but we can continue using legacy permission manager
        }
    }
    
    /// Perform the actual permission manager migration
    private func performPermissionMigration() async throws {
        // Step 1: Initialize the concurrent permission manager
        await initializeConcurrentPermissionManager()
        
        // Step 2: Migrate state from legacy permission manager
        await migratePermissionState()
        
        // Step 3: Verify the migration was successful
        try await verifyPermissionMigration()
        
        // Step 4: Log migration completion
        logPermissionMigrationCompletion()
    }
    
    /// Initialize the concurrent permission manager
    private func initializeConcurrentPermissionManager() async {
        print("MTMR: Initializing ActorBasedPermissionManager...")
        
        concurrentManager = ActorBasedPermissionManager.shared
        
        // Verify the manager is working
        let stats = await concurrentManager?.getCacheStats()
        print("MTMR: ActorBasedPermissionManager initialized with \(stats?.cachedPermissions ?? 0) cached permissions")
        
        print("MTMR: ActorBasedPermissionManager initialized successfully")
    }
    
    /// Migrate permission state from legacy permission manager
    private func migratePermissionState() async {
        print("MTMR: Migrating permission state...")
        
        guard let concurrentManager = concurrentManager else {
            print("MTMR: ActorBasedPermissionManager not available for migration")
            return
        }
        
        // Get the legacy manager
        legacyManager = EnhancedPermissionManager.shared
        
        // Migrate the permission state
        await concurrentManager.migrateFromLegacy(legacyManager!)
        
        print("MTMR: Permission state migration completed")
    }
    
    /// Verify that the permission migration was successful
    private func verifyPermissionMigration() async throws {
        print("MTMR: Verifying permission migration...")
        
        guard let concurrentManager = concurrentManager else {
            throw PermissionMigrationError.concurrentManagerNotAvailable
        }
        
        // Verify that the concurrent manager has basic functionality
        let stats = await concurrentManager.getCacheStats()
        guard stats.cachedPermissions > 0 || !await concurrentManager.needsMigration else {
            throw PermissionMigrationError.permissionStateNotMigrated
        }
        
        print("MTMR: Permission migration verification successful")
    }
    
    /// Log permission migration completion details
    private func logPermissionMigrationCompletion() {
        guard let startTime = migrationStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        print("MTMR: Permission manager migration completed in \(String(format: "%.2f", duration)) seconds")
    }
    
    // MARK: - Permission Access (Migration-Aware)
    
    /// Get the appropriate permission manager based on migration status
    var activePermissionManager: Any {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            return concurrentManager
        } else {
            // Fall back to legacy manager
            return EnhancedPermissionManager.shared
        }
    }
    
    /// Check all permissions using the appropriate manager
    func checkAllPermissions() async -> [String: Any] {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            let permissions = await concurrentManager.checkAllPermissions()
            // Convert to dictionary format for compatibility
            var result: [String: Any] = [:]
            for (key, value) in permissions {
                result[key] = value.rawValue
            }
            return result
        } else {
            // Use legacy method
            let permissions = EnhancedPermissionManager.shared.checkAllPermissions()
            return permissions
        }
    }
    
    /// Check a specific permission using the appropriate manager
    func checkPermission(for permission: String) async -> String {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            let state = await concurrentManager.getCachedPermissionState(for: permission)
            return state.rawValue
        } else {
            // Use legacy method
            let state = EnhancedPermissionManager.shared.getCachedPermissionState(for: permission)
            return state.rawValue
        }
    }
    
    /// Request a permission using the appropriate manager
    func requestPermission(for permission: String) async -> Bool {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            return await concurrentManager.smartRequestPermission(for: permission)
        } else {
            // Use legacy method
            return EnhancedPermissionManager.shared.smartRequestPermission(for: permission)
        }
    }
    
    /// Get permission status summary using the appropriate manager
    func getPermissionStatusSummary() async -> String {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            return await concurrentManager.getPermissionStatusSummary()
        } else {
            // Use legacy method
            return EnhancedPermissionManager.shared.getPermissionStatusSummary()
        }
    }
    
    /// Check if a permission is granted using the appropriate manager
    func isPermissionGranted(for permission: String) async -> Bool {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            return concurrentManager.isPermissionGranted(for: permission)
        } else {
            // Use legacy method
            return EnhancedPermissionManager.shared.isPermissionGranted(for: permission)
        }
    }
    
    // MARK: - Status Information
    
    /// Check if permission migration is complete
    var migrationStatus: PermissionMigrationStatus {
        if isMigrationComplete {
            return .completed
        } else if migrationStartTime != nil {
            return .inProgress
        } else {
            return .notStarted
        }
    }
    
    /// Get permission migration progress information
    var migrationProgress: PermissionMigrationProgress {
        return PermissionMigrationProgress(
            status: migrationStatus,
            startTime: migrationStartTime,
            isComplete: isMigrationComplete
        )
    }
    
    // MARK: - Legacy Manager Access
    
    /// Get the legacy permission manager (for migration purposes)
    func getLegacyManager() -> EnhancedPermissionManager {
        return EnhancedPermissionManager.shared
    }
    
    /// Check if legacy manager is still needed
    var needsLegacyManager: Bool {
        return !isMigrationComplete
    }
    
    // MARK: - Performance Monitoring
    
    /// Get cache statistics from the appropriate manager
    func getCacheStats() async -> (cachedPermissions: Int, lastCheck: Date?) {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            return await concurrentManager.getCacheStats()
        } else {
            // Legacy manager doesn't have cache stats, return default values
            return (0, nil)
        }
    }
    
    /// Check if cache is valid using the appropriate manager
    func isCacheValid() async -> Bool {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            return concurrentManager.isCacheValid()
        } else {
            // Legacy manager doesn't have cache validation, return false
            return false
        }
    }
    
    /// Refresh permission cache using the appropriate manager
    func refreshPermissionCache() async {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            await concurrentManager.refreshPermissionCache()
        } else {
            // Legacy manager doesn't have cache refresh, do nothing
        }
    }
}

// MARK: - Supporting Types

enum PermissionMigrationStatus {
    case notStarted
    case inProgress
    case completed
}

struct PermissionMigrationProgress {
    let status: PermissionMigrationStatus
    let startTime: Date?
    let isComplete: Bool
}

enum PermissionMigrationError: Error, LocalizedError {
    case concurrentManagerNotAvailable
    case permissionStateNotMigrated
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .concurrentManagerNotAvailable:
            return "ActorBasedPermissionManager not available for migration"
        case .permissionStateNotMigrated:
            return "Permission state not properly migrated to concurrent manager"
        case .migrationFailed(let detail):
            return "Permission manager migration failed: \(detail)"
        }
    }
}

// MARK: - Migration Utilities

extension PermissionMigrationBridge {
    
    /// Check if the app should use the new permission system
    var shouldUseConcurrentPermissions: Bool {
        return isMigrationComplete && concurrentManager != nil
    }
    
    /// Get the current permission configuration
    var currentPermissionConfiguration: [String: String] {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            // Return configuration from concurrent manager
            // This will be implemented once the concurrent manager is fully functional
            return [:]
        } else {
            // Return configuration from legacy manager
            let permissions = EnhancedPermissionManager.shared.checkAllPermissions()
            var result: [String: String] = [:]
            for (key, value) in permissions {
                result[key] = value.rawValue
            }
            return result
        }
    }
    
    /// Update permission configuration
    func updatePermissionConfiguration(_ newPermissions: [String: String]) async {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            // Update concurrent manager configuration
            // This will be implemented once the concurrent manager is fully functional
        } else {
            // Use legacy method
            // Legacy manager doesn't support dynamic configuration updates
        }
    }
    
    /// Reset permission cache using the appropriate manager
    func resetPermissionCache() async {
        if isMigrationComplete, let concurrentManager = concurrentManager {
            concurrentManager.resetPermissionCache()
        } else {
            // Use legacy method
            EnhancedPermissionManager.shared.resetPermissionCache()
        }
    }
}
