import Cocoa

class IconCache {
    static let shared = IconCache()
    private let cacheDirectory: URL
    private var memoryCache: [String: NSImage] = [:]
    
    private init() {
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cacheDir.appendingPathComponent("com.yourdomain.AltTabPlus/IconCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheIcon(_ icon: NSImage) -> String {
        let hash = String(icon.hashValue)
        print("Caching icon with hash: \(hash)") // Debug print
        
        // Store in memory cache
        memoryCache[hash] = icon
        
        // Store on disk
        if let tiffData = icon.tiffRepresentation {
            let fileURL = cacheDirectory.appendingPathComponent(hash)
            do {
                try tiffData.write(to: fileURL)
                print("Successfully wrote icon to disk: \(fileURL.path)") // Debug print
            } catch {
                print("Failed to write icon to disk: \(error)") // Debug print
            }
        }
        
        return hash
    }
    
    func getIcon(forHash hash: String) -> NSImage? {
        // Check memory cache first
        if let icon = memoryCache[hash] {
            return icon
        }
        
        // Try loading from disk
        let fileURL = cacheDirectory.appendingPathComponent(hash)
        if let data = try? Data(contentsOf: fileURL),
           let icon = NSImage(data: data) {
            memoryCache[hash] = icon
            return icon
        }
        
        return nil
    }
    
    func clearCache() {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
} 