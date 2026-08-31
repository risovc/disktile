import Foundation
import CoreGraphics

/// Squarified Treemap Layout Engine based on the Bruls-Huizing-van Wijk algorithm
public struct TreemapEngine {
    
    /// Computes proportional rectangular layout for an array of FileNodes within a bounding rectangle
    public static func computeLayout(
        for nodes: [FileNode],
        in rect: CGRect,
        padding: CGFloat = 2.0
    ) -> [TreemapTile] {
        guard !nodes.isEmpty, rect.width > 4, rect.height > 4 else { return [] }

        // Filter out 0 byte files and normalize
        let validNodes = nodes.filter { $0.size > 0 }
        guard !validNodes.isEmpty else { return [] }

        let totalSize = Double(validNodes.reduce(0) { $0 + $1.size })
        guard totalSize > 0 else { return [] }

        let totalArea = Double(rect.width * rect.height)
        let normalizedSizes = validNodes.map { (node: $0, area: (Double($0.size) / totalSize) * totalArea) }

        var tiles: [TreemapTile] = []
        var remainingRect = rect
        var currentRow: [(node: FileNode, area: Double)] = []

        func worstAspectRatio(row: [(node: FileNode, area: Double)], length: Double) -> Double {
            guard !row.isEmpty, length > 0 else { return Double.greatestFiniteMagnitude }
            let rowArea = row.reduce(0.0) { $0 + $1.area }
            let rowWidth = rowArea / length
            guard rowWidth > 0 else { return Double.greatestFiniteMagnitude }

            var worst: Double = 0.0
            for item in row {
                let itemHeight = item.area / rowWidth
                guard itemHeight > 0 else { continue }
                let ratio = max(rowWidth / itemHeight, itemHeight / rowWidth)
                if ratio > worst {
                    worst = ratio
                }
            }
            return worst
        }

        func layoutRow(_ row: [(node: FileNode, area: Double)], in boundingBox: inout CGRect) {
            guard !row.isEmpty else { return }
            let rowArea = row.reduce(0.0) { $0 + $1.area }
            let isHorizontal = boundingBox.width >= boundingBox.height

            if isHorizontal {
                let rowWidth = CGFloat(rowArea / Double(boundingBox.height))
                var currentY = boundingBox.minY

                for item in row {
                    let itemHeight = CGFloat(item.area / Double(rowWidth))
                    let tileRect = CGRect(
                        x: boundingBox.minX + padding,
                        y: currentY + padding,
                        width: max(1, rowWidth - (padding * 2)),
                        height: max(1, itemHeight - (padding * 2))
                    )
                    tiles.append(TreemapTile(node: item.node, rect: tileRect))
                    currentY += itemHeight
                }
                boundingBox = CGRect(
                    x: boundingBox.minX + rowWidth,
                    y: boundingBox.minY,
                    width: max(0, boundingBox.width - rowWidth),
                    height: boundingBox.height
                )
            } else {
                let rowHeight = CGFloat(rowArea / Double(boundingBox.width))
                var currentX = boundingBox.minX

                for item in row {
                    let itemWidth = CGFloat(item.area / Double(rowHeight))
                    let tileRect = CGRect(
                        x: currentX + padding,
                        y: boundingBox.minY + padding,
                        width: max(1, itemWidth - (padding * 2)),
                        height: max(1, rowHeight - (padding * 2))
                    )
                    tiles.append(TreemapTile(node: item.node, rect: tileRect))
                    currentX += itemWidth
                }
                boundingBox = CGRect(
                    x: boundingBox.minX,
                    y: boundingBox.minY + rowHeight,
                    width: boundingBox.width,
                    height: max(0, boundingBox.height - rowHeight)
                )
            }
        }

        for item in normalizedSizes {
            let shortestSide = Double(min(remainingRect.width, remainingRect.height))
            if currentRow.isEmpty {
                currentRow.append(item)
            } else {
                let currentWorst = worstAspectRatio(row: currentRow, length: shortestSide)
                var nextRow = currentRow
                nextRow.append(item)
                let nextWorst = worstAspectRatio(row: nextRow, length: shortestSide)

                if nextWorst <= currentWorst {
                    currentRow.append(item)
                } else {
                    layoutRow(currentRow, in: &remainingRect)
                    currentRow = [item]
                }
            }
        }

        if !currentRow.isEmpty {
            layoutRow(currentRow, in: &remainingRect)
        }

        return tiles
    }
}
