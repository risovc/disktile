# DiskTile — Native macOS Storage Visualizer & Cleaner

**DiskTile** is a native macOS storage analysis and reclamation tool designed with Apple's Human Interface Guidelines (macOS Sequoia / Sonoma / Ventura). It visualizes file system usage as an interactive, proportional squarified treemap where larger folders occupy larger tiles, allowing you to instantly pinpoint disk hogs, inspect hidden dotfiles/caches, and drag files/folders directly into the macOS Trash.

---

## 🌟 Key Features

1. **Squarified Proportional Treemap Tiles**:
   - Layout algorithm ensures clean rectangular aspect ratios.
   - Tiles are dynamically sized proportionally to their disk consumption.
   - Category-based color gradients (Developer builds, Caches, Media, Documents, Archives, System, Hidden dotfiles).
   - Live labels display human-readable size (`18.4 GB`), item count, and relative modification timestamps (`2h ago`, `3d ago`).

2. **Hidden Files & Deep Cache Exploration**:
   - Includes hidden files (`.cache`, `.git`, `.npm`, `.Trash`, `~/Library/Caches`, `DerivedData`, etc.) with visual badges.
   - One-click toggle switch or keyboard shortcut (`⌘⇧.`) to show/hide hidden dotfiles.

3. **Interactive Drag & Drop to Trash**:
   - Drag any tile or folder directly into the macOS Dock-styled Trash Bin drop zone.
   - Safe recycling using Apple's official `FileManager.default.trashItem(at:resultingItemURL:)` / `NSWorkspace.shared.recycle` APIs.
   - Immediate feedback and live space reclamation recalculation.

4. **⚡ "Quick Clean" Developer Presets**:
   - Scans and safely clears massive developer bloat and transient caches:
     - `~/Library/Developer/Xcode/DerivedData`
     - `node_modules` in project directories
     - `~/.npm/_cacache` & `~/.yarn/berry/cache`
     - `~/.cargo/registry/cache` & `~/.gradle/caches`
     - `~/Library/Caches/Homebrew` & `CocoaPods`
     - Old Xcode Archives and Downloaded `.dmg` / `.pkg` installers

5. **Finder-Style Breadcrumb Navigation**:
   - Clickable breadcrumb path trail (`~ > Library > Developer > Xcode > DerivedData`) for instant upward drill-out.
   - Double-click any tile to zoom and drill down into subfolders.

6. **Right-Click Context Menu & Inspector Sidebar**:
   - Context options: "Drill Down", "Reveal in Finder", "Copy Full Path", "Move to Trash".
   - Collapsible Inspector panel with progress gauge showing percentage of parent scope, full POSIX path, item counts, and timestamps.

---

## 📁 Project Architecture

```
MacStorageVisualizer/
├── DiskTile/                               # Native macOS Swift / SwiftUI App
│   ├── Package.swift                       # Swift Package Manager manifest (macOS 13+)
│   └── Sources/DiskTile/
│       ├── DiskTileApp.swift               # @main App & macOS Menu commands
│       ├── Models/
│       │   └── StorageModels.swift         # FileNode, FileCategory, VolumeInfo, QuickCleanPreset
│       ├── Services/
│       │   ├── DiskScanner.swift           # High-performance async POSIX/FileManager crawler
│       │   ├── TreemapEngine.swift         # Squarified Treemap layout algorithm (Bruls et al.)
│       │   └── TrashManager.swift          # Native Apple Trash & Finder integration
│       ├── Utilities/
│       │   └── Formatters.swift            # Byte formatting, date formatters, SF symbols
│       └── Views/
│           ├── MainView.swift              # Main Window, Toolbar, Scope Picker & Layout
│           ├── TreemapView.swift           # Interactive tile canvas, hover glow & drag-and-drop
│           ├── InspectorSidebarView.swift  # Metadata sidebar with % usage progress bars
│           ├── TrashDropZoneView.swift     # Dock-style drop zone with spring animations
│           ├── BreadcrumbBar.swift         # Clickable Finder path bar
│           └── QuickCleanSheet.swift       # Developer cache scanner & one-click reclaim sheet
│
├── scripts/
│   ├── storage_scanner.sh                  # Portable shell script with structured JSON output
│   └── build_and_run.sh                    # Automated macOS build and run script
│
└── preview_app/                            # Interactive Live Preview (macOS Aqua Web UI)
    ├── server.py                           # Zero-dependency Python HTTP backend
    ├── templates/
    │   └── index.html                      # Native macOS window template
    └── static/
        ├── css/macos.css                   # macOS frosted glass, traffic lights, SF styling
        └── js/treemap.js                   # Interactive treemap engine & drag-and-drop
```

---

## 🚀 How to Run

### 1. Build and Run on macOS (Native App)

On your MacBook, open Terminal in the project directory:

```bash
cd DiskTile
swift run -c release
```

Or open directly in **Xcode**:
```bash
open Package.swift
```
Select the `DiskTile` target and press **`⌘R`** (Run).

### 2. Standalone Shell Script Scanner

Run the standalone scanner in Terminal to analyze any directory and get JSON metrics:

```bash
./scripts/storage_scanner.sh ~ 2 true
```

### 3. Interactive Live Preview (Web )

To test the macOS UI, treemap calculations, and drag-and-drop trash mechanics immediately on your browser:

```bash
python3 preview_app/server.py 8888
```
Open **`http://localhost:8888`** in your browser.
