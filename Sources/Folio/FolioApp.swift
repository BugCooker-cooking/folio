import AppKit
import SwiftUI

@main
struct FolioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DocumentStore.shared
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        Window("Folio", id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(settings)
        }
        .defaultSize(width: 1180, height: 760)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            FolioCommands(store: store, settings: settings)
        }

        Settings {
            SettingsView(settings: settings)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = nil
        openCommandLineArguments()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let store = DocumentStore.shared
        if store.bypassTerminationPrompt {
            store.bypassTerminationPrompt = false
            return .terminateNow
        }
        return store.confirmTermination() ? .terminateNow : .terminateCancel
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        DocumentStore.shared.open(urls: urls)
    }

    private func openCommandLineArguments() {
        let paths = CommandLine.arguments
            .dropFirst()
            .filter { !$0.hasPrefix("-") }
            .map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        if !paths.isEmpty {
            DocumentStore.shared.open(urls: paths)
        }
    }
}
