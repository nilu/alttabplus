import Cocoa
import os.log

class WindowManager {
    private let logger = os.Logger(subsystem: "com.pandey.AltTabPlus", category: "WindowManager")
    
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
    
    private func launchAppIfNeeded(_ bundleId: String?) -> NSRunningApplication? {
        guard let bundleId = bundleId else { return nil }
        
        // Check if app is already running
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            return runningApp
        }
        
        // Get the app URL from bundle ID
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            print("Could not find app with bundle ID: \(bundleId)")
            return nil
        }
        
        // Launch the app using new API
        var launchedApp: NSRunningApplication?
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        
        let semaphore = DispatchSemaphore(value: 0)
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            launchedApp = app
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2)
        
        return launchedApp
    }
    
    func switchToApp(for direction: DirectionalSettings.Direction) {
        guard let mapping = settings.mappings[direction] else { return }
        
        // Try to launch app if it's not running
        if let app = launchAppIfNeeded(mapping.bundleIdentifier) {
            print("Activating app: \(mapping.bundleIdentifier)")
            app.activate()
            
            // Special handling for Finder
            if mapping.bundleIdentifier == "com.apple.finder" {
                print("Found Finder, checking windows...")
                
                // Get all visible windows
                let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
                
                // Just check for any Finder window that's not the desktop
                let finderWindows = windowList.filter { window in
                    guard let pid = window[kCGWindowOwnerPID as String] as? pid_t,
                          let app = NSRunningApplication(processIdentifier: pid),
                          app.bundleIdentifier == "com.apple.finder",
                          let layer = window[kCGWindowLayer as String] as? Int,
                          layer == 0,  // Normal window layer
                          window[kCGWindowOwnerName as String] as? String == "Finder"  // Just check if it's a Finder window
                    else { return false }
                    return true
                }
                
                let hasVisibleWindows = !finderWindows.isEmpty
                print("🔍 DEBUG: Finder has visible windows: \(hasVisibleWindows)")
                
                if !hasVisibleWindows {
                    print("No Finder windows found, creating one...")
                    app.activate()
                } else {
                    print("Finder windows exist, just activating")
                    app.activate()
                }
            } else {
                app.activate()
            }
        } else {
            print("Failed to launch or activate app with bundle ID: \(mapping.bundleIdentifier)")
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
