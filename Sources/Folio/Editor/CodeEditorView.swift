import AppKit
import SwiftUI

struct CodeEditorView: NSViewRepresentable {
    let document: EditorDocument
    let settings: AppSettings
    let controller: EditorController
    let onTextChange: (String) -> Void
    let onSelectionChange: (NSRange, Int, Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.makeView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.update(document: document, settings: settings)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorView
        private let container = EditorContainerView()
        private var lineStarts: [Int] = [0]
        private var currentDocument: EditorDocument?
        private var currentVersion = -1
        private var lastFontSize: CGFloat = 0
        private var lastLineNumbers: Bool?
        private var lastCurrentLine: Bool?
        private var lastKind: FileKind?
        private var lastSelectionMatches: Bool?
        private var searchIsActive = false
        private var selectionHighlightWork: DispatchWorkItem?
        private var isProgrammatic = false
        private var generation = 0
        private var highlightWork: DispatchWorkItem?
        private let highlightQueue = DispatchQueue(label: "com.folio.highlight", qos: .userInitiated)
        private var scrollObserver: NSObjectProtocol?

        init(parent: CodeEditorView) {
            self.parent = parent
            super.init()
        }

        deinit {
            if let scrollObserver {
                NotificationCenter.default.removeObserver(scrollObserver)
            }
        }

        func makeView() -> NSView {
            let textView = container.textView
            textView.delegate = self
            parent.controller.attach(textView: textView)
            parent.controller.onSearchActiveChanged = { [weak self] active in
                guard let self else { return }
                self.searchIsActive = active
                if active {
                    self.selectionHighlightWork?.cancel()
                } else {
                    self.scheduleSelectionHighlights()
                }
            }
            scrollObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: container.scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                self?.container.gutter.needsDisplay = true
            }
            return container
        }

        func update(document: EditorDocument, settings: AppSettings) {
            if currentDocument?.id != document.id {
                persistCursor()
                currentDocument = document
                currentVersion = document.contentVersion
                load(text: document.text, cursor: document.cursorLocation)
            } else if currentVersion != document.contentVersion {
                currentDocument = document
                currentVersion = document.contentVersion
                load(text: document.text, cursor: document.cursorLocation)
            } else {
                currentDocument = document
            }

            if lastKind != document.kind {
                lastKind = document.kind
                scheduleHighlight(after: 0)
            }

            applySettings(settings)
        }

        private func persistCursor() {
            guard let currentDocument else { return }
            currentDocument.cursorLocation = container.textView.selectedRange().location
        }

        private func load(text: String, cursor: Int) {
            let textView = container.textView
            isProgrammatic = true
            textView.string = text
            textView.undoManager?.removeAllActions()

            recomputeLineStarts(text)
            container.gutter.lineStarts = lineStarts
            lastKind = currentDocument?.kind

            let base = baseAttributes()
            if let storage = textView.textStorage, storage.length > 0 {
                storage.setAttributes(base, range: NSRange(location: 0, length: storage.length))
            }
            textView.typingAttributes = base

            let length = (text as NSString).length
            let location = min(max(0, cursor), length)
            textView.setSelectedRange(NSRange(location: location, length: 0))
            if length > 0 {
                textView.scrollRangeToVisible(NSRange(location: location, length: 0))
            } else {
                container.scrollView.contentView.scroll(to: .zero)
                container.scrollView.reflectScrolledClipView(container.scrollView.contentView)
            }
            isProgrammatic = false

            updateSelectionStatus()
            scheduleHighlight(after: 0)
            container.gutter.needsDisplay = true
            textView.needsDisplay = true
            focusEditorSoon()
        }

        private func focusEditorSoon() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let textView = self.container.textView
                textView.window?.makeFirstResponder(textView)
            }
        }

        private func applySettings(_ settings: AppSettings) {
            let size = CGFloat(settings.fontSize)
            if lastFontSize != size {
                lastFontSize = size
                container.gutter.fontSize = size
                container.textView.typingAttributes = baseAttributes()
                scheduleHighlight(after: 0)
            }

            if lastLineNumbers != settings.showLineNumbers {
                lastLineNumbers = settings.showLineNumbers
                container.gutter.isHidden = !settings.showLineNumbers
                container.needsLayout = true
            }

            if lastCurrentLine != settings.highlightCurrentLine {
                lastCurrentLine = settings.highlightCurrentLine
                container.textView.highlightsCurrentLine = settings.highlightCurrentLine
            }

            if lastSelectionMatches != settings.highlightSelectionMatches {
                lastSelectionMatches = settings.highlightSelectionMatches
                if settings.highlightSelectionMatches {
                    scheduleSelectionHighlights()
                } else {
                    clearSelectionHighlights()
                }
            }
        }

        // MARK: - Text delegate

        func textDidChange(_ notification: Notification) {
            guard !isProgrammatic else { return }
            let text = container.textView.string
            recomputeLineStarts(text)
            container.gutter.lineStarts = lineStarts
            updateSelectionStatus()
            if !searchIsActive {
                clearSelectionHighlights()
            }
            scheduleSelectionHighlights()
            parent.onTextChange(text)
            scheduleHighlight(after: 0.12)
            container.gutter.needsDisplay = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            updateSelectionStatus()
            scheduleSelectionHighlights()
            container.gutter.needsDisplay = true
            container.textView.needsDisplay = true
        }

        // MARK: - Selection occurrence highlighting

        private func scheduleSelectionHighlights() {
            selectionHighlightWork?.cancel()
            guard !searchIsActive, parent.settings.highlightSelectionMatches else { return }
            let work = DispatchWorkItem { [weak self] in
                self?.applySelectionHighlights()
            }
            selectionHighlightWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: work)
        }

        private func clearSelectionHighlights() {
            guard let layoutManager = container.textView.layoutManager else { return }
            let full = NSRange(location: 0, length: (container.textView.string as NSString).length)
            if !searchIsActive {
                layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: full)
            }
        }

        private func applySelectionHighlights() {
            guard !searchIsActive, parent.settings.highlightSelectionMatches else { return }
            let textView = container.textView
            guard let layoutManager = textView.layoutManager else { return }

            let full = NSRange(location: 0, length: (textView.string as NSString).length)
            layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: full)

            let selection = textView.selectedRange()
            let ns = textView.string as NSString
            guard selection.length > 0, selection.length <= 240, NSMaxRange(selection) <= ns.length else { return }
            let needle = ns.substring(with: selection)
            guard !needle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

            var ranges: [NSRange] = []
            var searchRange = full
            while searchRange.length > 0, ranges.count < 3000 {
                let found = ns.range(of: needle, options: [], range: searchRange)
                if found.location == NSNotFound { break }
                ranges.append(found)
                let next = NSMaxRange(found)
                if next >= ns.length { break }
                searchRange = NSRange(location: next, length: ns.length - next)
            }

            guard !ranges.isEmpty else { return }
            for range in ranges {
                layoutManager.addTemporaryAttribute(
                    .backgroundColor,
                    value: EditorTheme.selectionMatch,
                    forCharacterRange: range
                )
            }
        }

        // MARK: - Selection and lines

        private func updateSelectionStatus() {
            let textView = container.textView
            let range = textView.selectedRange()
            let location = min(range.location, (textView.string as NSString).length)
            let (line, column) = lineColumn(for: location)
            container.gutter.currentLine = line - 1
            if let currentDocument {
                currentDocument.cursorLocation = location
            }
            parent.onSelectionChange(range, line, column)
        }

        private func lineColumn(for location: Int) -> (Int, Int) {
            guard !lineStarts.isEmpty else { return (1, 1) }
            var low = 0
            var high = lineStarts.count - 1
            var index = 0
            while low <= high {
                let mid = (low + high) / 2
                if lineStarts[mid] <= location {
                    index = mid
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            return (index + 1, location - lineStarts[index] + 1)
        }

        private func recomputeLineStarts(_ text: String) {
            let ns = text as NSString
            if ns.length == 0 {
                lineStarts = [0]
                return
            }
            var starts = [0]
            var index = 0
            while index < ns.length {
                let range = ns.lineRange(for: NSRange(location: index, length: 0))
                let next = NSMaxRange(range)
                if next <= index { break }
                if next < ns.length {
                    starts.append(next)
                } else if next == ns.length, ns.character(at: ns.length - 1) == 0x0A {
                    starts.append(ns.length)
                }
                index = next
            }
            lineStarts = starts
        }

        // MARK: - Highlighting

        private func baseAttributes() -> [NSAttributedString.Key: Any] {
            let size = CGFloat(parent.settings.fontSize)
            return [
                .font: EditorTheme.editorFont(size: size),
                .foregroundColor: EditorTheme.ink,
                .paragraphStyle: EditorTheme.paragraphStyle(fontSize: size)
            ]
        }

        private func scheduleHighlight(after delay: TimeInterval) {
            highlightWork?.cancel()
            generation &+= 1
            let generation = self.generation
            let text = container.textView.string
            let kind = currentDocument?.kind ?? .plain

            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.highlightQueue.async {
                    let tokens = SyntaxEngine.tokens(for: text, kind: kind)
                    DispatchQueue.main.async {
                        guard self.generation == generation else { return }
                        guard self.container.textView.string == text else { return }
                        self.apply(tokens: tokens, text: text)
                    }
                }
            }
            highlightWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }

        private func apply(tokens: [HighlightToken], text: String) {
            let textView = container.textView
            guard let storage = textView.textStorage, textView.string == text else { return }
            let full = NSRange(location: 0, length: storage.length)
            let base = baseAttributes()

            isProgrammatic = true
            storage.beginEditing()
            storage.setAttributes(base, range: full)
            for token in tokens {
                guard token.range.location >= 0,
                      token.range.location <= storage.length,
                      NSMaxRange(token.range) <= storage.length else { continue }
                apply(token: token, storage: storage)
            }
            storage.endEditing()
            textView.typingAttributes = base
            isProgrammatic = false

            container.gutter.needsDisplay = true
            textView.needsDisplay = true
        }

        private func apply(token: HighlightToken, storage: NSTextStorage) {
            let range = token.range
            guard range.length > 0 else { return }
            switch token.kind {
            case .keyword:
                storage.addAttribute(.foregroundColor, value: EditorTheme.keyword, range: range)
            case .type:
                storage.addAttribute(.foregroundColor, value: EditorTheme.type, range: range)
            case .key:
                storage.addAttribute(.foregroundColor, value: EditorTheme.key, range: range)
            case .string:
                storage.addAttribute(.foregroundColor, value: EditorTheme.string, range: range)
            case .number:
                storage.addAttribute(.foregroundColor, value: EditorTheme.number, range: range)
            case .comment:
                storage.addAttribute(.foregroundColor, value: EditorTheme.comment, range: range)
            case .literal:
                storage.addAttribute(.foregroundColor, value: EditorTheme.keyword, range: range)
            case .boolean:
                storage.addAttribute(.foregroundColor, value: EditorTheme.boolean, range: range)
            case .null:
                storage.addAttribute(.foregroundColor, value: EditorTheme.null, range: range)
            case .punctuation:
                storage.addAttribute(.foregroundColor, value: EditorTheme.punctuation, range: range)
            case .heading(let level):
                let scale: CGFloat
                switch level {
                case 1: scale = 1.58
                case 2: scale = 1.36
                case 3: scale = 1.2
                case 4: scale = 1.1
                case 5: scale = 1.03
                default: scale = 0.97
                }
                let size = CGFloat(parent.settings.fontSize) * scale
                storage.addAttributes([
                    .foregroundColor: EditorTheme.heading,
                    .font: NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
                ], range: range)
            case .strong:
                if let font = font(at: range.location, storage: storage) {
                    let bold = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                    storage.addAttribute(.font, value: bold, range: range)
                }
            case .emphasis:
                storage.addAttribute(.obliqueness, value: 0.14, range: range)
            case .code:
                let size = (font(at: range.location, storage: storage)?.pointSize ?? CGFloat(parent.settings.fontSize)) * 0.94
                storage.addAttributes([
                    .foregroundColor: EditorTheme.code,
                    .backgroundColor: EditorTheme.codeBackground,
                    .font: NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
                ], range: range)
            case .codeBlock:
                storage.addAttribute(.backgroundColor, value: EditorTheme.codeBlockBackground, range: range)
            case .link:
                storage.addAttribute(.foregroundColor, value: EditorTheme.link, range: range)
            case .marker:
                storage.addAttribute(.foregroundColor, value: EditorTheme.marker, range: range)
            case .quote:
                storage.addAttribute(.foregroundColor, value: EditorTheme.secondaryInk, range: range)
            case .hr:
                storage.addAttribute(.foregroundColor, value: EditorTheme.marker, range: range)
            }
        }

        private func font(at location: Int, storage: NSTextStorage) -> NSFont? {
            guard storage.length > 0, location < storage.length else { return nil }
            return storage.attribute(.font, at: location, effectiveRange: nil) as? NSFont
        }
    }
}
