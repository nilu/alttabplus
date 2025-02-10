import Cocoa

class MouseTracker {
    private let windowManager: WindowManager
    private var startPoint: NSPoint?
    private var isTracking = false
    private var eventMonitor: Any?
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        setupEventMonitor()
    }
    
    private func setupEventMonitor() {
        // Monitor Alt (Option) key press and mouse events
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handleEvent(event)
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            if event.modifierFlags.contains(.option) {
                startTracking()
            } else {
                stopTracking()
            }
            
        case .leftMouseDown:
            if isTracking {
                startPoint = event.locationInWindow
            }
            
        case .leftMouseDragged:
            if let start = startPoint {
                let current = event.locationInWindow
                let angle = calculateAngle(from: start, to: current)
                windowManager.switchToWindow(at: angle)
            }
            
        case .leftMouseUp:
            startPoint = nil
            
        default:
            break
        }
    }
    
    private func startTracking() {
        isTracking = true
    }
    
    private func stopTracking() {
        isTracking = false
        startPoint = nil
    }
    
    private func calculateAngle(from start: NSPoint, to end: NSPoint) -> Double {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return atan2(dy, dx)
    }
} 