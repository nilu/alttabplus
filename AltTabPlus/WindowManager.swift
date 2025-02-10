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
    
    func switchToWindow(at angle: Double) {
        let direction = DirectionalSettings.Direction.from(angle: angle)
        
        guard let mapping = settings.mappings[direction],
              let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == mapping.bundleIdentifier })
        else { return }
        
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }
    
    func updateSettings(_ newSettings: DirectionalSettings) {
        settings = newSettings
    }
} 