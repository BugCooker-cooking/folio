import AppKit
import Foundation
import UniformTypeIdentifiers

final class DocumentStore: ObservableObject {
    static let shared = DocumentStore()

    @Published private(set) var documents: [EditorDocument] = []
    @Published var activeID: UUID?
    @Published private(set) var recents: [RecentFile] = []
    @Published var isSidebarVisible = true
    @Published var findRequestID = 0

    weak var activeEditor: EditorController?

    /// Set only by the window close button after the user has confirmed.
    var bypassTerminationPrompt = false

    private let recentsKey = "folio.recentFiles"
    private let maxRecents = 10

    var activeDocument: EditorDocument? {
        guard let activeID else { return nil }
        return documents.first { $0.id == activeID }
    }

    init() {
        loadRecents()
    }

    // MARK: - Documents

    @discardableResult
    func newDocument(kind: FileKind = .plain) -> EditorDocument {
        let doc = EditorDocument(kind: kind)
        documents.append(doc)
        activeID = doc.id
        return doc
    }

    func activate(_ document: EditorDocument) {
        activeID = document.id
    }

    func closeActive() {
        guard let doc = activeDocument else { return }
        close(doc)
    }

    func close(_ document: EditorDocument) {
        if document.isDirty {
            let alert = NSAlert()
            alert.messageText = L10n.t("Save changes to “%@”?", document.title)
            alert.informativeText = L10n.t("Your changes will be lost if you don’t save them.")
            alert.addButton(withTitle: L10n.t("Save"))
            alert.addButton(withTitle: L10n.t("Cancel"))
            alert.addButton(withTitle: L10n.t("Don’t Save"))
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                guard save(document, as: document.url == nil) else { return }
            case .alertThirdButtonReturn:
                break
            default:
                return
            }
        }
        remove(document)
    }

    private func remove(_ document: EditorDocument) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents.remove(at: index)
        if activeID == document.id {
            if documents.isEmpty {
                activeID = nil
            } else {
                activeID = documents[min(index, documents.count - 1)].id
            }
        }
    }

    // MARK: - Opening

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.message = L10n.t("Choose a text, Markdown, JSON, SQL, or code file")
        panel.prompt = L10n.t("Open")
        if panel.runModal() == .OK {
            open(urls: panel.urls)
        }
    }

    func open(urls: [URL]) {
        for url in urls {
            openOne(url)
        }
    }

    private func openOne(_ rawURL: URL) {
        let url = rawURL.standardizedFileURL.resolvingSymlinksInPath()

        if let existing = documents.first(where: { $0.url?.standardizedFileURL == url }) {
            activate(existing)
            return
        }

        do {
            let loaded = try FileIO.load(url: url)
            // Drop a pristine untitled document so opening a file doesn't leave an empty tab behind.
            if let blank = documents.first(where: { $0.url == nil && $0.text.isEmpty && !$0.isDirty }) {
                remove(blank)
            }
            let doc = EditorDocument(
                url: url,
                text: loaded.text,
                kind: FileKind.from(url: url),
                encoding: loaded.encoding,
                lineEnding: loaded.lineEnding,
                hadBOM: loaded.hadBOM
            )
            documents.append(doc)
            activeID = doc.id
            addRecent(url, kind: doc.kind)
        } catch {
            presentError(L10n.t("Couldn’t open “%@”", url.lastPathComponent), error.localizedDescription)
            removeRecent(path: url.path)
        }
    }

    // MARK: - Saving

    func saveActive() {
        guard let doc = activeDocument else { return }
        _ = save(doc, as: doc.url == nil)
    }

    func saveActiveAs() {
        guard let doc = activeDocument else { return }
        _ = save(doc, as: true)
    }

    @discardableResult
    func save(_ document: EditorDocument, as forceNewLocation: Bool) -> Bool {
        var destination = document.url
        if destination == nil || forceNewLocation {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = document.suggestedFilename
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            panel.message = L10n.t("Save “%@”", document.title)
            panel.prompt = L10n.t("Save")
            guard panel.runModal() == .OK, let url = panel.url else { return false }
            destination = url
        }
        guard let url = destination else { return false }

        do {
            try FileIO.save(
                text: document.text,
                to: url,
                encoding: document.encoding,
                lineEnding: document.lineEnding,
                hadBOM: document.hadBOM
            )
            document.didSave(
                to: url,
                encoding: document.encoding,
                lineEnding: document.lineEnding,
                hadBOM: document.hadBOM
            )
            addRecent(url, kind: document.kind)
            return true
        } catch {
            presentError(L10n.t("Couldn’t save “%@”", url.lastPathComponent), error.localizedDescription)
            return false
        }
    }

    // MARK: - JSON actions

    func formatActiveJSON() {
        guard let doc = activeDocument, doc.kind == .json else { return }
        if let error = JSONTools.validationError(doc.text) {
            presentJSONError(error)
            return
        }
        guard let formatted = JSONTools.prettyPrinted(doc.text), formatted != doc.text else { return }
        doc.replaceText(formatted)
    }

    func minifyActiveJSON() {
        guard let doc = activeDocument, doc.kind == .json else { return }
        if let error = JSONTools.validationError(doc.text) {
            presentJSONError(error)
            return
        }
        guard let minified = JSONTools.minified(doc.text), minified != doc.text else { return }
        doc.replaceText(minified)
    }

    private func presentJSONError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.t("This isn’t valid JSON")
        alert.informativeText = message
        alert.addButton(withTitle: L10n.t("OK"))
        alert.runModal()
    }

    // MARK: - Editor actions

    func requestFind() {
        findRequestID &+= 1
    }

    func presentGoToLine() {
        guard let editor = activeEditor else { return }
        let alert = NSAlert()
        alert.messageText = L10n.t("Go to Line")
        alert.informativeText = L10n.t("Enter a line number.")
        alert.addButton(withTitle: L10n.t("Go"))
        alert.addButton(withTitle: L10n.t("Cancel"))
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.placeholderString = L10n.t("Line number")
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let trimmed = field.stringValue.trimmingCharacters(in: .whitespaces)
        guard let line = Int(trimmed), line > 0 else { return }
        editor.goToLine(line)
    }

    func revealActiveInFinder() {
        guard let url = activeDocument?.url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func copyActivePath() {
        guard let url = activeDocument?.url else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
    }

    func cycleMarkdownLayout() {
        guard let doc = activeDocument, doc.kind == .markdown else { return }
        switch doc.viewMode {
        case .preview: doc.viewMode = .split
        case .split: doc.viewMode = .edit
        case .edit: doc.viewMode = .preview
        }
    }

    // MARK: - Recents

    private func addRecent(_ url: URL, kind: FileKind) {
        recents.removeAll { $0.path == url.path }
        recents.insert(
            RecentFile(
                path: url.path,
                name: url.lastPathComponent,
                kindRaw: kind.storageKey,
                openedAt: Date()
            ),
            at: 0
        )
        if recents.count > maxRecents {
            recents = Array(recents.prefix(maxRecents))
        }
        storeRecents()
    }

    func removeRecent(path: String) {
        recents.removeAll { $0.path == path }
        storeRecents()
    }

    func clearRecents() {
        recents.removeAll()
        storeRecents()
    }

    private func loadRecents() {
        guard let data = UserDefaults.standard.data(forKey: recentsKey),
              let decoded = try? JSONDecoder().decode([RecentFile].self, from: data) else {
            return
        }
        recents = decoded.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func storeRecents() {
        guard let data = try? JSONEncoder().encode(recents) else { return }
        UserDefaults.standard.set(data, forKey: recentsKey)
    }

    // MARK: - Termination

    func confirmTermination() -> Bool {
        let dirty = documents.filter(\.isDirty)
        guard !dirty.isEmpty else { return true }

        let alert = NSAlert()
        alert.messageText = dirty.count == 1
            ? L10n.t("Save changes to “%@”?", dirty[0].title)
            : L10n.t("You have %d documents with unsaved changes.", dirty.count)
        alert.informativeText = L10n.t("Save your work before quitting Folio.")
        alert.addButton(withTitle: L10n.t("Save All"))
        alert.addButton(withTitle: L10n.t("Cancel"))
        alert.addButton(withTitle: L10n.t("Discard Changes"))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            for doc in dirty {
                if !save(doc, as: doc.url == nil) { return false }
            }
            return true
        case .alertThirdButtonReturn:
            return true
        default:
            return false
        }
    }

    // MARK: - Errors

    func presentError(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: L10n.t("OK"))
        alert.runModal()
    }
}
