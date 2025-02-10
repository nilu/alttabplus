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
        
        init?(app: NSRunningApplication) {
            guard let bundleIdentifier = app.bundleIdentifier,
                  let name = app.localizedName else { return nil }
            self.bundleIdentifier = bundleIdentifier
            self.name = name
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
            UserDefaults.standard.set(data, forKey: "DirectionalSettings")
        }
    }
} 