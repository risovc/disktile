import SwiftUI

public struct InspectorSidebarView: View {
    public let node: FileNode?
    public let rootSize: Int64
    public let onMoveToTrash: (FileNode) -> Void
    public let onRevealInFinder: (FileNode) -> Void

    public init(
        node: FileNode?,
        rootSize: Int64,
        onMoveToTrash: @escaping (FileNode) -> Void,
        onRevealInFinder: @escaping (FileNode) -> Void
    ) {
        self.node = node
        self.rootSize = rootSize
        self.onMoveToTrash = onMoveToTrash
        self.onRevealInFinder = onRevealInFinder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let node = node {
                // Header with icon and name
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(node.category.color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: node.category.iconName)
                            .font(.system(size: 22))
                            .foregroundStyle(node.category.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.name)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                            .help(node.name)

                        Text(node.category.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.top, 4)

                Divider()

                // Key Metrics
                VStack(spacing: 10) {
                    MetricRow(label: "Size", value: node.formattedSize, isEmphasized: true)
                    
                    if rootSize > 0 {
                        let percent = Double(node.size) / Double(rootSize)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("% of Current Scope")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.secondary)
                                Spacer()
                                Text(Formatters.formatPercentage(percent))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            ProgressView(value: min(1.0, max(0.0, percent)))
                                .tint(node.category.color)
                        }
                    }

                    if node.isDirectory {
                        MetricRow(label: "Contains", value: "\(node.itemCount.formatted()) items")
                    }

                    MetricRow(label: "Last Modified", value: node.formattedDate)
                    MetricRow(label: "Relative Age", value: node.relativeDate)
                    MetricRow(label: "Type", value: node.isDirectory ? "Folder" : "File")
                    if node.isHidden {
                        MetricRow(label: "Visibility", value: "Hidden (Dotfile)")
                    }
                }

                Divider()

                // Path box
                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Path")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)

                    Text(node.path)
                        .font(.system(size: 10, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 8) {
                    Button {
                        onRevealInFinder(node)
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder.badge.gearshape")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.regular)

                    Button(role: .destructive) {
                        onMoveToTrash(node)
                    } label: {
                        Label("Move to Trash", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.regular)
                    .tint(.red)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "hand.tap")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                    Text("Select a Tile")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    Text("Click on any folder or file tile to inspect size breakdown and options.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
    }
}

private struct MetricRow: View {
    let label: String
    let value: String
    var isEmphasized: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: isEmphasized ? .semibold : .regular))
                .foregroundStyle(isEmphasized ? Color.primary : Color.secondary)
        }
    }
}
