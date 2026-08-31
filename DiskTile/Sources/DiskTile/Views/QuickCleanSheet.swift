import SwiftUI

public struct QuickCleanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var presets: [QuickCleanPreset] = []
    @State private var isScanningPresets: Bool = true
    @State private var isCleaning: Bool = false
    @State private var cleanResult: String?
    public let onCleanupCompleted: () -> Void

    public init(onCleanupCompleted: @escaping () -> Void) {
        self.onCleanupCompleted = onCleanupCompleted
    }

    private var totalReclaimable: Int64 {
        presets.filter { $0.isSelected }.reduce(0) { $0 + $1.totalSize }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Clean Presets")
                        .font(.system(size: 16, weight: .bold))
                    Text("Safely reclaim storage by clearing heavy developer and system caches.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // List of Presets
            if isScanningPresets {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("Scanning cache and developer folders...")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach($presets) { $preset in
                            PresetRow(preset: $preset)
                        }
                    }
                    .padding(16)
                }
            }

            Divider()

            // Footer with Reclaim Action
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Selected Space")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                    Text(Formatters.formatBytes(totalReclaimable))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(totalReclaimable > 0 ? Color.green : Color.primary)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    performCleanup()
                } label: {
                    if isCleaning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Move Selected to Trash")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(totalReclaimable == 0 || isCleaning)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 440)
        .task {
            await scanPresets()
        }
    }

    private func scanPresets() async {
        isScanningPresets = true
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        var list: [QuickCleanPreset] = [
            QuickCleanPreset(
                id: "xcode",
                title: "Xcode DerivedData & Archives",
                subtitle: "~/Library/Developer/Xcode/DerivedData",
                icon: "hammer.fill",
                pathPatterns: ["\(home)/Library/Developer/Xcode/DerivedData", "\(home)/Library/Developer/Xcode/Archives"]
            ),
            QuickCleanPreset(
                id: "user_caches",
                title: "User App Caches",
                subtitle: "~/Library/Caches",
                icon: "trash.circle.fill",
                pathPatterns: ["\(home)/Library/Caches"]
            ),
            QuickCleanPreset(
                id: "node_modules",
                title: "NPM & Yarn Cache",
                subtitle: "~/.npm/_cacache, ~/.yarn/berry/cache",
                icon: "shippingbox.fill",
                pathPatterns: ["\(home)/.npm/_cacache", "\(home)/.yarn/berry/cache"]
            ),
            QuickCleanPreset(
                id: "cargo_rust",
                title: "Rust & Cargo Registry Cache",
                subtitle: "~/.cargo/registry/cache",
                icon: "gearshape.fill",
                pathPatterns: ["\(home)/.cargo/registry/cache"]
            ),
            QuickCleanPreset(
                id: "gradle",
                title: "Gradle & Android Build Caches",
                subtitle: "~/.gradle/caches, ~/.android/build-cache",
                icon: "ant.fill",
                pathPatterns: ["\(home)/.gradle/caches", "\(home)/.android/build-cache"]
            ),
            QuickCleanPreset(
                id: "homebrew",
                title: "Homebrew Download Caches",
                subtitle: "~/Library/Caches/Homebrew",
                icon: "mug.fill",
                pathPatterns: ["\(home)/Library/Caches/Homebrew"]
            )
        ]

        // Calculate sizes concurrently
        for i in 0..<list.count {
            var matched: [FileNode] = []
            for path in list[i].pathPatterns {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
                    let size = getFolderSize(path: path)
                    if size > 0 {
                        matched.append(
                            FileNode(
                                name: (path as NSString).lastPathComponent,
                                path: path,
                                isDirectory: isDir.boolValue,
                                isHidden: (path as NSString).lastPathComponent.hasPrefix("."),
                                size: size,
                                itemCount: 1,
                                modificationDate: Date(),
                                category: .caches
                            )
                        )
                    }
                }
            }
            list[i].matchedNodes = matched
        }

        presets = list
        isScanningPresets = false
    }

    private func getFolderSize(path: String) -> Int64 {
        var total: Int64 = 0
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return 0 }
        for case let subpath as String in enumerator {
            let fullPath = (path as NSString).appendingPathComponent(subpath)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        return total
    }

    private func performCleanup() {
        isCleaning = true
        let selectedPaths = presets.filter { $0.isSelected }.flatMap { $0.matchedNodes.map { $0.path } }
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = TrashManager.shared.batchMoveToTrash(paths: selectedPaths)
            DispatchQueue.main.async {
                isCleaning = false
                onCleanupCompleted()
                dismiss()
            }
        }
    }
}

private struct PresetRow: View {
    @Binding var preset: QuickCleanPreset

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $preset.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .disabled(preset.totalSize == 0)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(preset.totalSize > 0 ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: preset.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(preset.totalSize > 0 ? Color.orange : Color.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.title)
                    .font(.system(size: 13, weight: .medium))
                Text(preset.subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            Text(Formatters.formatBytes(preset.totalSize))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(preset.totalSize > 0 ? Color.primary : Color.secondary.opacity(0.6))
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
