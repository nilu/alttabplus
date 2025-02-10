import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, SettingsWindowDelegate {
    private var statusItem: NSStatusItem?
    private var windowManager: WindowManager?
    private var mouseTracker: MouseTracker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App is launching...")
        
        // Request accessibility permissions if needed
        requestAccessibilityPermissions()
        
        // Initialize components
        windowManager = WindowManager()
        mouseTracker = MouseTracker(windowManager: windowManager!)
        
        // Setup menu bar item
        setupStatusItem()
        print("Menu bar item should be visible now")
    }
    
    private func requestAccessibilityPermissions() {
        // First check without showing prompt
        if AXIsProcessTrusted() {
            print("Accessibility permissions already granted")
            return
        }
        
        // If not trusted, then show the prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            print("Please grant accessibility permissions in System Preferences")
        }
    }
    
    private func setupStatusItem() {
        print("Setting up status item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            print("Creating menu bar icon...")
            let image = NSImage(size: NSSize(width: 18, height: 18))
            image.isTemplate = true // For proper dark/light mode support
            
            image.lockFocus()
            NSColor.black.set()
            
            let path = NSBezierPath()
            // Draw arrows in four directions
            // Up arrow
            path.move(to: NSPoint(x: 9, y: 2))
            path.line(to: NSPoint(x: 5, y: 6))
            path.line(to: NSPoint(x: 13, y: 6))
            path.close()
            // Down arrow
            path.move(to: NSPoint(x: 9, y: 16))
            path.line(to: NSPoint(x: 5, y: 12))
            path.line(to: NSPoint(x: 13, y: 12))
            path.close()
            // Left arrow
            path.move(to: NSPoint(x: 2, y: 9))
            path.line(to: NSPoint(x: 6, y: 5))
            path.line(to: NSPoint(x: 6, y: 13))
            path.close()
            // Right arrow
            path.move(to: NSPoint(x: 16, y: 9))
            path.line(to: NSPoint(x: 12, y: 5))
            path.line(to: NSPoint(x: 12, y: 13))
            path.close()
            
            path.fill()
            image.unlockFocus()
            
            button.image = image
        } else {
            print("Failed to get status item button")
        }
        
        setupStatusMenu()
    }
    
    private func setupStatusMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About AltTabPlus", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func showAbout() {
        AboutWindow.showAbout()
    }
    
    @objc private func showSettings() {
        SettingsWindow.showSettings(with: windowManager!.settings, delegate: self)
    }
    
    func settingsDidUpdate(_ settings: DirectionalSettings) {
        windowManager?.updateSettings(settings)
    }
} 