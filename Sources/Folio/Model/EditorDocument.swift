import Foundation
import Combine

enum EditorViewMode: String, CaseIterable, Identifiable {
    case edit
    case split
    case preview

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .edit: return "text.alignleft"
        case .split: return "rectangle.split.2x1"
        case .preview: return "eye"
        }
    }

    var title: String {
        switch self {
        case .edit: return L10n.t("Source")
        case .split: return L10n.t("Split")
        case .preview: return L10n.t("Preview")
        }
    }
}

final class EditorDocument: ObservableObject, Identifiable {
    let id = UUID()

    @Published var isDirty: Bool = false
    @Published private(set) var url: URL?
    @Published private(set) var kind: FileKind
    @Published private(set) var contentVersion: Int = 0
    @Published var viewMode: EditorViewMode = .edit
    @Published var jsonError: String?

    /// The current buffer. Mutated by the editor coordinator on the main thread.
    var text: String
    var encoding: String.Encoding
    var lineEnding: LineEnding
    var hadBOM: Bool

    /// Restored when the document is re-activated.
    var cursorLocation: Int = 0

    init(
        url: URL? = nil,
        text: String = "",
        kind: FileKind? = nil,
        encoding: String.Encoding = .utf8,
        lineEnding: LineEnding = .lf,
        hadBOM: Bool = false
    ) {
        self.url = url
        self.text = text
        self.kind = kind ?? FileKind.from(url: url)
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.hadBOM = hadBOM

        if self.kind == .markdown {
            viewMode = .preview
        }
    }

    var title: String {
        url?.lastPathComponent ?? L10n.t("Untitled")
    }

    var folderPath: String {
        guard let url else { return L10n.t("Not saved yet") }
        return (url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath
    }

    var displayPath: String {
        guard let url else { return L10n.t("Unsaved document") }
        return (url.path as NSString).abbreviatingWithTildeInPath
    }

    var suggestedFilename: String {
        if let url { return url.lastPathComponent }
        return "\(L10n.t("Untitled")).\(kind.defaultExtension)"
    }

    var languageLabel: String {
        if case .plain = kind, let ext = url?.pathExtension, !ext.isEmpty {
            return ext.uppercased()
        }
        return kind.displayName
    }

    func markEdited() {
        if !isDirty { isDirty = true }
    }

    func replaceText(_ newText: String, markDirty: Bool = true) {
        text = newText
        jsonError = nil
        contentVersion += 1
        if markDirty { isDirty = true }
    }

    func didSave(to newURL: URL?, encoding: String.Encoding, lineEnding: LineEnding, hadBOM: Bool) {
        if let newURL {
            let previousKind = kind
            url = newURL
            kind = FileKind.from(url: newURL)
            if kind != previousKind {
                viewMode = kind == .markdown ? .split : .edit
            }
        }
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.hadBOM = hadBOM
        isDirty = false
    }
}
