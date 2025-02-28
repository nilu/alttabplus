import Cocoa

class DirectionalOverlay {
    private var settings: DirectionalSettings
    private var overlayWindows: [NSScreen: OverlayWindow] = [:]
    
    init(settings: DirectionalSettings) {
        self.settings = settings
        createOverlayWindows()
    }
    
    private func createOverlayWindows() {
        // Clear existing windows
        overlayWindows.removeAll()
        
        // Create a window for each screen
        for (index, screen) in NSScreen.screens.enumerated() {
            let window = OverlayWindow(
                settings: settings,
                screen: screen,
                screenNumber: index + 1
            )
            overlayWindows[screen] = window
        }
    }
    
    func show() {
        overlayWindows.values.forEach { $0.orderFront(nil) }
    }
    
    func hide() {
        overlayWindows.values.forEach { $0.orderOut(nil) }
    }
    
    func updateSelection(_ angle: Double?) {
        overlayWindows.values.forEach { $0.updateSelection(angle) }
    }
    
    func updateSettings(_ newSettings: DirectionalSettings) {
        self.settings = newSettings
        overlayWindows.values.forEach { $0.updateSettings(newSettings) }
    }
    
    func updatePosition(to mouseLocation: NSPoint) {
        // Only update the window for the screen containing the mouse
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            overlayWindows[screen]?.updatePosition(to: mouseLocation)
        }
    }
}

// New class to represent each screen's overlay window
class OverlayWindow: NSWindow {
    private var settings: DirectionalSettings
    private var selectedDirection: DirectionalSettings.Direction?
    private var directionViews: [DirectionalSettings.Direction: NSImageView] = [:]
    private let screenNumber: Int
    
    init(settings: DirectionalSettings, screen: NSScreen, screenNumber: Int) {
        self.settings = settings
        self.screenNumber = screenNumber
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        
        // Set up the content view
        let overlayView = DirectionalOverlayView(settings: settings, screenNumber: screenNumber)
        self.contentView = overlayView
        
        // Create image views for each direction
        setupDirectionViews(in: overlayView)
    }
    
    private func setupDirectionViews(in overlayView: DirectionalOverlayView) {
        let center = NSPoint(x: overlayView.bounds.midX, y: overlayView.bounds.midY)
        let radius: CGFloat = 80 // Adjusted to match new wheel size
        
        for direction in DirectionalSettings.Direction.allCases {
            let angle = direction.angle * .pi / 180
            let x = center.x + radius * cos(CGFloat(angle))
            let y = center.y + radius * sin(CGFloat(angle))
            
            let imageView = NSImageView(frame: NSRect(x: x - 16, y: y - 16, width: 32, height: 32))
            imageView.imageScaling = .scaleProportionallyUpOrDown
            overlayView.addSubview(imageView)
            directionViews[direction] = imageView
        }
    }
    
    func updateSelection(_ angle: Double?) {
        guard let contentView = contentView as? DirectionalOverlayView else { return }
        
        if let angle = angle {
            selectedDirection = DirectionalSettings.Direction.from(angle: angle)
        } else {
            selectedDirection = nil
        }
        
        contentView.selectedDirection = selectedDirection
        contentView.needsDisplay = true
    }
    
    func updateSettings(_ newSettings: DirectionalSettings) {
        self.settings = newSettings
        if let contentView = contentView as? DirectionalOverlayView {
            contentView.updateSettings(newSettings)
            contentView.needsDisplay = true
        }
    }
    
    func updatePosition(to mouseLocation: NSPoint) {
        guard let overlayView = contentView as? DirectionalOverlayView,
              let window = overlayView.window else { return }
        
        // Convert screen coordinates to window coordinates
        let windowPoint = window.convertPoint(fromScreen: mouseLocation)
        overlayView.centerPoint = windowPoint
        overlayView.needsDisplay = true
        
        // Update direction views positions using the converted point
        let radius: CGFloat = 100
        for (direction, imageView) in directionViews {
            let angle = direction.angle * .pi / 180
            let x = windowPoint.x + radius * cos(CGFloat(angle))
            let y = windowPoint.y + radius * sin(CGFloat(angle))
            imageView.frame = NSRect(x: x - 25, y: y - 25, width: 50, height: 50)
        }
    }
}

class DirectionalOverlayView: NSView {
    private var settings: DirectionalSettings
    private let screenNumber: Int
    var selectedDirection: DirectionalSettings.Direction?
    var centerPoint: NSPoint?
    
    init(settings: DirectionalSettings, screenNumber: Int) {
        self.settings = settings
        self.screenNumber = screenNumber
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw screen number
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 24, weight: .bold)
        ]
        let text = "Screen \(screenNumber)"
        let size = text.size(withAttributes: attributes)
        let point = NSPoint(x: 20, y: bounds.height - size.height - 20)
        text.draw(at: point, withAttributes: attributes)
        
        let center = centerPoint ?? NSPoint(x: bounds.midX, y: bounds.midY)
        let innerRadius: CGFloat = 40  // Inner circle radius
        let outerRadius: CGFloat = 120 // Outer radius for segments
        let selectedOuterRadius: CGFloat = 140 // Expanded radius for selected segment
        
        // Draw dark semi-transparent background circle
        let bgPath = NSBezierPath(ovalIn: NSRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        ))
        NSColor.black.withAlphaComponent(0.7).setFill()
        bgPath.fill()
        
        // Draw inner circle
        let innerCirclePath = NSBezierPath(ovalIn: NSRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
        NSColor.black.withAlphaComponent(0.8).setFill()
        innerCirclePath.fill()
        
        // Draw the segments
        for direction in DirectionalSettings.Direction.allCases {
            let isSelected = direction == selectedDirection
            let startAngle = direction.angle - 22.5 // Half of 45 degrees
            let endAngle = direction.angle + 22.5
            let radius = isSelected ? selectedOuterRadius : outerRadius
            
            // Create segment path
            let segmentPath = NSBezierPath()
            segmentPath.move(to: center)
            segmentPath.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            segmentPath.close()
            
            // Set segment color
            if isSelected {
                NSColor.white.withAlphaComponent(0.3).setFill()
                NSColor.white.withAlphaComponent(0.6).setStroke()
            } else {
                NSColor.white.withAlphaComponent(0.1).setFill()
                NSColor.white.withAlphaComponent(0.2).setStroke()
            }
            
            segmentPath.fill()
            segmentPath.lineWidth = 1
            segmentPath.stroke()
            
            // Draw app icon if mapped
            if let mapping = settings.mappings[direction] {
                let iconSize: CGFloat = 32
                let iconDistance = (radius + innerRadius) / 2
                let iconAngle = direction.angle * .pi / 180
                let iconX = center.x + iconDistance * cos(CGFloat(iconAngle)) - iconSize/2
                let iconY = center.y + iconDistance * sin(CGFloat(iconAngle)) - iconSize/2
                let iconRect = NSRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
                
                if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == mapping.bundleIdentifier }),
                   let icon = app.icon {
                    icon.draw(in: iconRect)
                } else if let icon = mapping.icon {
                    icon.draw(in: iconRect)
                }
            }
        }
    }
    
    func updateSettings(_ newSettings: DirectionalSettings) {
        self.settings = newSettings
    }
} 