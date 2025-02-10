import Cocoa

class SettingsWindow: NSWindow {
    private var settings = DirectionalSettings.load()
    private var directionButtons: [DirectionalSettings.Direction: NSButton] = [:]
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        title = "AltTabPlus Settings"
        setupUI()
    }
    
    private func setupUI() {
        let contentView = NSView(frame: frame)
        
        // Create direction buttons in a circle
        let center = NSPoint(x: frame.width/2, y: frame.height/2)
        let radius: CGFloat = 100
        
        for direction in DirectionalSettings.Direction.allCases {
            let angle = direction.angle * .pi / 180
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            let button = NSButton(frame: NSRect(x: x-25, y: y-25, width: 50, height: 50))
            button.bezelStyle = .regularSquare
            button.title = direction.rawValue
            button.target = self
            button.action = #selector(directionClicked(_:))
            
            if let mapping = settings.mappings[direction] {
                updateButtonAppearance(button, with: mapping)
            }
            
            contentView.addSubview(button)
            directionButtons[direction] = button
        }
        
        contentView.wantsLayer = true
        self.contentView = contentView
    }
    
    private func updateButtonAppearance(_ button: NSButton, with mapping: DirectionalSettings.AppMapping) {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == mapping.bundleIdentifier }),
           let icon = app.icon {
            button.image = icon
            button.imagePosition = .imageOnly
        }
    }
    
    @objc private func directionClicked(_ sender: NSButton) {
        guard let direction = directionButtons.first(where: { $0.value == sender })?.key else { return }
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        
        panel.begin { [weak self] response in
            guard response == .OK,
                  let url = panel.url,
                  let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleURL == url }),
                  let mapping = DirectionalSettings.AppMapping(app: app)
            else { return }
            
            self?.settings.mappings[direction] = mapping
            self?.settings.save()
            self?.updateButtonAppearance(sender, with: mapping)
        }
    }
} 