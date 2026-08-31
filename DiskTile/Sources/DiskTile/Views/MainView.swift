import SwiftUI
import AppKit

public struct MainView: View {
    @State private var scanState: ScanState = .idle
    @State private var rootNode: FileNode?
    @State private var currentScopeNode: FileNode?
    @State private var selectedNode: FileNode?
    @State private var showHiddenFiles: Bool = true
    @State private var showQuickClean: Bool = false
    @State private var showInspector: Bool = true
    @State private var searchText: String = ""
    @State private var targetURL: URL = FileManager.default.homeDirectoryForCurrentUser
    @State private var volumeInfo: VolumeInfo = VolumeInfo.currentMainVolume()
    @State private var scannerTask: Task<Void, Never>?
    @State private var showDeleteConfirmation: Bool = false
    @State private var nodeToTrash: FileNode?

    private let scanner = DiskScanner()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar / Scope bar
            topToolbarView

            Divider()

            // Breadcrumb Navigation
            if let current = currentScopeNode {
                HStack {
                    BreadcrumbBar(currentNode: current) { target in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentScopeNode = target
                            selectedNode = target
                        }
                    }
                    Spacer()
                    if current.parent != nil {
                        Button {
                            if let parent = current.parent {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentScopeNode = parent
                                    selectedNode = parent
                                }
                            }
                        } label: {
                            Label("Up", systemImage: "arrow.up")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.windowBackgroundColor))

                Divider()
            }

            // Main Content Area
            HStack(spacing: 0) {
                mainContentView

                if showInspector {
                    Divider()
                    InspectorSidebarView(
                        node: selectedNode,
                        rootSize: currentScopeNode?.size ?? rootNode?.size ?? 0,
                        onMoveToTrash: { node in
                            promptTrash(node: node)
                        },
                        onRevealInFinder: { node in
                            TrashManager.shared.revealInFinder(path: node.path)
                        }
                    )
                    .transition(.move(edge: .trailing))
                }
            }

            Divider()

            // Bottom Status and Trash Zone
            bottomStatusAndTrashBar
        }
        .frame(minWidth: 850, minHeight: 550)
        .sheet(isPresented: $showQuickClean) {
            QuickCleanSheet {
                startScan()
            }
        }
        .confirmationDialog(
            "Move to Trash?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                if let node = nodeToTrash {
                    performMoveToTrash(node: node)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let node = nodeToTrash {
                Text("Are you sure you want to move \"\(node.name)\" (\(node.formattedSize)) to the Trash?")
            }
        }
        .onAppear {
            startScan()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var topToolbarView: some View {
        HStack(spacing: 10) {
            // Target Directory Menu
            Menu {
                Button {
                    setTargetURL(FileManager.default.homeDirectoryForCurrentUser)
                } label: {
                    Label("Home (~/)", systemImage: "house")
                }

                Button {
                    let dl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? FileManager.default.homeDirectoryForCurrentUser
                    setTargetURL(dl)
                } label: {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }

                Button {
                    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.homeDirectoryForCurrentUser
                    setTargetURL(appSupport)
                } label: {
                    Label("Application Support", systemImage: "gearshape")
                }

                Button {
                    setTargetURL(URL(fileURLWithPath: "/Applications"))
                } label: {
                    Label("Applications", systemImage: "app.badge")
                }

                Divider()

                Button {
                    chooseCustomFolder()
                } label: {
                    Label("Choose Custom Folder...", systemImage: "folder.badge.plus")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(targetURL.lastPathComponent.isEmpty ? targetURL.path : targetURL.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .menuStyle(.borderlessButton)

            // Rescan Button
            Button {
                startScan()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Rescan Directory (⌘R)")
            .keyboardShortcut("r", modifiers: .command)

            Spacer()

            // Hidden Files Toggle
            Toggle(isOn: $showHiddenFiles) {
                Label("Hidden Files", systemImage: showHiddenFiles ? "eye" : "eye.slash")
                    .font(.system(size: 12))
            }
            .toggleStyle(.button)
            .onChange(of: showHiddenFiles) { _ in
                startScan()
            }
            .help("Toggle Dotfiles and Hidden Directories (⌘⇧.)")

            // Quick Clean Button
            Button {
                showQuickClean = true
            } label: {
                Label("Quick Clean", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            // Toggle Inspector
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showInspector.toggle()
                }
            } label: {
                Image(systemName: "sidebar.trailing")
            }
            .help("Toggle Inspector Sidebar")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private var mainContentView: some View {
        ZStack {
            switch scanState {
            case .idle:
                Text("Ready to scan")
                    .foregroundStyle(Color.secondary)

            case .scanning(let currentPath, let items, let bytes):
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Scanning storage...")
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(items.formatted()) items scanned (\(Formatters.formatBytes(bytes)))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Text(currentPath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .completed:
                if let current = currentScopeNode {
                    TreemapView(
                        rootNode: current,
                        selectedNode: $selectedNode,
                        onDrillDown: { node in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentScopeNode = node
                                selectedNode = node
                            }
                        },
                        onMoveToTrash: { node in
                            promptTrash(node: node)
                        },
                        onRevealInFinder: { node in
                            TrashManager.shared.revealInFinder(path: node.path)
                        }
                    )
                }

            case .failed(let error):
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.yellow)
                    Text("Scan Failed")
                        .font(.system(size: 14, weight: .semibold))
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Button("Try Again") {
                        startScan()
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var bottomStatusAndTrashBar: some View {
        HStack(spacing: 16) {
            // Volume Free Space Gauge
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                    Text("\(volumeInfo.name): \(Formatters.formatBytes(volumeInfo.freeBytes)) Free of \(Formatters.formatBytes(volumeInfo.totalBytes))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                ProgressView(value: volumeInfo.usedPercentage)
                    .tint(volumeInfo.usedPercentage > 0.9 ? .red : .accentColor)
                    .frame(width: 220)
            }

            Spacer()

            // Trash Drop Target
            TrashDropZoneView { droppedPath in
                handleDroppedPath(droppedPath)
            }
            .frame(width: 320)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Actions

    private func setTargetURL(_ url: URL) {
        targetURL = url
        startScan()
    }

    private func chooseCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = showHiddenFiles
        panel.prompt = "Analyze Folder"
        if panel.runModal() == .OK, let url = panel.url {
            setTargetURL(url)
        }
    }

    private func startScan() {
        scannerTask?.cancel()
        scannerTask = Task {
            scanState = .scanning(currentPath: targetURL.path, itemsScanned: 0, bytesScanned: 0)
            let startTime = Date()

            do {
                let root = try await scanner.scanDirectory(
                    at: targetURL,
                    includeHidden: showHiddenFiles
                ) { path, count, bytes in
                    Task { @MainActor in
                        self.scanState = .scanning(currentPath: path, itemsScanned: count, bytesScanned: bytes)
                    }
                }

                await MainActor.run {
                    self.rootNode = root
                    self.currentScopeNode = root
                    self.selectedNode = root.children.first
                    self.volumeInfo = VolumeInfo.currentMainVolume()
                    self.scanState = .completed(
                        totalItems: root.itemCount,
                        totalBytes: root.size,
                        duration: Date().timeIntervalSince(startTime)
                    )
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.scanState = .failed(error: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func promptTrash(node: FileNode) {
        self.nodeToTrash = node
        self.showDeleteConfirmation = true
    }

    private func handleDroppedPath(_ path: String) {
        do {
            try TrashManager.shared.moveToTrash(path: path)
            startScan()
        } catch {
            print("Failed to move dropped item to trash: \(error)")
        }
    }

    private func performMoveToTrash(node: FileNode) {
        do {
            try TrashManager.shared.moveToTrash(path: node.path)
            startScan()
        } catch {
            print("Failed to move \(node.path) to trash: \(error)")
        }
    }
}
