import Cocoa

class ScreenManager {
    static let shared = ScreenManager()
    
    private init() {}
    
    func getAllScreens() -> [NSScreen] {
        return NSScreen.screens
    }
    
    func getScreenContaining(point: NSPoint) -> NSScreen? {
        return NSScreen.screens.first { screen in
            NSMouseInRect(point, screen.frame, false)
        }
    }
    
    func getMainScreen() -> NSScreen? {
        return NSScreen.main
    }
    
    func getTotalScreenFrame() -> NSRect {
        return NSScreen.screens.reduce(NSRect.zero) { union, screen in
            union.union(screen.frame)
        }
    }
} 