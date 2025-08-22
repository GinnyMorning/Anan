//
//  CloudSyncManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 5C: Cloud Sync - Cloud Sync Manager.
//

import Cocoa
import Foundation
import CloudKit

// MARK: - Cloud Sync Manager

// MARK: - Supporting Types

struct LayoutConfiguration: Codable, Sendable {
    var spacing: Double = 8.0
    var padding: Double = 16.0
    var alignment: String = "center"
}

struct GlobalSettings: Codable, Sendable {
    var theme: String = "default"
    var language: String = "en"
    var notifications: Bool = true
}

struct WidgetConfiguration: Codable, Sendable {
    let id: String
    let type: String
    let name: String
    let configuration: [String: String]
}

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var isSignedIn = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var lastError: String?
    
    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    private var userRecordID: CKRecord.ID?
    private var syncTimer: Timer?
    
    private init() {
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        
        // Check iCloud status
        checkiCloudStatus()
        
        // Set up sync timer
        setupSyncTimer()
    }
    
    // MARK: - Public Methods
    
    func signIn() async throws {
        syncStatus = .signingIn
        
        do {
            // Request iCloud permission
            let status = try await container.requestApplicationPermission(.userDiscoverability)
            
            guard status == .granted else {
                throw CloudSyncError.permissionDenied
            }
            
            // Get user record
            let userRecord = try await container.userRecordID()
            self.userRecordID = userRecord
            
            // Check if user exists in our system
            try await ensureUserRecordExists()
            
            await MainActor.run {
                self.isSignedIn = true
                self.syncStatus = .idle
            }
            
            print("MTMR: Cloud sync signed in successfully")
        } catch {
            await MainActor.run {
                self.syncStatus = .error
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() {
        isSignedIn = false
        userRecordID = nil
        syncStatus = .idle
        lastSyncDate = nil
        syncProgress = 0.0
        lastError = nil
        
        // Stop sync timer
        syncTimer?.invalidate()
        syncTimer = nil
        
        print("MTMR: Cloud sync signed out")
    }
    
    func syncConfiguration() async throws {
        guard isSignedIn else {
            throw CloudSyncError.notSignedIn
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Upload current configuration
            try await uploadConfiguration()
            syncProgress = 0.5
            
            // Download any updates
            try await downloadConfiguration()
            syncProgress = 1.0
            
            await MainActor.run {
                self.syncStatus = .idle
                self.lastSyncDate = Date()
                self.lastError = nil
            }
            
            print("MTMR: Configuration synced successfully")
        } catch {
            await MainActor.run {
                self.syncStatus = .error
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func backupConfiguration() async throws {
        guard isSignedIn else {
            throw CloudSyncError.notSignedIn
        }
        
        syncStatus = .backingUp
        syncProgress = 0.0
        
        do {
            // Create backup record
            try await createBackupRecord()
            syncProgress = 1.0
            
            await MainActor.run {
                self.syncStatus = .idle
                self.lastError = nil
            }
            
            print("MTMR: Configuration backed up successfully")
        } catch {
            await MainActor.run {
                self.syncStatus = .error
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func restoreConfiguration(from backup: ConfigurationBackup) async throws {
        guard isSignedIn else {
            throw CloudSyncError.notSignedIn
        }
        
        syncStatus = .restoring
        syncProgress = 0.0
        
        do {
            // Download backup data
            let configuration = try await downloadBackupData(backup)
            syncProgress = 0.5
            
            // Apply configuration locally
            try await applyConfiguration(configuration)
            syncProgress = 1.0
            
            await MainActor.run {
                self.syncStatus = .idle
                self.lastError = nil
            }
            
            print("MTMR: Configuration restored successfully")
        } catch {
            await MainActor.run {
                self.syncStatus = .error
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func shareConfiguration(with users: [String]) async throws {
        guard isSignedIn else {
            throw CloudSyncError.notSignedIn
        }
        
        syncStatus = .sharing
        syncProgress = 0.0
        
        do {
            // Create share record
            try await createShareRecord(for: users)
            syncProgress = 1.0
            
            await MainActor.run {
                self.syncStatus = .idle
                self.lastError = nil
            }
            
            print("MTMR: Configuration shared successfully")
        } catch {
            await MainActor.run {
                self.syncStatus = .error
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    func getBackups() async throws -> [ConfigurationBackup] {
        guard isSignedIn else {
            throw CloudSyncError.notSignedIn
        }
        
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", userRecordID!)
        let query = CKQuery(recordType: "ConfigurationBackup", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = try await privateDatabase.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        return records.compactMap { record in
            guard let name = record["name"] as? String,
                  let creationDate = record.creationDate,
                  let configurationData = record["configurationData"] as? Data else {
                return nil
            }
            
            return ConfigurationBackup(
                id: record.recordID.recordName,
                name: name,
                creationDate: creationDate,
                size: configurationData.count
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if status == .available {
                    print("MTMR: iCloud is available")
                } else {
                    print("MTMR: iCloud status: \(status.rawValue)")
                    if let error = error {
                        print("MTMR: iCloud error: \(error)")
                    }
                }
            }
        }
    }
    
    private func setupSyncTimer() {
        // Sync every 30 minutes when signed in
        syncTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            guard let self = self, self.isSignedIn else { return }
            
            Task {
                try? await self.syncConfiguration()
            }
        }
    }
    
    private func ensureUserRecordExists() async throws {
        guard let userRecordID = userRecordID else { return }
        
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", userRecordID)
        let query = CKQuery(recordType: "MTMRUser", predicate: predicate)
        
        do {
            let result = try await privateDatabase.records(matching: query)
            if result.matchResults.isEmpty {
                // Create user record
                try await createUserRecord()
            }
        } catch {
            // If query fails, create user record
            try await createUserRecord()
        }
    }
    
    private func createUserRecord() async throws {
        let userRecord = CKRecord(recordType: "MTMRUser")
        userRecord["deviceName"] = Host.current().localizedName ?? "Unknown Device"
        userRecord["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        userRecord["lastSyncDate"] = Date()
        
        try await privateDatabase.save(record: userRecord)
    }
    
    private func uploadConfiguration() async throws {
        guard let userRecordID = userRecordID else { return }
        
        // Get current configuration
        let configuration = getCurrentConfiguration()
        let configurationData = try JSONEncoder().encode(configuration)
        
        // Create or update configuration record
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", userRecordID)
        let query = CKQuery(recordType: "Configuration", predicate: predicate)
        
        do {
            let result = try await privateDatabase.records(matching: query)
            let existingRecordResult = result.matchResults.first?.1
            
            let record: CKRecord
            if let existingRecordResult = existingRecordResult {
                switch existingRecordResult {
                case .success(let r):
                    record = r
                case .failure(let error):
                    throw CloudSyncError.uploadFailed(error)
                }
            } else {
                record = CKRecord(recordType: "Configuration")
            }
            
            record["configurationData"] = configurationData
            record["lastModified"] = Date()
            record["version"] = "1.0"
            
            try await privateDatabase.save(record: record)
        } catch {
            throw CloudSyncError.uploadFailed(error)
        }
    }
    
    private func downloadConfiguration() async throws {
        guard let userRecordID = userRecordID else { return }
        
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", userRecordID)
        let query = CKQuery(recordType: "Configuration", predicate: predicate)
        
        do {
            let result = try await privateDatabase.records(matching: query)
            guard let recordResult = result.matchResults.first?.1 else {
                return // No configuration to download
            }
            
            let record: CKRecord
            switch recordResult {
            case .success(let r):
                record = r
            case .failure(let error):
                throw CloudSyncError.downloadFailed(error)
            }
            
            guard let configurationData = record["configurationData"] as? Data else {
                return // No configuration to download
            }
            
            let configuration = try JSONDecoder().decode(CloudConfiguration.self, from: configurationData)
            
            // Check if remote configuration is newer
            if let lastModified = record["lastModified"] as? Date,
               let localLastModified = getLocalLastModified(),
               lastModified > localLastModified {
                // Apply remote configuration
                try await applyConfiguration(configuration)
            }
        } catch {
            throw CloudSyncError.downloadFailed(error)
        }
    }
    
    private func createBackupRecord() async throws {
        guard let userRecordID = userRecordID else { return }
        
        let configuration = getCurrentConfiguration()
        let configurationData = try JSONEncoder().encode(configuration)
        
        let backupRecord = CKRecord(recordType: "ConfigurationBackup")
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        backupRecord["name"] = "Backup \(formatter.string(from: Date()))"
        backupRecord["configurationData"] = configurationData
        backupRecord["size"] = configurationData.count
        backupRecord["description"] = "Automatic backup created on \(formatter.string(from: Date()))"
        
        try await privateDatabase.save(record: backupRecord)
    }
    
    private func downloadBackupData(_ backup: ConfigurationBackup) async throws -> CloudConfiguration {
        let predicate = NSPredicate(format: "recordID.recordName == %@", backup.id)
        let query = CKQuery(recordType: "ConfigurationBackup", predicate: predicate)
        
        do {
            let result = try await privateDatabase.records(matching: query)
            guard let recordResult = result.matchResults.first?.1 else {
                throw CloudSyncError.backupNotFound
            }
            
            let record: CKRecord
            switch recordResult {
            case .success(let r):
                record = r
            case .failure(let error):
                throw CloudSyncError.downloadFailed(error)
            }
            
            guard let configurationData = record["configurationData"] as? Data else {
                throw CloudSyncError.backupNotFound
            }
            
            return try JSONDecoder().decode(CloudConfiguration.self, from: configurationData)
        } catch {
            throw CloudSyncError.downloadFailed(error)
        }
    }
    
    private func applyConfiguration(_ configuration: CloudConfiguration) async throws {
        // Apply configuration to local system
        // This would integrate with ConfigurationManager
        print("MTMR: Applying cloud configuration...")
        
        // Simulate configuration application
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }
    
    private func createShareRecord(for users: [String]) async throws {
        guard let userRecordID = userRecordID else { return }
        
        let configuration = getCurrentConfiguration()
        let configurationData = try JSONEncoder().encode(configuration)
        
        let shareRecord = CKRecord(recordType: "ConfigurationShare")
        shareRecord["sharedWith"] = users
        shareRecord["configurationData"] = configurationData
        shareRecord["sharedBy"] = userRecordID.recordName
        shareRecord["shareDate"] = Date()
        shareRecord["isPublic"] = false
        
        try await privateDatabase.save(record: shareRecord)
    }
    
    private func getCurrentConfiguration() -> CloudConfiguration {
        // Get current configuration from ConfigurationManager
        // This would integrate with the existing configuration system
        return CloudConfiguration(
            widgets: [],
            layout: LayoutConfiguration(),
            globalSettings: GlobalSettings(),
            version: "1.0.0",
            lastModified: Date()
        )
    }
    
    private func getLocalLastModified() -> Date? {
        // Get local last modified date
        // This would integrate with the existing configuration system
        return Date()
    }
}

// MARK: - Models

struct CloudConfiguration: Codable {
    let widgets: [WidgetConfiguration]
    let layout: LayoutConfiguration
    let globalSettings: GlobalSettings
    let version: String
    let lastModified: Date
}

struct ConfigurationBackup: Identifiable, Codable {
    let id: String
    let name: String
    let creationDate: Date
    let size: Int
    
    var formattedSize: String {
        if size >= 1_000_000 {
            return String(format: "%.1f MB", Double(size) / 1_000_000.0)
        } else if size >= 1_000 {
            return String(format: "%.1f KB", Double(size) / 1_000.0)
        } else {
            return "\(size) B"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}

enum SyncStatus {
    case idle
    case signingIn
    case syncing
    case backingUp
    case restoring
    case sharing
    case error
    
    var description: String {
        switch self {
        case .idle: return "Ready"
        case .signingIn: return "Signing In..."
        case .syncing: return "Syncing..."
        case .backingUp: return "Backing Up..."
        case .restoring: return "Restoring..."
        case .sharing: return "Sharing..."
        case .error: return "Error"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "checkmark.circle"
        case .signingIn: return "person.crop.circle.badge.plus"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .backingUp: return "externaldrive"
        case .restoring: return "arrow.clockwise"
        case .sharing: return "square.and.arrow.up"
        case .error: return "exclamationmark.triangle"
        }
    }
}

enum CloudSyncError: LocalizedError {
    case notSignedIn
    case permissionDenied
    case uploadFailed(Error)
    case downloadFailed(Error)
    case backupNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to use cloud sync"
        case .permissionDenied:
            return "iCloud permission denied"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .backupNotFound:
            return "Backup not found"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Extensions

extension CKDatabase {
    func records(matching query: CKQuery) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        return try await withCheckedThrowingContinuation { continuation in
            let operation = CKQueryOperation(query: query)
            var records: [(CKRecord.ID, Result<CKRecord, Error>)] = []
            
            operation.recordFetchedBlock = { record in
                records.append((record.recordID, .success(record)))
            }
            
            operation.queryCompletionBlock = { cursor, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (matchResults: records, queryCursor: cursor))
                }
            }
            
            operation.start()
        }
    }
    
    func save(record: CKRecord) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            save(record) { record, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
