import Cocoa

class MouseTracker {
    private let windowManager: WindowManager
    private var startPoint: NSPoint?
    private var isTracking = false
    private var eventMonitor: Any?
    private let overlay: DirectionalOverlay
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        self.overlay = DirectionalOverlay(settings: windowManager.settings)
        setupEventMonitor()
        
        // Add observer for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange(_:)),
            name: NSNotification.Name("SettingsDidChange"),
            object: nil
        )
    }
    
    @objc private func settingsDidChange(_ notification: Notification) {
        if let newSettings = notification.object as? DirectionalSettings {
            overlay.updateSettings(newSettings)
        }
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
                overlay.show()
            } else {
                stopTracking()
                overlay.hide()
            }
            
        case .leftMouseDown:
            if isTracking {
                startPoint = event.locationInWindow
            }
            
        case .leftMouseDragged:
            if let start = startPoint {
                let current = event.locationInWindow
                let angle = calculateAngle(from: start, to: current)
                overlay.updateSelection(angle)
                windowManager.switchToApp(for: DirectionalSettings.Direction.from(angle: angle))
            }
            
        case .leftMouseUp:
            startPoint = nil
            overlay.updateSelection(nil)
            
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