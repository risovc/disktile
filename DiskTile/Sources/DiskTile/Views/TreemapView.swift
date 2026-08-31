import SwiftUI
import AppKit

public struct TreemapView: View {
    public let rootNode: FileNode
    @Binding public var selectedNode: FileNode?
    public let onDrillDown: (FileNode) -> Void
    public let onMoveToTrash: (FileNode) -> Void
    public let onRevealInFinder: (FileNode) -> Void

    @State private var hoveredTileId: UUID?

    public init(
        rootNode: FileNode,
        selectedNode: Binding<FileNode?>,
        onDrillDown: @escaping (FileNode) -> Void,
        onMoveToTrash: @escaping (FileNode) -> Void,
        onRevealInFinder: @escaping (FileNode) -> Void
    ) {
        self.rootNode = rootNode
        self._selectedNode = selectedNode
        self.onDrillDown = onDrillDown
        self.onMoveToTrash = onMoveToTrash
        self.onRevealInFinder = onRevealInFinder
    }

    public var body: some View {
        GeometryReader { geometry in
            let tiles = TreemapEngine.computeLayout(
                for: rootNode.children,
                in: CGRect(origin: .zero, size: geometry.size),
                padding: 2.0
            )

            ZStack(alignment: .topLeading) {
                // Background grid placeholder
                Color(NSColor.underPageBackgroundColor)

                if tiles.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.secondary)
                        Text("No items found or directory is empty")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(tiles) { tile in
                        TileItemView(
                            tile: tile,
                            isSelected: selectedNode?.id == tile.node.id,
                            isHovered: hoveredTileId == tile.node.id,
                            onSelect: {
                                selectedNode = tile.node
                            },
                            onDoubleTap: {
                                if tile.node.isDirectory && !tile.node.children.isEmpty {
                                    onDrillDown(tile.node)
                                }
                            },
                            onMoveToTrash: {
                                onMoveToTrash(tile.node)
                            },
                            onRevealInFinder: {
                                onRevealInFinder(tile.node)
                            }
                        )
                        .frame(width: tile.rect.width, height: tile.rect.height)
                        .position(x: tile.rect.midX, y: tile.rect.midY)
                        .onHover { hovering in
                            if hovering {
                                hoveredTileId = tile.node.id
                            } else if hoveredTileId == tile.node.id {
                                hoveredTileId = nil
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct TileItemView: View {
    let tile: TreemapTile
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onDoubleTap: () -> Void
    let onMoveToTrash: () -> Void
    let onRevealInFinder: () -> Void

    var body: some View {
        let node = tile.node
        let isLargeEnough = tile.rect.width > 70 && tile.rect.height > 45
        let isMedium = tile.rect.width > 40 && tile.rect.height > 30

        ZStack(alignment: .topLeading) {
            // Tile background with subtle gradient
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            node.category.color.opacity(isHovered ? 0.95 : 0.85),
                            node.category.color.opacity(isHovered ? 0.75 : 0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Inner content
            VStack(alignment: .leading, spacing: 2) {
                if isLargeEnough {
                    HStack(spacing: 4) {
                        Image(systemName: node.category.iconName)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(node.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer(minLength: 0)

                        if node.isHidden {
                            Text("HIDDEN")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.black.opacity(0.3))
                                .foregroundStyle(.white.opacity(0.8))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(node.formattedSize)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(node.relativeDate)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()

                        if node.isDirectory {
                            Text("\(node.itemCount) items")
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.2))
                                .foregroundStyle(.white.opacity(0.9))
                                .clipShape(Capsule())
                        }
                    }
                } else if isMedium {
                    Text(node.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Text(node.formattedSize)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSelected ? Color.white : (isHovered ? Color.white.opacity(0.5) : Color.black.opacity(0.15)),
                    lineWidth: isSelected ? 2.5 : (isHovered ? 1.5 : 0.5)
                )
        )
        .shadow(color: isSelected ? Color.black.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
        .onDrag {
            NSItemProvider(object: NSURL(fileURLWithPath: node.path))
        }
        .contextMenu {
            if node.isDirectory {
                Button {
                    onDoubleTap()
                } label: {
                    Label("Drill Down", systemImage: "arrow.down.right.and.arrow.up.left")
                }
            }

            Button {
                onRevealInFinder()
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(node.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                onMoveToTrash()
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
        }
        .help("\(node.name)\nSize: \(node.formattedSize)\nModified: \(node.formattedDate)\nPath: \(node.path)")
    }
}
