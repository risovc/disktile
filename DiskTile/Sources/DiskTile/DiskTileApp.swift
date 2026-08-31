import SwiftUI

@main
struct DiskTileApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .navigationTitle("DiskTile — Mac Storage Visualizer")
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Scan") {
                Button("Rescan Target") {
                    NotificationCenter.default.post(name: .init("TriggerRescan"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Open Folder...") {
                    NotificationCenter.default.post(name: .init("TriggerOpenFolder"), object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Toggle Hidden Files") {
                    NotificationCenter.default.post(name: .init("ToggleHiddenFiles"), object: nil)
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            }
        }
    }
}
