import SwiftUI

class AboutWindow: NSWindow {
    private static var shared: AboutWindow?
    
    static func showAbout() {
        if shared == nil {
            shared = AboutWindow()
        }
        shared?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "About AltTabPlus"
        self.center()
        
        let contentView = NSHostingView(rootView: AboutView())
        self.contentView = contentView
        self.isReleasedWhenClosed = false
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("AltTabPlus")
                .font(.title)
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
            
            Text("© 2024 Your Name")
            
            Link("View on GitHub", destination: URL(string: "https://github.com/yourusername/AltTabPlus")!)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
} 