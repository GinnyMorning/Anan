//
//  AnalyticsManager.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Phase 5D: Advanced Analytics - Analytics Manager.
//

import Cocoa
import Foundation
import Combine

// MARK: - Analytics Manager

@MainActor
final class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var isEnabled = true
    @Published var currentMetrics: PerformanceMetrics = PerformanceMetrics(
        timestamp: Date(),
        cpuUsage: 0.0,
        memoryUsage: 0.0,
        diskUsage: 0.0,
        networkUsage: NetworkUsage(bytesIn: 0, bytesOut: 0, packetsIn: 0, packetsOut: 0),
        touchBarInteractions: 0,
        widgetPerformance: [],
        systemPerformance: SystemPerformanceMetrics(uptime: 0, processCount: 0, thermalState: 0, powerState: "normal")
    )
    @Published var historicalData: [PerformanceMetrics] = []
    @Published var insights: [AnalyticsInsight] = []
    @Published var recommendations: [ConfigurationRecommendation] = []
    
    private var metricsTimer: Timer?
    private var dataCollectionTimer: Timer?
    private let maxHistoricalDataPoints = 1000
    private let metricsCollectionInterval: TimeInterval = 5.0 // 5 seconds
    private let dataCollectionInterval: TimeInterval = 300.0 // 5 minutes
    
    private init() {
        // Load historical data
        loadHistoricalData()
        
        // Start metrics collection
        startMetricsCollection()
        
        // Start data collection
        startDataCollection()
        
        // Generate initial insights
        generateInsights()
    }
    
    // MARK: - Public Methods
    
    func startMetricsCollection() {
        guard isEnabled else { return }
        
        metricsTimer?.invalidate()
        metricsTimer = Timer.scheduledTimer(withTimeInterval: metricsCollectionInterval, repeats: true) { [weak self] _ in
            self?.collectCurrentMetrics()
        }
        
        // Collect initial metrics
        collectCurrentMetrics()
    }
    
    func stopMetricsCollection() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }
    
    func startDataCollection() {
        guard isEnabled else { return }
        
        dataCollectionTimer?.invalidate()
        dataCollectionTimer = Timer.scheduledTimer(withTimeInterval: dataCollectionInterval, repeats: true) { [weak self] _ in
            self?.collectAndStoreMetrics()
        }
        
        // Collect initial data
        collectAndStoreMetrics()
    }
    
    func stopDataCollection() {
        dataCollectionTimer?.invalidate()
        dataCollectionTimer = nil
    }
    
    func generateInsights() {
        guard !historicalData.isEmpty else { return }
        
        var newInsights: [AnalyticsInsight] = []
        
        // Performance insights
        if let performanceInsight = generatePerformanceInsight() {
            newInsights.append(performanceInsight)
        }
        
        // Usage pattern insights
        if let usageInsight = generateUsagePatternInsight() {
            newInsights.append(usageInsight)
        }
        
        // Configuration insights
        if let configurationInsight = generateConfigurationInsight() {
            newInsights.append(configurationInsight)
        }
        
        // Resource usage insights
        if let resourceInsight = generateResourceUsageInsight() {
            newInsights.append(resourceInsight)
        }
        
        insights = newInsights
    }
    
    func generateRecommendations() {
        guard !historicalData.isEmpty else { return }
        
        var newRecommendations: [ConfigurationRecommendation] = []
        
        // Performance recommendations
        if let performanceRec = generatePerformanceRecommendation() {
            newRecommendations.append(performanceRec)
        }
        
        // Configuration recommendations
        if let configRec = generateConfigurationRecommendation() {
            newRecommendations.append(configRec)
        }
        
        // Resource optimization recommendations
        if let resourceRec = generateResourceOptimizationRecommendation() {
            newRecommendations.append(resourceRec)
        }
        
        recommendations = newRecommendations
    }
    
    func exportAnalyticsData() -> Data? {
        let exportData = AnalyticsExportData(
            exportDate: Date(),
            historicalData: historicalData,
            insights: insights,
            recommendations: recommendations,
            summary: generateAnalyticsSummary()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func clearHistoricalData() {
        historicalData.removeAll()
        saveHistoricalData()
        generateInsights()
        generateRecommendations()
    }
    
    // MARK: - Private Methods
    
    private func collectCurrentMetrics() {
        let metrics = PerformanceMetrics(
            timestamp: Date(),
            cpuUsage: getCurrentCPUUsage(),
            memoryUsage: getCurrentMemoryUsage(),
            diskUsage: getCurrentDiskUsage(),
            networkUsage: getCurrentNetworkUsage(),
            touchBarInteractions: getTouchBarInteractionCount(),
            widgetPerformance: getWidgetPerformanceMetrics(),
            systemPerformance: getSystemPerformanceMetrics()
        )
        
        currentMetrics = metrics
    }
    
    private func collectAndStoreMetrics() {
        let metrics = currentMetrics
        
        // Add to historical data
        historicalData.append(metrics)
        
        // Maintain data size limit
        if historicalData.count > maxHistoricalDataPoints {
            historicalData.removeFirst(historicalData.count - maxHistoricalDataPoints)
        }
        
        // Save to persistent storage
        saveHistoricalData()
        
        // Generate new insights and recommendations
        generateInsights()
        generateRecommendations()
    }
    
    private func getCurrentCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: UInt32 = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return 0.0
        }
        
        defer { 
            let deallocateResult = vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), vm_size_t(numCpuInfo * 4))
            if deallocateResult != KERN_SUCCESS {
                print("MTMR: Failed to deallocate CPU info: \(deallocateResult)")
            }
        }
        
        var totalUsage: Double = 0.0
        for i in 0..<Int(numCpus) {
            let user = Double(cpuInfo[i * 4])
            let system = Double(cpuInfo[i * 4 + 1])
            let idle = Double(cpuInfo[i * 4 + 2])
            let nice = Double(cpuInfo[i * 4 + 3])
            
            let total = user + system + idle + nice
            let usage = (user + system + nice) / total
            totalUsage += usage
        }
        
        return (totalUsage / Double(numCpus)) * 100.0
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0.0 }
        
        let usedMemory = Double(info.resident_size)
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        
        return (usedMemory / totalMemory) * 100.0
    }
    
    private func getCurrentDiskUsage() -> Double {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: homeDirectory.path)
            let freeSpace = attributes[.systemFreeSize] as? NSNumber ?? 0
            let totalSpace = attributes[.systemSize] as? NSNumber ?? 1
            
            let usedSpace = totalSpace.doubleValue - freeSpace.doubleValue
            return (usedSpace / totalSpace.doubleValue) * 100.0
        } catch {
            return 0.0
        }
    }
    
    private func getCurrentNetworkUsage() -> NetworkUsage {
        // Simulate network usage for now
        // In production, this would use Network framework or system calls
        return NetworkUsage(
            bytesIn: Int.random(in: 1000...10000),
            bytesOut: Int.random(in: 500...5000),
            packetsIn: Int.random(in: 10...100),
            packetsOut: Int.random(in: 5...50)
        )
    }
    
    private func getTouchBarInteractionCount() -> Int {
        // This would integrate with the TouchBar system
        // For now, return a simulated value
        return Int.random(in: 0...10)
    }
    
    private func getWidgetPerformanceMetrics() -> [WidgetPerformanceMetric] {
        // This would integrate with the widget system
        // For now, return simulated metrics
        return [
            WidgetPerformanceMetric(
                widgetID: "brightness",
                renderTime: Double.random(in: 0.001...0.01),
                memoryUsage: Int.random(in: 1024...8192),
                isActive: true
            ),
            WidgetPerformanceMetric(
                widgetID: "volume",
                renderTime: Double.random(in: 0.001...0.01),
                memoryUsage: Int.random(in: 1024...8192),
                isActive: true
            ),
            WidgetPerformanceMetric(
                widgetID: "dnd",
                renderTime: Double.random(in: 0.001...0.01),
                memoryUsage: Int.random(in: 1024...8192),
                isActive: false
            )
        ]
    }
    
    private func getSystemPerformanceMetrics() -> SystemPerformanceMetrics {
        return SystemPerformanceMetrics(
            uptime: ProcessInfo.processInfo.systemUptime,
            processCount: UInt32(ProcessInfo.processInfo.activeProcessorCount),
            thermalState: ProcessInfo.processInfo.thermalState.rawValue,
            powerState: getCurrentPowerState()
        )
    }
    
    private func getCurrentPowerState() -> String {
        // This would integrate with IOKit for power state
        // For now, return a simulated value
        return "AC Power"
    }
    
    private func generatePerformanceInsight() -> AnalyticsInsight? {
        guard historicalData.count >= 10 else { return nil }
        
        let recentMetrics = Array(historicalData.suffix(10))
        let avgCPU = recentMetrics.map { $0.cpuUsage }.reduce(0, +) / Double(recentMetrics.count)
        let avgMemory = recentMetrics.map { $0.memoryUsage }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgCPU > 80.0 {
            return AnalyticsInsight(
                type: .performance,
                title: "High CPU Usage Detected",
                description: "Average CPU usage is \(String(format: "%.1f", avgCPU))% over the last 50 seconds",
                severity: .warning,
                recommendation: "Consider reducing widget complexity or disabling unused widgets",
                timestamp: Date()
            )
        }
        
        if avgMemory > 70.0 {
            return AnalyticsInsight(
                type: .performance,
                title: "High Memory Usage Detected",
                description: "Average memory usage is \(String(format: "%.1f", avgMemory))% over the last 50 seconds",
                severity: .warning,
                recommendation: "Consider restarting MTMR or optimizing widget memory usage",
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func generateUsagePatternInsight() -> AnalyticsInsight? {
        guard historicalData.count >= 20 else { return nil }
        
        let recentMetrics = Array(historicalData.suffix(20))
        let touchBarInteractions = recentMetrics.map { $0.touchBarInteractions }
        let avgInteractions = touchBarInteractions.reduce(0, +) / touchBarInteractions.count
        
        if avgInteractions > 5 {
            return AnalyticsInsight(
                type: .usage,
                title: "High TouchBar Activity",
                description: "Average of \(String(format: "%.1f", avgInteractions)) TouchBar interactions per 5 seconds",
                severity: .info,
                recommendation: "Your TouchBar is being actively used. Consider adding more widgets for efficiency",
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func generateConfigurationInsight() -> AnalyticsInsight? {
        guard historicalData.count >= 5 else { return nil }
        
        let recentMetrics = Array(historicalData.suffix(5))
        let activeWidgets = recentMetrics.flatMap { $0.widgetPerformance }.filter { $0.isActive }
        
        if activeWidgets.count < 3 {
            return AnalyticsInsight(
                type: .configuration,
                title: "Low Widget Utilization",
                description: "Only \(activeWidgets.count) widgets are currently active",
                severity: .info,
                recommendation: "Consider adding more widgets to maximize TouchBar utility",
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func generateResourceUsageInsight() -> AnalyticsInsight? {
        guard historicalData.count >= 15 else { return nil }
        
        let recentMetrics = Array(historicalData.suffix(15))
        let avgDiskUsage = recentMetrics.map { $0.diskUsage }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgDiskUsage > 90.0 {
            return AnalyticsInsight(
                type: .resource,
                title: "High Disk Usage",
                description: "Disk usage is \(String(format: "%.1f", avgDiskUsage))%",
                severity: .warning,
                recommendation: "Consider freeing up disk space to improve system performance",
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func generatePerformanceRecommendation() -> ConfigurationRecommendation? {
        guard historicalData.count >= 10 else { return nil }
        
        let recentMetrics = Array(historicalData.suffix(10))
        let avgCPU = recentMetrics.map { $0.cpuUsage }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgCPU > 70.0 {
            return ConfigurationRecommendation(
                type: .performance,
                title: "Optimize Widget Performance",
                description: "High CPU usage detected. Consider optimizing widget configurations",
                priority: .high,
                action: "Review and optimize widget settings",
                estimatedImpact: "Reduce CPU usage by 15-25%",
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func generateConfigurationRecommendation() -> ConfigurationRecommendation? {
        guard historicalData.count >= 5 else { return nil }
        
        let recentMetrics = Array(historicalData.suffix(5))
        let activeWidgets = recentMetrics.flatMap { $0.widgetPerformance }.filter { $0.isActive }
        
        if activeWidgets.count < 2 {
            return ConfigurationRecommendation(
                type: .configuration,
                title: "Add More Widgets",
                description: "Low widget utilization detected",
                priority: .medium,
                action: "Browse and add useful widgets",
                estimatedImpact: "Increase TouchBar utility by 40-60%",
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func generateResourceOptimizationRecommendation() -> ConfigurationRecommendation? {
        guard historicalData.count >= 15 else { return nil }
        
        let recentMetrics = Array(historicalData.suffix(15))
        let avgMemory = recentMetrics.map { $0.memoryUsage }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgMemory > 60.0 {
            return ConfigurationRecommendation(
                type: .resource,
                title: "Optimize Memory Usage",
                description: "High memory usage detected",
                priority: .medium,
                action: "Review memory-intensive widgets",
                estimatedImpact: "Reduce memory usage by 10-20%",
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func generateAnalyticsSummary() -> AnalyticsSummary {
        guard !historicalData.isEmpty else {
            return AnalyticsSummary(
                totalDataPoints: 0,
                dataCollectionPeriod: 0,
                averageCPUUsage: 0,
                averageMemoryUsage: 0,
                totalTouchBarInteractions: 0,
                performanceScore: 0,
                recommendationsCount: recommendations.count
            )
        }
        
        let totalDataPoints = historicalData.count
        let dataCollectionPeriod = historicalData.last?.timestamp.timeIntervalSince(historicalData.first?.timestamp ?? Date()) ?? 0
        let averageCPUUsage = historicalData.map { $0.cpuUsage }.reduce(0, +) / Double(historicalData.count)
        let averageMemoryUsage = historicalData.map { $0.memoryUsage }.reduce(0, +) / Double(historicalData.count)
        let totalTouchBarInteractions = historicalData.map { $0.touchBarInteractions }.reduce(0, +)
        
        // Calculate performance score (0-100)
        let cpuScore = max(0, 100 - averageCPUUsage)
        let memoryScore = max(0, 100 - averageMemoryUsage)
        let performanceScore = (cpuScore + memoryScore) / 2
        
        return AnalyticsSummary(
            totalDataPoints: totalDataPoints,
            dataCollectionPeriod: dataCollectionPeriod,
            averageCPUUsage: averageCPUUsage,
            averageMemoryUsage: averageMemoryUsage,
            totalTouchBarInteractions: totalTouchBarInteractions,
            performanceScore: performanceScore,
            recommendationsCount: recommendations.count
        )
    }
    
    private func saveHistoricalData() {
        // Save to UserDefaults for persistence
        if let data = try? JSONEncoder().encode(historicalData) {
            UserDefaults.standard.set(data, forKey: "MTMR_AnalyticsHistoricalData")
        }
    }
    
    private func loadHistoricalData() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "MTMR_AnalyticsHistoricalData"),
           let loadedData = try? JSONDecoder().decode([PerformanceMetrics].self, from: data) {
            historicalData = loadedData
        }
    }
}

// MARK: - Models

struct PerformanceMetrics: Codable, Identifiable {
    var id = UUID()
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let networkUsage: NetworkUsage
    let touchBarInteractions: Int
    let widgetPerformance: [WidgetPerformanceMetric]
    let systemPerformance: SystemPerformanceMetrics
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

struct NetworkUsage: Codable {
    let bytesIn: Int
    let bytesOut: Int
    let packetsIn: Int
    let packetsOut: Int
    
    var formattedBytesIn: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesIn))
    }
    
    var formattedBytesOut: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesOut))
    }
}

struct WidgetPerformanceMetric: Codable, Identifiable {
    var id = UUID()
    let widgetID: String
    let renderTime: Double
    let memoryUsage: Int
    let isActive: Bool
    
    var formattedRenderTime: String {
        return String(format: "%.3fms", renderTime * 1000)
    }
    
    var formattedMemoryUsage: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryUsage))
    }
}

struct SystemPerformanceMetrics: Codable {
    let uptime: TimeInterval
    let processCount: UInt32
    let thermalState: Int
    let powerState: String
    
    var formattedUptime: String {
        let hours = Int(uptime) / 3600
        let minutes = Int(uptime) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

struct AnalyticsInsight: Codable, Identifiable {
    var id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let recommendation: String
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

enum InsightType: String, Codable, CaseIterable {
    case performance = "Performance"
    case usage = "Usage"
    case configuration = "Configuration"
    case resource = "Resource"
    
    var icon: String {
        switch self {
        case .performance: return "speedometer"
        case .usage: return "chart.bar"
        case .configuration: return "slider.horizontal.3"
        case .resource: return "externaldrive"
        }
    }
    
    var color: String {
        switch self {
        case .performance: return "#FF6B6B"
        case .usage: return "#4ECDC4"
        case .configuration: return "#45B7D1"
        case .resource: return "#96CEB4"
        }
    }
}

enum InsightSeverity: String, Codable, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        }
    }
    
    var color: String {
        switch self {
        case .info: return "#4ECDC4"
        case .warning: return "#FFE66D"
        case .critical: return "#FF6B6B"
        }
    }
}

struct ConfigurationRecommendation: Codable, Identifiable {
    var id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let priority: RecommendationPriority
    let action: String
    let estimatedImpact: String
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

enum RecommendationType: String, Codable, CaseIterable {
    case performance = "Performance"
    case configuration = "Configuration"
    case resource = "Resource"
    
    var icon: String {
        switch self {
        case .performance: return "speedometer"
        case .configuration: return "slider.horizontal.3"
        case .resource: return "externaldrive"
        }
    }
}

enum RecommendationPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#96CEB4"
        case .medium: return "#FFE66D"
        case .high: return "#FF6B6B"
        }
    }
}

struct AnalyticsExportData: Codable {
    let exportDate: Date
    let historicalData: [PerformanceMetrics]
    let insights: [AnalyticsInsight]
    let recommendations: [ConfigurationRecommendation]
    let summary: AnalyticsSummary
}

struct AnalyticsSummary: Codable {
    let totalDataPoints: Int
    let dataCollectionPeriod: TimeInterval
    let averageCPUUsage: Double
    let averageMemoryUsage: Double
    let totalTouchBarInteractions: Int
    let performanceScore: Double
    let recommendationsCount: Int
    
    var formattedDataCollectionPeriod: String {
        let hours = Int(dataCollectionPeriod) / 3600
        let minutes = Int(dataCollectionPeriod) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var formattedPerformanceScore: String {
        return String(format: "%.1f", performanceScore)
    }
}
