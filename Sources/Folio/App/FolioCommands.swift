import AppKit
import SwiftUI

struct FolioCommands: Commands {
    @ObservedObject var store: DocumentStore
    @ObservedObject var settings: AppSettings

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(L10n.t("New Document")) {
                store.newDocument()
            }
            .keyboardShortcut("n")

            Button(L10n.t("Open…")) {
                store.presentOpenPanel()
            }
            .keyboardShortcut("o")

            Menu {
                if store.recents.isEmpty {
                    Button(L10n.t("No Recent Files")) {}
                        .disabled(true)
                } else {
                    ForEach(store.recents) { recent in
                        Button(recent.name) {
                            store.open(urls: [recent.url])
                        }
                    }
                    Divider()
                    Button(L10n.t("Clear Menu")) {
                        store.clearRecents()
                    }
                }
            } label: {
                Text(L10n.t("Open Recent"))
            }

            Divider()

            Button(L10n.t("Close Document")) {
                if let keyWindow = NSApp.keyWindow, keyWindow.title == "Folio Settings" {
                    keyWindow.performClose(nil)
                } else {
                    store.closeActive()
                }
            }
            .keyboardShortcut("w")
        }

        CommandGroup(replacing: .saveItem) {
            Button(L10n.t("Save")) {
                store.saveActive()
            }
            .keyboardShortcut("s")
            .disabled(store.activeDocument == nil)

            Button(L10n.t("Save As…")) {
                store.saveActiveAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(store.activeDocument == nil)

            Divider()

            Button(L10n.t("Format JSON")) {
                store.formatActiveJSON()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(store.activeDocument?.kind != .json)

            Button(L10n.t("Minify JSON")) {
                store.minifyActiveJSON()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .disabled(store.activeDocument?.kind != .json)
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            Button(L10n.t("Find…")) {
                store.requestFind()
            }
            .keyboardShortcut("f")
            .disabled(store.activeDocument == nil)

            Button(L10n.t("Find Next")) {
                store.activeEditor?.findNext()
            }
            .keyboardShortcut("g")
            .disabled(store.activeDocument == nil)

            Button(L10n.t("Find Previous")) {
                store.activeEditor?.findPrevious()
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            .disabled(store.activeDocument == nil)

            Button(L10n.t("Go to Line…")) {
                store.presentGoToLine()
            }
            .keyboardShortcut("l")
            .disabled(store.activeDocument == nil)
        }

        CommandGroup(after: .toolbar) {
            Button(store.isSidebarVisible ? L10n.t("Hide Sidebar") : L10n.t("Show Sidebar")) {
                store.isSidebarVisible.toggle()
            }
            .keyboardShortcut("s", modifiers: [.control, .command])

            Button(L10n.t("Cycle Markdown Layout")) {
                store.cycleMarkdownLayout()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(store.activeDocument?.kind != .markdown)

            Divider()

            Button(L10n.t("Zoom In")) {
                settings.fontSize = min(24, settings.fontSize + 1)
            }
            .keyboardShortcut("=", modifiers: .command)

            Button(L10n.t("Zoom Out")) {
                settings.fontSize = max(10, settings.fontSize - 1)
            }
            .keyboardShortcut("-", modifiers: .command)

            Button(L10n.t("Actual Size")) {
                settings.fontSize = 13.5
            }
            .keyboardShortcut("0", modifiers: .command)
        }
    }
}
