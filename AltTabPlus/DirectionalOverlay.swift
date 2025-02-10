import Cocoa

class DirectionalOverlay: NSWindow {
    private var settings: DirectionalSettings
    private var selectedDirection: DirectionalSettings.Direction?
    
    init(settings: DirectionalSettings) {
        self.settings = settings
        self.selectedDirection = nil
        
        // Create window spanning the entire screen
        let screen = NSScreen.main ?? NSScreen.screens[0]
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        
        // Set up the content view
        contentView = DirectionalOverlayView(settings: settings)
    }
    
    func show() {
        orderFront(nil)
        selectedDirection = nil
        updateSelection(nil)
    }
    
    func hide() {
        orderOut(nil)
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
}

class DirectionalOverlayView: NSView {
    private var settings: DirectionalSettings
    var selectedDirection: DirectionalSettings.Direction?
    
    init(settings: DirectionalSettings) {
        self.settings = settings
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = 100
        let selectedRadius: CGFloat = 120
        
        // Draw the wheel segments
        for direction in DirectionalSettings.Direction.allCases {
            let angle = direction.angle * .pi / 180
            let isSelected = direction == selectedDirection
            
            // Calculate segment position
            let segmentRadius = isSelected ? selectedRadius : radius
            let x = center.x + segmentRadius * cos(CGFloat(angle))
            let y = center.y + segmentRadius * sin(CGFloat(angle))
            
            let segmentRect = NSRect(x: x - 25, y: y - 25, width: 50, height: 50)
            
            // Draw segment background
            let bgPath = NSBezierPath(ovalIn: segmentRect)
            if isSelected {
                NSColor.white.withAlphaComponent(0.3).setFill()
            } else {
                NSColor.black.withAlphaComponent(0.5).setFill()
            }
            bgPath.fill()
            
            // Draw app icon if mapped
            if let mapping = settings.mappings[direction],
               let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == mapping.bundleIdentifier }),
               let icon = app.icon {
                icon.draw(in: segmentRect)
            }
        }
    }
    
    func updateSettings(_ newSettings: DirectionalSettings) {
        self.settings = newSettings
    }
} 