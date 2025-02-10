import Cocoa

class WindowManager {
    private var windows: [CGWindowID: WindowInfo] = [:]
    private var currentMouseLocation: NSPoint?
    private(set) var settings: DirectionalSettings
    
    struct WindowInfo {
        let app: NSRunningApplication
        let frame: CGRect
        let title: String?
    }
    
    init() {
        self.settings = DirectionalSettings.load()
        updateWindowList()
    }
    
    func updateWindowList() {
        windows.removeAll()
        
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        
        for window in windowList {
            guard let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                  let pid = window[kCGWindowOwnerPID as String] as? pid_t,
                  let app = NSRunningApplication(processIdentifier: pid),
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  window[kCGWindowLayer as String] as? Int == 0
            else { continue }
            
            let frame = CGRect(x: bounds["X"] ?? 0,
                             y: bounds["Y"] ?? 0,
                             width: bounds["Width"] ?? 0,
                             height: bounds["Height"] ?? 0)
            
            let title = window[kCGWindowName as String] as? String
            
            windows[windowID] = WindowInfo(app: app, frame: frame, title: title)
        }
        
        print("Found \(windows.count) windows")
    }
    
    private func launchAppIfNeeded(_ bundleId: String) -> NSRunningApplication? {
        // Check if app is already running
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            return runningApp
        }
        
        // If not running, try to launch it
        do {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            
            let runningApp = try NSWorkspace.shared.openApplication(
                withBundleIdentifier: bundleId,
                configuration: config
            )
            return runningApp
        } catch {
            print("Failed to launch app with bundle ID \(bundleId): \(error)")
            return nil
        }
    }
    
    func switchToApp(for direction: DirectionalSettings.Direction) {
        guard let mapping = settings.mappings[direction],
              let bundleId = mapping.bundleIdentifier else {
            return
        }
        
        // Try to launch app if it's not running
        if let app = launchAppIfNeeded(bundleId) {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }
    
    func updateSettings(_ newSettings: DirectionalSettings) {
        settings = newSettings
        NotificationCenter.default.post(
            name: NSNotification.Name("SettingsDidChange"),
            object: newSettings
        )
    }
} 