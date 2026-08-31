import Foundation
import AppKit

/// Handles safe macOS Trash operations using Apple's official APIs
public final class TrashManager: @unchecked Sendable {
    public static let shared = TrashManager()

    private init() {}

    /// Moves a file or folder at the given path to the macOS Trash (reclaimable)
    @discardableResult
    public func moveToTrash(path: String) throws -> URL {
        let fileURL = URL(fileURLWithPath: path)
        var resultingURL: NSURL?
        
        try FileManager.default.trashItem(at: fileURL, resultingItemURL: &resultingURL)
        
        if let result = resultingURL as URL? {
            return result
        }
        return fileURL
    }

    /// Moves multiple files/folders to Trash
    public func batchMoveToTrash(paths: [String]) -> (succeeded: [String], failed: [String: String]) {
        var succeeded: [String] = []
        var failed: [String: String] = [:]

        for path in paths {
            do {
                try moveToTrash(path: path)
                succeeded.append(path)
            } catch {
                failed[path] = error.localizedDescription
            }
        }
        return (succeeded, failed)
    }

    /// Reveals a path in macOS Finder
    public func revealInFinder(path: String) {
        let fileURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    /// Opens file or folder in default macOS application
    public func openItem(path: String) {
        let fileURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(fileURL)
    }
}
