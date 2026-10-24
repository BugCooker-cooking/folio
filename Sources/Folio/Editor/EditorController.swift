import AppKit
import Combine
import Foundation

struct FindOptions: Equatable {
    var caseSensitive = false
    var regularExpression = false

    var nsOptions: NSString.CompareOptions {
        var options: NSString.CompareOptions = []
        if !caseSensitive { options.insert(.caseInsensitive) }
        return options
    }
}

final class EditorController: ObservableObject {
    @Published private(set) var matchCount = 0
    @Published private(set) var currentMatchIndex = 0
    @Published private(set) var searchError: String?

    weak var textView: NSTextView?

    /// Called when the find session starts or ends. Selection-match highlights
    /// yield to find highlights while a search is active.
    var onSearchActiveChanged: ((Bool) -> Void)?

    private var matches: [NSRange] = []
    private var lastQuery = ""
    private var lastOptions = FindOptions()
    private var regex: NSRegularExpression?
    private var refreshWork: DispatchWorkItem?

    var currentMatchRange: NSRange? {
        guard matches.indices.contains(currentMatchIndex) else { return nil }
        return matches[currentMatchIndex]
    }

    var isSearching: Bool { !lastQuery.isEmpty }

    func attach(textView: NSTextView) {
        self.textView = textView
    }

    // MARK: - Search

    func find(_ query: String, options: FindOptions) {
        lastQuery = query
        lastOptions = options
        refreshWork?.cancel()
        recompute(anchor: textView?.selectedRange().location ?? 0)
    }

    func refreshFind() {
        guard isSearching else { return }
        refreshWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.recompute(anchor: self.textView?.selectedRange().location ?? 0)
        }
        refreshWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    func findNext() {
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matches.count
        paintAndScroll()
    }

    func findPrevious() {
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matches.count) % matches.count
        paintAndScroll()
    }

    func clear() {
        lastQuery = ""
        matches = []
        matchCount = 0
        currentMatchIndex = 0
        searchError = nil
        clearTemporaryHighlights()
        onSearchActiveChanged?(false)
    }

    private func recompute(anchor: Int) {
        guard let textView else { return }
        clearTemporaryHighlights()
        matches = []
        regex = nil
        searchError = nil

        guard !lastQuery.isEmpty else {
            matchCount = 0
            currentMatchIndex = 0
            onSearchActiveChanged?(false)
            return
        }
        onSearchActiveChanged?(true)

        let string = textView.string
        let ns = string as NSString
        let full = NSRange(location: 0, length: ns.length)

        if lastOptions.regularExpression {
            do {
                let expression = try NSRegularExpression(
                    pattern: lastQuery,
                    options: lastOptions.caseSensitive ? [] : [.caseInsensitive]
                )
                regex = expression
                matches = expression
                    .matches(in: string, range: full)
                    .map(\.range)
                    .filter { $0.length > 0 }
            } catch {
                searchError = L10n.t("Invalid regular expression")
                matchCount = 0
                currentMatchIndex = 0
                return
            }
        } else {
            var searchRange = full
            while searchRange.length > 0 {
                let found = ns.range(of: lastQuery, options: lastOptions.nsOptions, range: searchRange)
                if found.location == NSNotFound { break }
                matches.append(found)
                let next = NSMaxRange(found)
                if next >= ns.length { break }
                searchRange = NSRange(location: next, length: ns.length - next)
            }
        }

        matchCount = matches.count
        if matches.isEmpty {
            currentMatchIndex = 0
            return
        }
        currentMatchIndex = matches.firstIndex { $0.location >= anchor } ?? 0
        paintAndScroll()
    }

    private func paintAndScroll() {
        guard let textView, let layoutManager = textView.layoutManager else { return }
        clearTemporaryHighlights()
        for (index, range) in matches.enumerated() {
            layoutManager.addTemporaryAttribute(
                .backgroundColor,
                value: index == currentMatchIndex ? EditorTheme.findCurrent : EditorTheme.findMatch,
                forCharacterRange: range
            )
        }
        if let range = currentMatchRange {
            textView.scrollRangeToVisible(range)
        }
    }

    private func clearTemporaryHighlights() {
        guard let textView, let layoutManager = textView.layoutManager else { return }
        let full = NSRange(location: 0, length: (textView.string as NSString).length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: full)
        layoutManager.removeTemporaryAttribute(.underlineStyle, forCharacterRange: full)
    }

    // MARK: - Replace

    func replaceCurrent(with template: String) {
        guard let textView, let range = currentMatchRange else { return }
        let replacement: String
        if lastOptions.regularExpression, let regex {
            if let match = regex.firstMatch(in: textView.string, range: range) {
                replacement = regex.replacementString(
                    for: match,
                    in: textView.string,
                    offset: 0,
                    template: template
                )
            } else {
                replacement = template
            }
        } else {
            replacement = template
        }
        replace(range: range, with: replacement, in: textView)
    }

    func replaceAll(with template: String) {
        guard let textView else { return }
        let string = textView.string
        let ns = string as NSString
        let full = NSRange(location: 0, length: ns.length)
        guard full.length > 0 else { return }

        let newString: String
        if lastOptions.regularExpression, let regex {
            newString = regex.stringByReplacingMatches(
                in: string,
                range: full,
                withTemplate: template
            )
        } else {
            newString = string.replacingOccurrences(
                of: lastQuery,
                with: template,
                options: lastOptions.nsOptions
            )
        }
        guard newString != string else { return }
        if textView.shouldChangeText(in: full, replacementString: newString) {
            textView.textStorage?.replaceCharacters(in: full, with: newString)
            textView.didChangeText()
        }
    }

    private func replace(range: NSRange, with replacement: String, in textView: NSTextView) {
        guard textView.shouldChangeText(in: range, replacementString: replacement) else { return }
        textView.textStorage?.replaceCharacters(in: range, with: replacement)
        textView.didChangeText()
        DispatchQueue.main.async { [weak self] in
            self?.refreshNowAfterReplace()
        }
    }

    private func refreshNowAfterReplace() {
        guard isSearching else { return }
        recompute(anchor: textView?.selectedRange().location ?? 0)
    }

    // MARK: - Navigation

    func focusEditor() {
        guard let textView else { return }
        textView.window?.makeFirstResponder(textView)
    }

    func applyMarkdown(_ action: MarkdownAction) {
        guard let textView else { return }
        MarkdownFormatter.apply(action, to: textView)
    }

    func goToLine(_ line: Int) {
        guard let textView else { return }
        let ns = textView.string as NSString
        var index = 0
        var current = 1
        while current < line, index < ns.length {
            let range = ns.lineRange(for: NSRange(location: index, length: 0))
            index = NSMaxRange(range)
            current += 1
        }
        let location = min(index, ns.length)
        textView.setSelectedRange(NSRange(location: location, length: 0))
        textView.scrollRangeToVisible(NSRange(location: location, length: 0))
        textView.window?.makeFirstResponder(textView)
    }
}
