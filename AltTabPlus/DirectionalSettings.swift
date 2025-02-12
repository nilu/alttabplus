import Cocoa

struct DirectionalSettings: Codable {
    enum Direction: String, CaseIterable, Codable {
        case north
        case northEast
        case east
        case southEast
        case south
        case southWest
        case west
        case northWest
        
        var angle: Double {
            switch self {
            case .north: return 90
            case .northEast: return 45
            case .east: return 0
            case .southEast: return 315
            case .south: return 270
            case .southWest: return 225
            case .west: return 180
            case .northWest: return 135
            }
        }
        
        static func from(angle: Double) -> Direction {
            // Normalize angle to 0-360
            var normalized = angle * 180 / .pi
            if normalized < 0 { normalized += 360 }
            
            // Find closest direction
            return Direction.allCases.min(by: { a, b in
                let aDiff = abs(normalized - a.angle)
                let bDiff = abs(normalized - b.angle)
                return aDiff < bDiff
            }) ?? .north
        }
    }
    
    var mappings: [Direction: AppMapping]
    
    struct AppMapping: Codable {
        let bundleIdentifier: String
        let name: String
        private let iconHash: String?
        
        // Make sure icon is not encoded
        private enum CodingKeys: String, CodingKey {
            case bundleIdentifier, name, iconHash
        }
        
        // Computed property should not affect encoding
        var icon: NSImage? {
            get {
                guard let hash = iconHash else { return nil }
                return IconCache.shared.getIcon(forHash: hash)
            }
        }
        
        init?(app: NSRunningApplication) {
            guard let bundleIdentifier = app.bundleIdentifier,
                  let name = app.localizedName else { return nil }
            
            self.bundleIdentifier = bundleIdentifier
            self.name = name
            
            // Store icon in cache and save only the hash
            if let appIcon = app.icon {
                self.iconHash = IconCache.shared.cacheIcon(appIcon)
            } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                self.iconHash = IconCache.shared.cacheIcon(icon)
            } else {
                self.iconHash = nil
            }
        }
    }
    
    static func load() -> DirectionalSettings {
        if let data = UserDefaults.standard.data(forKey: "DirectionalSettings"),
           let settings = try? JSONDecoder().decode(DirectionalSettings.self, from: data) {
            return settings
        }
        return DirectionalSettings(mappings: [:])
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            print("Settings data size: \(data.count) bytes") // Debug print
            if data.count >= 4_194_304 {
                print("WARNING: Data size exceeds 4MB limit!")
                // Print the mappings to see what's taking up space
                mappings.forEach { direction, mapping in
                    print("Direction: \(direction), App: \(mapping.name)")
                }
            }
            UserDefaults.standard.set(data, forKey: "DirectionalSettings")
            UserDefaults.standard.synchronize()
        } else {
            print("Failed to encode settings")
        }
    }
    
    func copy() -> DirectionalSettings {
        let mappingsCopy = self.mappings
        return DirectionalSettings(mappings: mappingsCopy)
    }
} 