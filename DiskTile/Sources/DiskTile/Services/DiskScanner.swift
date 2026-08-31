import Foundation

/// Fast asynchronous file system scanner with symlink protection and progress streaming
public actor DiskScanner {
    private var isCancelled: Bool = false
    private var visitedInodes: Set<String> = []

    public init() {}

    public func cancel() {
        isCancelled = true
    }

    /// Recursively scans a root directory and builds a hierarchical FileNode tree
    public func scanDirectory(
        at url: URL,
        includeHidden: Bool = true,
        progressHandler: (@Sendable (String, Int, Int64) -> Void)? = nil
    ) async throws -> FileNode {
        isCancelled = false
        visitedInodes.removeAll()

        var itemsScanned = 0
        var bytesScanned: Int64 = 0
        var lastReportTime = Date()

        let rootNode = try await scanNode(
            at: url,
            includeHidden: includeHidden,
            depth: 0,
            maxDepth: 25,
            itemsScanned: &itemsScanned,
            bytesScanned: &bytesScanned,
            lastReportTime: &lastReportTime,
            progressHandler: progressHandler
        )

        return rootNode
    }

    private func scanNode(
        at url: URL,
        includeHidden: Bool,
        depth: Int,
        maxDepth: Int,
        itemsScanned: inout Int,
        bytesScanned: inout Int64,
        lastReportTime: inout Date,
        progressHandler: (@Sendable (String, Int, Int64) -> Void)?
    ) async throws -> FileNode {
        if Task.isCancelled || isCancelled {
            throw CancellationError()
        }

        let fileManager = FileManager.default
        let path = url.path
        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let isHidden = name.hasPrefix(".")

        // Get file attributes
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return FileNode(
                name: name,
                path: path,
                isDirectory: false,
                isHidden: isHidden,
                size: 0,
                itemCount: 1,
                modificationDate: Date(),
                category: .other
            )
        }

        var modDate = Date()
        var fileSize: Int64 = 0

        // Read stat attributes
        var statBuf = stat()
        if lstat(path, &statBuf) == 0 {
            let inodeKey = "\(statBuf.st_dev):\(statBuf.st_ino)"
            if isDirectory.boolValue {
                if visitedInodes.contains(inodeKey) {
                    // Cyclic symlink detected
                    return FileNode(
                        name: name,
                        path: path,
                        isDirectory: true,
                        isHidden: isHidden,
                        size: 0,
                        itemCount: 0,
                        modificationDate: modDate,
                        category: .other
                    )
                }
                visitedInodes.insert(inodeKey)
            }
            fileSize = Int64(statBuf.st_size)
            modDate = Date(timeIntervalSince1970: TimeInterval(statBuf.st_mtimespec.tv_sec))
        }

        itemsScanned += 1
        bytesScanned += fileSize

        // Periodic progress throttle (every 100ms)
        let now = Date()
        if now.timeIntervalSince(lastReportTime) > 0.1 {
            lastReportTime = now
            let currentPath = path
            let currentCount = itemsScanned
            let currentBytes = bytesScanned
            progressHandler?(currentPath, currentCount, currentBytes)
        }

        let category = FileCategory.categorize(name: name, path: path, isDirectory: isDirectory.boolValue)

        if !isDirectory.boolValue || depth >= maxDepth {
            return FileNode(
                name: name,
                path: path,
                isDirectory: isDirectory.boolValue,
                isHidden: isHidden,
                size: fileSize,
                itemCount: 1,
                modificationDate: modDate,
                category: category
            )
        }

        // Enumerate directory contents
        var children: [FileNode] = []
        var totalChildSize: Int64 = 0
        var totalChildItems = 1

        do {
            let options: FileManager.DirectoryEnumerationOptions = includeHidden ? [] : [.skipsHiddenFiles]
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                options: options
            )

            for childURL in contents {
                if Task.isCancelled || isCancelled { break }
                
                let childNode = try await scanNode(
                    at: childURL,
                    includeHidden: includeHidden,
                    depth: depth + 1,
                    maxDepth: maxDepth,
                    itemsScanned: &itemsScanned,
                    bytesScanned: &bytesScanned,
                    lastReportTime: &lastReportTime,
                    progressHandler: progressHandler
                )
                totalChildSize += childNode.size
                totalChildItems += childNode.itemCount
                children.append(childNode)
            }
        } catch {
            // Permission denied or non-readable directory: gracefully record size as-is
        }

        // Sort children by size descending for optimal treemap layout
        children.sort { $0.size > $1.size }

        let node = FileNode(
            name: name,
            path: path,
            isDirectory: true,
            isHidden: isHidden,
            size: max(fileSize, totalChildSize),
            itemCount: totalChildItems,
            modificationDate: modDate,
            category: category,
            children: children
        )

        for child in children {
            child.parent = node
        }

        return node
    }
}
