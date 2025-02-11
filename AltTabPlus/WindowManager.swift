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
        // Check if we have a valid bundle ID
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
        
        // Launch the app
        let options: NSWorkspace.LaunchOptions = [.default, .withoutActivation]
        var launchedApp: NSRunningApplication?
        
        do {
            launchedApp = try NSWorkspace.shared.launchApplication(
                at: appURL,
                options: options,
                configuration: [:]
            )
        } catch {
            print("Failed to launch app: \(error)")
            return nil
        }
        
        return launchedApp
    }
    
    func switchToApp(for direction: DirectionalSettings.Direction) {
        guard let mapping = settings.mappings[direction] else { return }
        
        // Try to launch app if it's not running
        if let app = launchAppIfNeeded(mapping.bundleIdentifier) {
            print("🔍 DEBUG: Activating app: \(mapping.bundleIdentifier ?? "unknown")")
            
            // Special handling for Finder
            if mapping.bundleIdentifier == "com.apple.finder" {
                print("🔍 DEBUG: Found Finder, checking windows...")
                
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
                    print("🔍 DEBUG: No Finder windows found, creating one...")
                    // First activate Finder
                    app.activate(options: .activateIgnoringOtherApps)
                    // Then create a new window with Command+N
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let source = CGEventSource(stateID: .combinedSessionState)
                        
                        // Create Command down event
                        let flagsDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
                        flagsDown?.flags = .maskCommand
                        
                        // Create 'n' key down event
                        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x2D, keyDown: true)
                        keyDown?.flags = .maskCommand
                        
                        // Create 'n' key up event
                        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x2D, keyDown: false)
                        keyUp?.flags = .maskCommand
                        
                        // Create Command up event
                        let flagsUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
                        
                        // Post the events
                        flagsDown?.post(tap: .cghidEventTap)
                        keyDown?.post(tap: .cghidEventTap)
                        keyUp?.post(tap: .cghidEventTap)
                        flagsUp?.post(tap: .cghidEventTap)
                    }
                } else {
                    print("🔍 DEBUG: Finder windows exist, just activating")
                    app.activate(options: .activateIgnoringOtherApps)
                }
            } else {
                // Normal app activation
                app.activate(options: .activateIgnoringOtherApps)
            }
        } else {
            print("Failed to launch or activate app with bundle ID: \(mapping.bundleIdentifier ?? "unknown")")
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
