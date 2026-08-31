import Foundation
import SwiftUI

/// Categorization for files and directories for visual differentiation
public enum FileCategory: String, CaseIterable, Identifiable, Sendable, Codable {
    case developer = "Developer & Builds"
    case caches = "Caches & Temporary"
    case media = "Media & Videos"
    case documents = "Documents & Data"
    case archives = "Archives & Disk Images"
    case system = "System & App Support"
    case hidden = "Hidden & Dotfiles"
    case other = "Other"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .developer:
            return Color(red: 0.95, green: 0.55, blue: 0.15) // Vibrant Orange
        case .caches:
            return Color(red: 0.92, green: 0.30, blue: 0.35) // Crimson Red
        case .media:
            return Color(red: 0.20, green: 0.60, blue: 0.95) // Vivid Blue
        case .documents:
            return Color(red: 0.25, green: 0.75, blue: 0.50) // Emerald Green
        case .archives:
            return Color(red: 0.65, green: 0.40, blue: 0.85) // Purple
        case .system:
            return Color(red: 0.45, green: 0.55, blue: 0.70) // Slate Indigo
        case .hidden:
            return Color(red: 0.50, green: 0.50, blue: 0.55) // Neutral Grey
        case .other:
            return Color(red: 0.35, green: 0.65, blue: 0.75) // Teal
        }
    }

    public var iconName: String {
        switch self {
        case .developer: return "hammer.fill"
        case .caches: return "trash.circle.fill"
        case .media: return "play.rectangle.fill"
        case .documents: return "doc.text.fill"
        case .archives: return "archivebox.fill"
        case .system: return "gearshape.2.fill"
        case .hidden: return "eye.slash.fill"
        case .other: return "folder.fill"
        }
    }

    public static func categorize(name: String, path: String, isDirectory: Bool) -> FileCategory {
        let lowerName = name.lowercased()
        let lowerPath = path.lowercased()

        if name.hasPrefix(".") {
            return .hidden
        }

        // Developer patterns
        let devPatterns = [
            "node_modules", "deriveddata", ".build", "target", "build", ".gradle",
            ".cargo", ".rustup", ".venv", "venv", "env", "pods", ".nuget", ".m2"
        ]
        if devPatterns.contains(where: { lowerName == $0 || lowerPath.contains("/" + $0 + "/") }) {
            return .developer
        }

        // Cache patterns
        let cachePatterns = ["cache", "caches", "tmp", "temp", ".cache", "logs", "log"]
        if cachePatterns.contains(where: { lowerName == $0 || lowerPath.contains("/" + $0 + "/") }) {
            return .caches
        }

        let ext = (name as NSString).pathExtension.lowercased()

        // Archives
        if ["zip", "tar", "gz", "tgz", "bz2", "xz", "7z", "rar", "dmg", "iso", "pkg"].contains(ext) {
            return .archives
        }

        // Media
        if ["mp4", "mov", "mkv", "avi", "m4v", "flv", "mp3", "wav", "flac", "aac", "m4a", "png", "jpg", "jpeg", "heic", "gif", "svg", "raw", "cr2", "psd"].contains(ext) {
            return .media
        }

        // Developer code files
        if ["swift", "js", "ts", "jsx", "tsx", "py", "rs", "go", "c", "cpp", "h", "hpp", "java", "kt", "html", "css", "json", "yaml", "yml", "toml", "sh", "sql"].contains(ext) {
            return .developer
        }

        // Documents
        if ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md", "csv", "rtf", "pages", "numbers", "keynote"].contains(ext) {
            return .documents
        }

        // System
        if lowerPath.contains("/library/") || lowerPath.contains("/system/") || lowerPath.contains("/application support/") {
            return .system
        }

        return isDirectory ? .other : .documents
    }
}

/// Represents a single file or directory node in the filesystem hierarchy
public final class FileNode: Identifiable, ObservableObject, Sendable {
    public let id: UUID
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let isHidden: Bool
    public let size: Int64
    public let itemCount: Int
    public let modificationDate: Date
    public let category: FileCategory
    public var children: [FileNode]
    public weak var parent: FileNode?

    public init(
        id: UUID = UUID(),
        name: String,
        path: String,
        isDirectory: Bool,
        isHidden: Bool,
        size: Int64,
        itemCount: Int,
        modificationDate: Date,
        category: FileCategory,
        children: [FileNode] = [],
        parent: FileNode? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.isHidden = isHidden
        self.size = size
        self.itemCount = itemCount
        self.modificationDate = modificationDate
        self.category = category
        self.children = children
        self.parent = parent
    }

    /// Formatted readable size string (e.g., "14.2 GB", "820 MB")
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Formatted modification date
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }

    /// Relative human readable date (e.g., "2 days ago")
    public var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: modificationDate, relativeTo: Date())
    }
}

/// Treemap Tile geometry computed for layout
public struct TreemapTile: Identifiable, Sendable {
    public var id: UUID { node.id }
    public let node: FileNode
    public let rect: CGRect
    public let depth: Int

    public init(node: FileNode, rect: CGRect, depth: Int = 0) {
        self.node = node
        self.rect = rect
        self.depth = depth
    }
}

/// Overall Scanning Status
public enum ScanState: Equatable, Sendable {
    case idle
    case scanning(currentPath: String, itemsScanned: Int, bytesScanned: Int64)
    case completed(totalItems: Int, totalBytes: Int64, duration: TimeInterval)
    case failed(error: String)
}

/// Quick clean preset item
public struct QuickCleanPreset: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: String
    public let pathPatterns: [String]
    public var matchedNodes: [FileNode]
    public var totalSize: Int64 {
        matchedNodes.reduce(0) { $0 + $1.size }
    }
    public var isSelected: Bool

    public init(
        id: String,
        title: String,
        subtitle: String,
        icon: String,
        pathPatterns: [String],
        matchedNodes: [FileNode] = [],
        isSelected: Bool = true
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.pathPatterns = pathPatterns
        self.matchedNodes = matchedNodes
        self.isSelected = isSelected
    }
}

/// Drive / Volume Information
public struct VolumeInfo: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let mountPoint: String
    public let totalBytes: Int64
    public let freeBytes: Int64
    public var usedBytes: Int64 { totalBytes - freeBytes }

    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    public static func currentMainVolume() -> VolumeInfo {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        do {
            let values = try homeURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeNameKey])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            let name = values.volumeName ?? "Macintosh HD"
            return VolumeInfo(name: name, mountPoint: "/", totalBytes: total, freeBytes: free)
        } catch {
            return VolumeInfo(name: "Macintosh HD", mountPoint: "/", totalBytes: 500_000_000_000, freeBytes: 150_000_000_000)
        }
    }
}
