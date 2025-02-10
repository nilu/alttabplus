import Cocoa

protocol SettingsWindowDelegate: AnyObject {
    func settingsDidUpdate(_ settings: DirectionalSettings)
}

class SettingsWindow: NSWindow {
    private var settings: DirectionalSettings
    private var directionButtons: [DirectionalSettings.Direction: NSButton] = [:]
    private var originalSettings: DirectionalSettings
    private var isClosing = false
    weak var settingsDelegate: SettingsWindowDelegate?
    static var shared: SettingsWindow?
    private var launchAtLoginCheckbox: NSButton!
    
    static func showSettings(with settings: DirectionalSettings, delegate: SettingsWindowDelegate?) {
        if let existing = shared {
            existing.orderFrontRegardless()
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            shared = SettingsWindow(settings: settings)
            shared?.settingsDelegate = delegate
            shared?.center()
            shared?.orderFrontRegardless()
            shared?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private init(settings: DirectionalSettings) {
        self.settings = settings.copy()
        self.originalSettings = settings.copy()
        
        let windowRect = NSRect(x: 0, y: 0, width: 400, height: 450)
        
        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        title = "AltTabPlus Settings"
        isReleasedWhenClosed = false
        delegate = self
        level = .floating
        setupUI()
    }
    
    private func setupUI() {
        let contentView = NSView(frame: frame)
        
        // Create direction buttons in a circle
        let center = NSPoint(x: frame.width/2, y: frame.height/2 + 25)
        let radius: CGFloat = 100
        
        for direction in DirectionalSettings.Direction.allCases {
            let angle = direction.angle * .pi / 180
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            let button = NSButton(frame: NSRect(x: x-25, y: y-25, width: 50, height: 50))
            button.bezelStyle = NSButton.BezelStyle.regularSquare
            button.title = direction.rawValue
            button.target = self
            button.action = #selector(directionClicked(_:))
            button.sendAction(on: .leftMouseUp)
            
            // Add right-click menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Unbind", action: #selector(unbindDirection(_:)), keyEquivalent: ""))
            button.menu = menu
            
            // Store the direction in the menu item's represented object
            if let menuItem = menu.items.first {
                menuItem.representedObject = direction
            }
            
            if let mapping = settings.mappings[direction] {
                updateButtonAppearance(button, with: mapping, direction: direction)
            }
            
            contentView.addSubview(button)
            directionButtons[direction] = button
        }
        
        // Add Save and Cancel buttons at the bottom
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 32
        let buttonSpacing: CGFloat = 20
        let bottomMargin: CGFloat = 20
        
        let saveButton = NSButton(frame: NSRect(
            x: frame.width/2 - buttonWidth - buttonSpacing/2,
            y: bottomMargin,
            width: buttonWidth,
            height: buttonHeight
        ))
        saveButton.title = "Save"
        saveButton.bezelStyle = NSButton.BezelStyle.rounded
        saveButton.target = self
        saveButton.action = #selector(saveSettings)
        contentView.addSubview(saveButton)
        
        let cancelButton = NSButton(frame: NSRect(
            x: frame.width/2 + buttonSpacing/2,
            y: bottomMargin,
            width: buttonWidth,
            height: buttonHeight
        ))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = NSButton.BezelStyle.rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelSettings)
        contentView.addSubview(cancelButton)
        
        // Add Launch at Login checkbox
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(toggleLaunchAtLogin(_:)))
        launchAtLoginCheckbox.state = LoginItemManager.shared.isLoginItemEnabled ? .on : .off
        launchAtLoginCheckbox.frame = NSRect(
            x: 20,
            y: bottomMargin + buttonHeight + 20,
            width: frame.width - 40,
            height: 20
        )
        contentView.addSubview(launchAtLoginCheckbox)
        
        contentView.wantsLayer = true
        self.contentView = contentView
    }
    
    private func updateButtonAppearance(_ button: NSButton, with mapping: DirectionalSettings.AppMapping, direction: DirectionalSettings.Direction) {
        // First try to get icon from running app
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == mapping.bundleIdentifier }),
           let icon = app.icon {
            button.image = icon
            button.imagePosition = .imageOnly
            return
        }
        
        // If app isn't running, try to get icon from the app bundle
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mapping.bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            button.image = icon
            button.imagePosition = .imageOnly
            return
        }
        
        // If no icon found, show the direction text
        button.image = nil
        button.imagePosition = .noImage
        button.title = direction.rawValue
    }
    
    private func refreshAllButtonAppearances() {
        for (direction, button) in directionButtons {
            if let mapping = settings.mappings[direction] {
                updateButtonAppearance(button, with: mapping, direction: direction)
            } else {
                // Reset button to default appearance if no mapping exists
                button.image = nil
                button.imagePosition = .noImage
                button.title = direction.rawValue
            }
        }
    }
    
    @objc private func directionClicked(_ sender: NSButton) {
        guard let direction = directionButtons.first(where: { $0.value == sender })?.key else { return }
        
        selectApp(for: direction)
    }
    
    private func selectApp(for direction: DirectionalSettings.Direction) {
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }  // Only show regular apps
            .sorted { $0.localizedName ?? "" < $1.localizedName ?? "" }
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        for app in runningApps {
            if let appName = app.localizedName {
                let item = NSMenuItem(title: appName, action: #selector(appSelected(_:)), keyEquivalent: "")
                item.target = self
                item.isEnabled = true
                item.representedObject = (app.bundleIdentifier, direction)
                menu.addItem(item)
            }
        }
        
        if let button = directionButtons[direction] {
            NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: button)
        }
    }
    
    @objc private func appSelected(_ sender: NSMenuItem) {
        guard let (bundleId, direction) = sender.representedObject as? (String?, DirectionalSettings.Direction) else { return }
        
        // Create a new mapping if we have a bundle ID
        if let bundleId = bundleId,
           let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            settings.mappings[direction] = .init(app: app)
            
            // Update button appearance
            if let button = directionButtons[direction] {
                updateButtonAppearance(button, with: settings.mappings[direction]!, direction: direction)
            }
        }
    }
    
    @objc private func unbindDirection(_ sender: NSMenuItem) {
        guard let direction = sender.representedObject as? DirectionalSettings.Direction else { return }
        
        // Remove the mapping
        settings.mappings.removeValue(forKey: direction)
        
        // Reset button appearance
        if let button = directionButtons[direction] {
            button.image = nil
            button.imagePosition = .noImage
            button.title = direction.rawValue
        }
    }
    
    @objc private func saveSettings() {
        if isClosing { return }
        isClosing = true
        settings.save()
        settingsDelegate?.settingsDidUpdate(settings)
        refreshAllButtonAppearances()  // Refresh all buttons
        SettingsWindow.shared = nil
        close()
    }
    
    @objc private func cancelSettings() {
        if isClosing { return }
        isClosing = true
        settings = originalSettings.copy()
        refreshAllButtonAppearances()  // Refresh all buttons
        SettingsWindow.shared = nil
        close()
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        LoginItemManager.shared.isLoginItemEnabled = (sender.state == .on)
    }
    
    override func close() {
        if !isClosing {
            cancelSettings()
            return
        }
        super.close()
        SettingsWindow.shared = nil
    }
}

extension SettingsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if !isClosing {
            cancelSettings()
        }
    }
} 