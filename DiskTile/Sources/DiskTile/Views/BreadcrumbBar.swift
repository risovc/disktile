import SwiftUI

public struct BreadcrumbBar: View {
    public let currentNode: FileNode
    public let onSelectNode: (FileNode) -> Void

    public init(currentNode: FileNode, onSelectNode: @escaping (FileNode) -> Void) {
        self.currentNode = currentNode
        self.onSelectNode = onSelectNode
    }

    private var nodeHierarchy: [FileNode] {
        var trail: [FileNode] = []
        var curr: FileNode? = currentNode
        while let node = curr {
            trail.insert(node, at: 0)
            curr = node.parent
        }
        return trail
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(nodeHierarchy.enumerated()), id: \.element.id) { index, node in
                    let isLast = index == nodeHierarchy.count - 1

                    Button {
                        onSelectNode(node)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: node.category.iconName)
                                .font(.system(size: 11))
                                .foregroundStyle(node.category.color)

                            Text(node.name)
                                .font(.system(size: 12, weight: isLast ? .semibold : .regular))
                                .foregroundStyle(isLast ? Color.primary : Color.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isLast ? Color.primary.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)

                    if !isLast {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
