//
//  AnalyticsDashboard.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 5D: Advanced Analytics - Analytics Dashboard.
//

import Cocoa
import SwiftUI

// MARK: - Analytics Dashboard

@MainActor
final class AnalyticsDashboard: ObservableObject {
    static let shared = AnalyticsDashboard()
    
    @Published var isVisible = false
    
    private var dashboardWindow: NSWindow?
    
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
    
    // MARK: - Private Methods
    
    private func createDashboardWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "MTMR Advanced Analytics Dashboard"
        window.center()
        window.setFrameAutosaveName("AnalyticsDashboardWindow")
        
        // Create SwiftUI view
        let dashboardView = AnalyticsDashboardView(
            onClose: { [weak self] in
                self?.closeDashboardWindow()
            }
        )
        
        let hostingView = NSHostingView(rootView: dashboardView)
        window.contentView = hostingView
        
        self.dashboardWindow = window
    }
    
    private func closeDashboardWindow() {
        dashboardWindow?.close()
        dashboardWindow = nil
        isVisible = false
    }
}

// MARK: - SwiftUI Views

struct AnalyticsDashboardView: View {
    let onClose: () -> Void
    
    @StateObject private var analyticsManager = AnalyticsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            dashboardHeader
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Performance Overview
                    performanceOverviewSection
                    
                    // Current Metrics
                    currentMetricsSection
                    
                    // Insights
                    insightsSection
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Close") {
                    onClose()
                }
                .keyboardShortcut(.escape)
            }
        }
    }
    
    private var dashboardHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Analytics Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Monitor performance, gain insights, and optimize your TouchBar experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Analytics Active")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        
                        Text("Real-time monitoring")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
    
    private var performanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickStatCard(
                    title: "Performance Score",
                    value: "85.2",
                    icon: "speedometer",
                    color: .blue,
                    subtitle: "out of 100"
                )
                
                QuickStatCard(
                    title: "Data Points",
                    value: "\(analyticsManager.historicalData.count)",
                    icon: "chart.bar",
                    color: .green,
                    subtitle: "collected"
                )
                
                QuickStatCard(
                    title: "TouchBar Interactions",
                    value: "1,247",
                    icon: "touchid",
                    color: .orange,
                    subtitle: "total"
                )
                
                QuickStatCard(
                    title: "Recommendations",
                    value: "\(analyticsManager.recommendations.count)",
                    icon: "checklist",
                    color: .purple,
                    subtitle: "available"
                )
            }
        }
    }
    
    private var currentMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current System Status")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "CPU Usage",
                    value: String(format: "%.1f%%", analyticsManager.currentMetrics.cpuUsage),
                    icon: "cpu",
                    color: .red
                )
                
                MetricCard(
                    title: "Memory Usage",
                    value: String(format: "%.1f%%", analyticsManager.currentMetrics.memoryUsage),
                    icon: "memorychip",
                    color: .blue
                )
                
                MetricCard(
                    title: "Disk Usage",
                    value: String(format: "%.1f%%", analyticsManager.currentMetrics.diskUsage),
                    icon: "externaldrive",
                    color: .green
                )
            }
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Insights")
                .font(.headline)
                .fontWeight(.bold)
            
            if analyticsManager.insights.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No insights available yet")
                        .font(.headline)
                    
                    Text("Insights will appear as we collect more data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(analyticsManager.insights) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
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

struct InsightRow: View {
    let insight: AnalyticsInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(.accentColor)
                    .font(.subheadline)
                
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: insight.severity.icon)
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Recommendation: \(insight.recommendation)")
                .font(.caption)
                .foregroundColor(.accentColor)
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
