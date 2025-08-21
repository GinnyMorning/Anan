import AppKit
import Foundation

class EnhancedWidgetBase: NSCustomTouchBarItem {
    
    // MARK: - Performance Properties
    
    private var updateTimer: Timer?
    private var lastUpdateTime: Date = Date.distantPast
    private var updateInterval: TimeInterval = 1.0
    private var isActive = false
    
    // MARK: - Caching System
    
    private var valueCache: [String: Any] = [:]
    private var cacheExpiry: [String: Date] = [:]
    private let defaultCacheExpiry: TimeInterval = 300 // 5 minutes
    
    // MARK: - Permission Management
    
    private var permissionManager = EnhancedPermissionManager.shared
    
    // MARK: - Initialization
    
    override init(identifier: NSTouchBarItem.Identifier) {
        super.init(identifier: identifier)
        setupPerformanceMonitoring()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPerformanceMonitoring()
    }
    
    deinit {
        stopUpdates()
        cleanup()
    }
    
    // MARK: - Performance Setup
    
    private func setupPerformanceMonitoring() {
        // Monitor memory usage
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoryWarningReceived),
            name: NSApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Monitor app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Update Management
    
    func startUpdates(interval: TimeInterval) {
        updateInterval = interval
        isActive = true
        
        // Only start timer if not already running
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.performUpdate()
            }
            RunLoop.current.add(updateTimer!, forMode: .common)
        }
    }
    
    func stopUpdates() {
        isActive = false
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func pauseUpdates() {
        isActive = false
    }
    
    func resumeUpdates() {
        isActive = true
    }
    
    // MARK: - Caching System
    
    func cacheValue(_ value: Any, forKey key: String, expiry: TimeInterval? = nil) {
        let expiryTime = expiry ?? defaultCacheExpiry
        valueCache[key] = value
        cacheExpiry[key] = Date().addingTimeInterval(expiryTime)
    }
    
    func getCachedValue(forKey key: String) -> Any? {
        guard let expiryDate = cacheExpiry[key] else { return nil }
        
        if Date() < expiryDate {
            return valueCache[key]
        } else {
            // Cache expired, remove it
            valueCache.removeValue(forKey: key)
            cacheExpiry.removeValue(forKey: key)
            return nil
        }
    }
    
    func clearCache() {
        valueCache.removeAll()
        cacheExpiry.removeAll()
    }
    
    func clearExpiredCache() {
        let now = Date()
        let expiredKeys = cacheExpiry.compactMap { key, expiry in
            now >= expiry ? key : nil
        }
        
        for key in expiredKeys {
            valueCache.removeValue(forKey: key)
            cacheExpiry.removeValue(forKey: key)
        }
    }
    
    // MARK: - Permission Checking
    
    func checkPermission(for feature: String) -> Bool {
        return permissionManager.isPermissionGranted(for: feature)
    }
    
    func smartRequestPermission(for feature: String) -> Bool {
        return permissionManager.smartRequestPermission(for: feature)
    }
    
    // MARK: - Update Logic
    
    private func performUpdate() {
        guard isActive else { return }
        
        // Check if enough time has passed since last update
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdateTime)
        if timeSinceLastUpdate < updateInterval {
            return
        }
        
        // Clear expired cache before update
        clearExpiredCache()
        
        // Perform the actual update
        DispatchQueue.main.async { [weak self] in
            self?.updateWidget()
            self?.lastUpdateTime = Date()
        }
    }
    
    // MARK: - Subclass Override Methods
    
    func updateWidget() {
        // Override in subclasses
        fatalError("updateWidget() must be overridden in subclasses")
    }
    
    func setupWidget() {
        // Override in subclasses for initial setup
    }
    
    func cleanup() {
        // Override in subclasses for cleanup
    }
    
    // MARK: - Memory Management
    
    @objc private func memoryWarningReceived() {
        // Clear cache when memory is low
        clearCache()
        
        // Reduce update frequency temporarily
        if updateTimer != nil {
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval * 2, repeats: true) { [weak self] _ in
                self?.performUpdate()
            }
            RunLoop.current.add(updateTimer!, forMode: .common)
        }
    }
    
    // MARK: - App State Management
    
    @objc private func appDidBecomeActive() {
        resumeUpdates()
    }
    
    @objc private func appDidResignActive() {
        pauseUpdates()
    }
    
    // MARK: - Performance Monitoring
    
    func getPerformanceMetrics() -> [String: Any] {
        return [
            "isActive": isActive,
            "updateInterval": updateInterval,
            "lastUpdateTime": lastUpdateTime,
            "cacheSize": valueCache.count,
            "memoryUsage": getMemoryUsage()
        ]
    }
    
    private func getMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            return String(format: "%.2f MB", memoryUsageMB)
        }
        
        return "Unknown"
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error, context: String) {
        print("MTMR: Error in \(context): \(error.localizedDescription)")
        
        // Log error for debugging
        #if DEBUG
        print("MTMR: Error details: \(error)")
        #endif
    }
    
    // MARK: - Thread Safety
    
    func performOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
    
    func performOnBackgroundThread(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async(execute: block)
    }
}
