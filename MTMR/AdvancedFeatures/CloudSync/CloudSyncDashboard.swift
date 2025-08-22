//
//  CloudSyncDashboard.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 5C: Cloud Sync - Cloud Sync Dashboard.
//

import Cocoa
import SwiftUI

// MARK: - Cloud Sync Dashboard

@MainActor
final class CloudSyncDashboard: ObservableObject {
    static let shared = CloudSyncDashboard()
    
    @Published var isVisible = false
    @Published var showBackupManager = false
    @Published var showShareManager = false
    
    private var dashboardWindow: NSWindow?
    private let cloudSyncManager = CloudSyncManager.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    func showDashboard() {
        isVisible = true
        
        if dashboardWindow == nil {
            createDashboardWindow()
        }
        
        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openBackupManager() {
        showBackupManager = true
        let backupWindow = createBackupManagerWindow()
        backupWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openShareManager() {
        showShareManager = true
        let shareWindow = createShareManagerWindow()
        shareWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Private Methods
    
    private func createDashboardWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "MTMR Cloud Sync Dashboard"
        window.center()
        window.setFrameAutosaveName("CloudSyncDashboardWindow")
        
        // Create SwiftUI view
        let dashboardView = CloudSyncDashboardView(
            onClose: { [weak self] in
                self?.closeDashboardWindow()
            }
        )
        
        let hostingView = NSHostingView(rootView: dashboardView)
        window.contentView = hostingView
        
        self.dashboardWindow = window
    }
    
    private func createBackupManagerWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Backup Manager"
        window.center()
        
        let backupManagerView = BackupManagerSheet()
        
        let hostingView = NSHostingView(rootView: backupManagerView)
        window.contentView = hostingView
        
        return window
    }
    
    private func createShareManagerWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Share Manager"
        window.center()
        
        let shareManagerView = ShareManagerSheet()
        
        let hostingView = NSHostingView(rootView: shareManagerView)
        window.contentView = hostingView
        
        return window
    }
    
    private func closeDashboardWindow() {
        dashboardWindow?.close()
        dashboardWindow = nil
        isVisible = false
    }
}

// MARK: - SwiftUI Views

struct CloudSyncDashboardView: View {
    @State var showBackupManager: Bool = false
    @State var showShareManager: Bool = false
    let onClose: () -> Void
    
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    @State private var showSignInAlert = false
    @State private var showSignOutAlert = false
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            dashboardHeader
            
            Divider()
            
            // Content
            if cloudSyncManager.isSignedIn {
                signedInContent
            } else {
                signedOutContent
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    if cloudSyncManager.isSignedIn {
                        Button("Backup Manager") {
                            showBackupManager = true
                        }
                        .keyboardShortcut("b")
                        
                        Button("Share Manager") {
                            showShareManager = true
                        }
                        .keyboardShortcut("s")
                        
                        Divider()
                        
                        Button("Sign Out") {
                            showSignOutAlert = true
                        }
                        .keyboardShortcut("o")
                    } else {
                        Button("Sign In") {
                            showSignInAlert = true
                        }
                        .keyboardShortcut("i")
                    }
                    
                    Divider()
                    
                    Button("Close") {
                        onClose()
                    }
                    .keyboardShortcut(.escape)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding()
            }
        )
        .sheet(isPresented: $showSignInAlert) {
            VStack(spacing: 20) {
                Text("Sign In to iCloud")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Sign in to your iCloud account to enable cloud sync, backup, and sharing features.")
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button("Sign In") {
                        Task {
                            try? await cloudSyncManager.signIn()
                        }
                        showSignInAlert = false
                    }
                    .keyboardShortcut(.return)
                    
                    Button("Cancel") {
                        showSignInAlert = false
                    }
                    .keyboardShortcut(.escape)
                }
            }
            .padding()
            .frame(width: 400, height: 200)
        }
        .sheet(isPresented: $showSignOutAlert) {
            VStack(spacing: 20) {
                Text("Sign Out")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Are you sure you want to sign out? This will stop cloud sync and remove access to your backups.")
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button("Sign Out") {
                        cloudSyncManager.signOut()
                        showSignOutAlert = false
                    }
                    .keyboardShortcut(.return)
                    
                    Button("Cancel") {
                        showSignOutAlert = false
                    }
                    .keyboardShortcut(.escape)
                }
            }
            .padding()
            .frame(width: 400, height: 200)
        }
        .sheet(isPresented: $showBackupManager) {
            BackupManagerSheet()
        }
        .sheet(isPresented: $showShareManager) {
            ShareManagerSheet()
        }
    }
    
    private var dashboardHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cloud Sync Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Synchronize and backup your TouchBar configurations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 8) {
                    Image(systemName: cloudSyncManager.isSignedIn ? "icloud.fill" : "icloud")
                        .foregroundColor(cloudSyncManager.isSignedIn ? .blue : .secondary)
                        .font(.title2)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(cloudSyncManager.isSignedIn ? "Signed In" : "Signed Out")
                            .font(.headline)
                            .foregroundColor(cloudSyncManager.isSignedIn ? .blue : .secondary)
                        
                        if let lastSync = cloudSyncManager.lastSyncDate {
                            Text("Last sync: \(formatDate(lastSync))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Sync status bar
            if cloudSyncManager.isSignedIn {
                syncStatusBar
            }
        }
        .padding()
    }
    
    private var syncStatusBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: cloudSyncManager.syncStatus.icon)
                    .foregroundColor(syncStatusColor)
                    .font(.subheadline)
                
                Text(cloudSyncManager.syncStatus.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(syncStatusColor)
                
                Spacer()
                
                if cloudSyncManager.syncStatus == .syncing || 
                   cloudSyncManager.syncStatus == .backingUp ||
                   cloudSyncManager.syncStatus == .restoring ||
                   cloudSyncManager.syncStatus == .sharing {
                    ProgressView(value: cloudSyncManager.syncProgress)
                        .frame(width: 100)
                }
            }
            
            if let error = cloudSyncManager.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var signedInContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Actions
                quickActionsSection
                
                // Sync Information
                syncInformationSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
    }
    
    private var signedOutContent: some View {
        VStack(spacing: 32) {
            Image(systemName: "icloud")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Text("Sign in to iCloud")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enable cloud sync to automatically backup and synchronize your TouchBar configurations across all your devices.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Button("Sign In to iCloud") {
                showSignInAlert = true
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                QuickActionCard(
                    title: "Sync Now",
                    description: "Manually sync your configuration",
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue
                ) {
                    Task {
                        try? await cloudSyncManager.syncConfiguration()
                    }
                }
                
                QuickActionCard(
                    title: "Create Backup",
                    description: "Backup your current configuration",
                    icon: "externaldrive",
                    color: .green
                ) {
                    Task {
                        try? await cloudSyncManager.backupConfiguration()
                    }
                }
                
                QuickActionCard(
                    title: "Backup Manager",
                    description: "Manage your backups",
                    icon: "folder",
                    color: .orange
                ) {
                    showBackupManager = true
                }
                
                QuickActionCard(
                    title: "Share Manager",
                    description: "Share configurations",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    showShareManager = true
                }
            }
        }
    }
    
    private var syncInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Information")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                InfoCard(
                    title: "Device Name",
                    value: Host.current().localizedName ?? "Unknown",
                    icon: "macbook",
                    color: .blue
                )
                
                InfoCard(
                    title: "App Version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                    icon: "app.badge",
                    color: .green
                )
                
                InfoCard(
                    title: "Last Sync",
                    value: cloudSyncManager.lastSyncDate != nil ? formatDate(cloudSyncManager.lastSyncDate!) : "Never",
                    icon: "clock",
                    color: .orange
                )
                
                InfoCard(
                    title: "Sync Status",
                    value: cloudSyncManager.syncStatus.description,
                    icon: cloudSyncManager.syncStatus.icon,
                    color: syncStatusColor
                )
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                ActivityRow(
                    action: "Configuration synced",
                    timestamp: Date().addingTimeInterval(-300),
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue
                )
                
                ActivityRow(
                    action: "Backup created",
                    timestamp: Date().addingTimeInterval(-1800),
                    icon: "externaldrive",
                    color: .green
                )
                
                ActivityRow(
                    action: "Configuration shared",
                    timestamp: Date().addingTimeInterval(-3600),
                    icon: "square.and.arrow.up",
                    color: .purple
                )
            }
        }
    }
    
    private var syncStatusColor: Color {
        switch cloudSyncManager.syncStatus {
        case .idle: return .green
        case .signingIn, .syncing, .backingUp, .restoring, .sharing: return .blue
        case .error: return .red
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ActivityRow: View {
    let action: String
    let timestamp: Date
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(action)
                .font(.subheadline)
            
            Spacer()
            
            Text(timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - Sheet Views

struct BackupManagerSheet: View {
    @State private var isPresented = true
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    @State private var backups: [ConfigurationBackup] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Text("Backup Manager")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            if isLoading {
                ProgressView("Loading backups...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if backups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "externaldrive")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No backups found")
                        .font(.headline)
                    
                    Text("Create your first backup to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(backups) { backup in
                            BackupRow(backup: backup)
                        }
                    }
                    .padding()
                }
            }
            
            HStack {
                Button("Create Backup") {
                    Task {
                        try? await cloudSyncManager.backupConfiguration()
                        await loadBackups()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 600, height: 400)
        .onAppear {
            loadBackups()
        }
    }
    
    private func loadBackups() {
        Task {
            isLoading = true
            do {
                let loadedBackups = try await cloudSyncManager.getBackups()
                await MainActor.run {
                    self.backups = loadedBackups
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("MTMR: Error loading backups: \(error)")
            }
        }
    }
}

struct BackupRow: View {
    let backup: ConfigurationBackup
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(backup.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(backup.formattedDate) • \(backup.formattedSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Restore") {
                Task {
                    try? await cloudSyncManager.restoreConfiguration(from: backup)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct ShareManagerSheet: View {
    @State private var isPresented = true
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    @State private var shareEmails = ""
    @State private var isSharing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share Configuration")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Share with (comma-separated emails):")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("email1@example.com, email2@example.com", text: $shareEmails)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What will be shared:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Current TouchBar configuration")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Widget layouts and settings")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Custom themes and configurations")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Share Configuration") {
                    shareConfiguration()
                }
                .buttonStyle(.bordered)
                .disabled(shareEmails.isEmpty || isSharing)
                
                if isSharing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
    
    private func shareConfiguration() {
        let emails = shareEmails
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !emails.isEmpty else { return }
        
        isSharing = true
        
        Task {
            do {
                try await cloudSyncManager.shareConfiguration(with: emails)
                await MainActor.run {
                    isSharing = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isSharing = false
                }
                print("MTMR: Error sharing configuration: \(error)")
            }
        }
    }
}
