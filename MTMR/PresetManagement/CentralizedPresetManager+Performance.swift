//
//  CentralizedPresetManager+Performance.swift
//  MTMR
//
//  Performance monitoring and optimization for CentralizedPresetManager
//

import Foundation

// MARK: - Performance Metrics

struct PerformanceMetrics {
    let operationName: String
    let duration: TimeInterval
    let timestamp: Date
    let success: Bool
    let errorMessage: String?
    
    var formattedDuration: String {
        return String(format: "%.3fs", duration)
    }
}

// MARK: - Performance Monitor

@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var recentMetrics: [PerformanceMetrics] = []
    @Published var isMonitoringEnabled = true
    
    private let maxStoredMetrics = 100
    private let performanceThreshold: TimeInterval = 0.1 // 100ms threshold
    
    private init() {}
    
    func recordOperation(_ operationName: String, duration: TimeInterval, success: Bool, errorMessage: String? = nil) {
        guard isMonitoringEnabled else { return }
        
        let metric = PerformanceMetrics(
            operationName: operationName,
            duration: duration,
            timestamp: Date(),
            success: success,
            errorMessage: errorMessage
        )
        
        DispatchQueue.main.async {
            self.recentMetrics.append(metric)
            
            // Keep only recent metrics
            if self.recentMetrics.count > self.maxStoredMetrics {
                self.recentMetrics.removeFirst()
            }
            
            // Log slow operations
            if duration > self.performanceThreshold {
                print("MTMR: ⚠️ Slow operation detected: \(operationName) took \(metric.formattedDuration)")
            }
        }
    }
    
    func getAverageDuration(for operationName: String) -> TimeInterval {
        let relevantMetrics = recentMetrics.filter { $0.operationName == operationName && $0.success }
        guard !relevantMetrics.isEmpty else { return 0 }
        
        let totalDuration = relevantMetrics.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(relevantMetrics.count)
    }
    
    func getPerformanceReport() -> String {
        var report = "MTMR Performance Report\n"
        report += "========================\n\n"
        
        let operations = Set(recentMetrics.map { $0.operationName })
        
        for operation in operations.sorted() {
            let avgDuration = getAverageDuration(for: operation)
            let successCount = recentMetrics.filter { $0.operationName == operation && $0.success }.count
            let totalCount = recentMetrics.filter { $0.operationName == operation }.count
            let successRate = totalCount > 0 ? Double(successCount) / Double(totalCount) * 100 : 0
            
            report += "\(operation):\n"
            report += "  Average Duration: \(String(format: "%.3fs", avgDuration))\n"
            report += "  Success Rate: \(String(format: "%.1f%%", successRate))\n"
            report += "  Total Operations: \(totalCount)\n\n"
        }
        
        return report
    }
    
    func clearMetrics() {
        recentMetrics.removeAll()
    }
}

// MARK: - CentralizedPresetManager Performance Extensions

extension CentralizedPresetManager {
    
    /// Performance-monitored version of addWidget
    func addWidgetWithPerformanceTracking(_ widget: WidgetDescriptor) -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = addWidget(widget)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        PerformanceMonitor.shared.recordOperation(
            "addWidget",
            duration: duration,
            success: result,
            errorMessage: result ? nil : "Widget addition failed"
        )
        
        return result
    }
    
    /// Performance-monitored version of removeLastWidget
    func removeLastWidgetWithPerformanceTracking() -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = removeLastWidget()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        PerformanceMonitor.shared.recordOperation(
            "removeLastWidget",
            duration: duration,
            success: result,
            errorMessage: result ? nil : "Widget removal failed"
        )
        
        return result
    }
    
    /// Performance-monitored version of duplicateLastWidget
    func duplicateLastWidgetWithPerformanceTracking() -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = duplicateLastWidget()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        PerformanceMonitor.shared.recordOperation(
            "duplicateLastWidget",
            duration: duration,
            success: result,
            errorMessage: result ? nil : "Widget duplication failed"
        )
        
        return result
    }
    
    /// Performance-monitored version of loadPreset
    func loadPresetWithPerformanceTracking(_ presetName: String) -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = loadPreset(presetName)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        PerformanceMonitor.shared.recordOperation(
            "loadPreset",
            duration: duration,
            success: result,
            errorMessage: result ? nil : "Preset loading failed"
        )
        
        return result
    }
    
    /// Get performance insights for optimization
    func getPerformanceInsights() -> String {
        return PerformanceMonitor.shared.getPerformanceReport()
    }
    
    /// Check if any operations are performing poorly
    func hasPerformanceIssues() -> Bool {
        let slowOperations = PerformanceMonitor.shared.recentMetrics.filter { 
            $0.duration > PerformanceMonitor.shared.performanceThreshold 
        }
        return !slowOperations.isEmpty
    }
    
    /// Optimize performance by clearing old metrics
    func optimizePerformance() {
        PerformanceMonitor.shared.clearMetrics()
        print("MTMR: Performance metrics cleared for optimization")
    }
}

// MARK: - Performance Monitoring UI

struct PerformanceMonitorView: View {
    @ObservedObject var performanceMonitor = PerformanceMonitor.shared
    @State private var showingReport = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance Monitor")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Toggle("Enable Monitoring", isOn: $performanceMonitor.isMonitoringEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            if performanceMonitor.recentMetrics.isEmpty {
                Text("No performance data available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Operations:")
                        .font(.headline)
                    
                    ForEach(performanceMonitor.recentMetrics.suffix(5), id: \.timestamp) { metric in
                        HStack {
                            Text(metric.operationName)
                                .font(.monospaced)
                            
                            Spacer()
                            
                            Text(metric.formattedDuration)
                                .font(.monospaced)
                                .foregroundColor(metric.duration > 0.1 ? .orange : .green)
                            
                            if metric.success {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack {
                Button("View Full Report") {
                    showingReport = true
                }
                
                Button("Clear Metrics") {
                    performanceMonitor.clearMetrics()
                }
                
                Spacer()
                
                if CentralizedPresetManager.shared.hasPerformanceIssues() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Performance issues detected")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingReport) {
            VStack {
                Text("Performance Report")
                    .font(.title)
                    .padding()
                
                ScrollView {
                    Text(CentralizedPresetManager.shared.getPerformanceInsights())
                        .font(.monospaced)
                        .padding()
                }
                
                Button("Close") {
                    showingReport = false
                }
                .padding()
            }
            .frame(width: 500, height: 400)
        }
    }
}
