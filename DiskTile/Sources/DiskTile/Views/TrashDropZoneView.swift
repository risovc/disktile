import SwiftUI
import UniformTypeIdentifiers

public struct TrashDropZoneView: View {
    public let onDropNode: (String) -> Void
    @State private var isTargeted: Bool = false
    @State private var bounceAnimation: Bool = false

    public init(onDropNode: @escaping (String) -> Void) {
        self.onDropNode = onDropNode
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isTargeted ? Color.red.opacity(0.25) : Color.primary.opacity(0.06))
                    .frame(width: 44, height: 44)

                Image(systemName: isTargeted ? "trash.fill" : "trash")
                    .font(.system(size: 20))
                    .foregroundStyle(isTargeted ? Color.red : Color.secondary)
                    .scaleEffect(isTargeted ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isTargeted ? "Release to Move to Trash" : "Drag Files/Folders Here")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isTargeted ? Color.red : Color.primary)

                Text("Items will be moved to macOS Trash safely")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isTargeted ? Color.red.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isTargeted ? Color.red : Color.primary.opacity(0.12),
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [4, 4])
                )
        )
        .onDrop(of: [.fileURL, .text], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        onDropNode(url.path)
                    }
                }
            }
            return true
        }
    }
}
