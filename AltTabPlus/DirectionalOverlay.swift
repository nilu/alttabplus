import Cocoa

class DirectionalOverlay: NSWindow {
    private var settings: DirectionalSettings
    private var selectedDirection: DirectionalSettings.Direction?
    private var directionViews: [DirectionalSettings.Direction: NSImageView] = [:]
    
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
        let overlayView = DirectionalOverlayView(settings: settings)
        contentView = overlayView
        
        // Create image views for each direction
        setupDirectionViews(in: overlayView)
        
        // Load all icons immediately
        updateAllIcons()
    }
    
    private func setupDirectionViews(in overlayView: DirectionalOverlayView) {
        let center = NSPoint(x: overlayView.bounds.midX, y: overlayView.bounds.midY)
        let radius: CGFloat = 100
        
        for direction in DirectionalSettings.Direction.allCases {
            let angle = direction.angle * .pi / 180
            let x = center.x + radius * cos(CGFloat(angle))
            let y = center.y + radius * sin(CGFloat(angle))
            
            let imageView = NSImageView(frame: NSRect(x: x - 25, y: y - 25, width: 50, height: 50))
            imageView.imageScaling = .scaleProportionallyUpOrDown
            overlayView.addSubview(imageView)
            directionViews[direction] = imageView
        }
    }
    
    func show() {
        orderFront(nil)
        selectedDirection = nil
        updateSelection(nil)
        updateAllIcons()
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
            updateAllIcons()
        }
    }
    
    func updateAllIcons() {
        for direction in DirectionalSettings.Direction.allCases {
            if settings.mappings[direction] != nil {
                updateDirectionIcon(direction)
            }
        }
    }
    
    private func updateDirectionIcon(_ direction: DirectionalSettings.Direction) {
        guard let directionView = directionViews[direction] else { return }
        
        if let mapping = settings.mappings[direction] {
            // Try to get icon from running app first
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == mapping.bundleIdentifier }),
               let icon = app.icon {
                directionView.image = icon
            } else if let icon = mapping.icon {
                // Use stored icon if app isn't running
                directionView.image = icon
            }
        } else {
            directionView.image = nil
        }
    }
    
    func updatePosition(to mouseLocation: NSPoint) {
        guard let overlayView = contentView as? DirectionalOverlayView else { return }
        overlayView.centerPoint = mouseLocation
        overlayView.needsDisplay = true
        
        // Update direction views positions
        let radius: CGFloat = 100
        for (direction, imageView) in directionViews {
            let angle = direction.angle * .pi / 180
            let x = mouseLocation.x + radius * cos(CGFloat(angle))
            let y = mouseLocation.y + radius * sin(CGFloat(angle))
            imageView.frame = NSRect(x: x - 25, y: y - 25, width: 50, height: 50)
        }
    }
}

class DirectionalOverlayView: NSView {
    private var settings: DirectionalSettings
    var selectedDirection: DirectionalSettings.Direction?
    var centerPoint: NSPoint?
    
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
        
        let center = centerPoint ?? NSPoint(x: bounds.midX, y: bounds.midY)
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
            if let mapping = settings.mappings[direction] {
                if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == mapping.bundleIdentifier }),
                   let icon = app.icon {
                    icon.draw(in: segmentRect)
                } else if let icon = mapping.icon {
                    icon.draw(in: segmentRect)
                }
            }
        }
    }
    
    func updateSettings(_ newSettings: DirectionalSettings) {
        self.settings = newSettings
    }
} 