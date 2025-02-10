import Cocoa

class WindowManager {
    private var windows: [CGWindowID: NSRunningApplication] = [:]
    
    init() {
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
                  window[kCGWindowLayer as String] as? Int == 0
            else { continue }
            
            windows[windowID] = app
        }
    }
    
    func switchToWindow(at angle: Double) {
        updateWindowList()
        
        // TODO: Implement window selection based on angle
    }
} 