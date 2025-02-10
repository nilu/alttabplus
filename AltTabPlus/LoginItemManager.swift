import Foundation
import ServiceManagement

class LoginItemManager {
    static let shared = LoginItemManager()
    
    private init() {}
    
    var isLoginItemEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                // For older macOS versions
                return false
            }
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to \(newValue ? "enable" : "disable") login item: \(error)")
                }
            }
        }
    }
} 