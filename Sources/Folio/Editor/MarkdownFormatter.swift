import AppKit

enum MarkdownAction {
    case heading(Int)
    case bold
    case italic
    case strikethrough
    case inlineCode
    case codeBlock
    case link
    case bulletList
    case numberedList
    case quote
    case table
    case horizontalRule
}

/// Small, line-aware Markdown editing actions used by the formatting toolbar.
/// Every action is a single text replacement so it participates in undo.
enum MarkdownFormatter {
    private static let headingRegex = try! NSRegularExpression(
        pattern: #"^(\s{0,3})(#{1,6})[ \t]+"#
    )
    private static let bulletRegex = try! NSRegularExpression(
        pattern: #"^(\s*)[-*+][ \t]+"#
    )
    private static let numberedRegex = try! NSRegularExpression(
        pattern: #"^(\s*)\d+[.)][ \t]+"#
    )
    private static let quoteRegex = try! NSRegularExpression(
        pattern: #"^(\s*)>[ \t]?"#
    )
    private static let blockPrefixRegex = try! NSRegularExpression(
        pattern: #"^(\s*)(?:[-*+][ \t]+|\d+[.)][ \t]+|>[ \t]?)"#
    )

    static func apply(_ action: MarkdownAction, to textView: NSTextView) {
        switch action {
        case .heading(let level):
            applyLineTransform(to: textView) { lines in
                transformHeadings(lines, level: level)
            }
        case .bulletList:
            applyLineTransform(to: textView) { lines in
                transformList(lines, marker: .bullet)
            }
        case .numberedList:
            applyLineTransform(to: textView) { lines in
                transformList(lines, marker: .numbered)
            }
        case .quote:
            applyLineTransform(to: textView) { lines in
                transformList(lines, marker: .quote)
            }
        case .bold:
            wrapSelection(in: textView, prefix: "**", suffix: "**")
        case .italic:
            wrapSelection(in: textView, prefix: "*", suffix: "*")
        case .strikethrough:
            wrapSelection(in: textView, prefix: "~~", suffix: "~~")
        case .inlineCode:
            wrapSelection(in: textView, prefix: "`", suffix: "`")
        case .link:
            wrapLink(in: textView)
        case .codeBlock:
            insertCodeBlock(in: textView)
        case .table:
            insertTable(in: textView)
        case .horizontalRule:
            insertHorizontalRule(in: textView)
        }
        textView.window?.makeFirstResponder(textView)
    }

    // MARK: - Line transforms

    private enum ListMarker {
        case bullet
        case numbered
        case quote
    }

    private static func applyLineTransform(
        to textView: NSTextView,
        transform: ([String]) -> [String]
    ) {
        let ns = textView.string as NSString
        let selection = textView.selectedRange()
        let lineRange = ns.lineRange(for: selection)
        let block = ns.substring(with: lineRange)
        guard !block.isEmpty || selection.length == 0 else { return }

        let trailingNewline = block.hasSuffix("\n")
        var lines = block.components(separatedBy: "\n")
        if trailingNewline { lines.removeLast() }
        let lineIndex = currentLineIndex(in: ns, lineRange: lineRange, location: selection.location)

        let transformed = transform(lines)
        let joined = transformed.joined(separator: "\n") + (trailingNewline ? "\n" : "")
        guard joined != block else { return }

        let newSelection: NSRange
        if selection.length > 0 {
            let contentLength = joined.utf16.count - (trailingNewline ? 1 : 0)
            newSelection = NSRange(location: lineRange.location, length: contentLength)
        } else {
            let safeIndex = min(lineIndex, max(0, transformed.count - 1))
            let prefixLength = transformed.prefix(safeIndex).reduce(0) { $0 + $1.utf16.count + 1 }
            let lineLength = transformed.isEmpty ? 0 : transformed[safeIndex].utf16.count
            newSelection = NSRange(
                location: min(lineRange.location + prefixLength + lineLength, lineRange.location + joined.utf16.count),
                length: 0
            )
        }

        replace(in: textView, range: lineRange, with: joined, selection: newSelection)
    }

    private static func currentLineIndex(in ns: NSString, lineRange: NSRange, location: Int) -> Int {
        let start = min(lineRange.location, ns.length)
        let end = min(max(location, start), NSMaxRange(lineRange))
        let prefix = ns.substring(with: NSRange(location: start, length: end - start))
        return max(0, prefix.components(separatedBy: "\n").count - 1)
    }

    private static func transformHeadings(_ lines: [String], level: Int) -> [String] {
        let marker = String(repeating: "#", count: max(1, min(6, level))) + " "
        let nonEmpty = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let already = !nonEmpty.isEmpty && nonEmpty.allSatisfy { headingLevel(of: $0) == level }

        if nonEmpty.isEmpty {
            return lines.enumerated().map { index, line in
                index == 0 ? marker : line
            }
        }

        if already {
            return lines.map { line in
                guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return line }
                return replacing(headingRegex, in: line, template: "$1")
            }
        }

        return lines.map { line in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return line }
            let stripped = replacing(headingRegex, in: line, template: "$1")
            return inserting(marker, afterIndentOf: stripped)
        }
    }

    private static func transformList(_ lines: [String], marker: ListMarker) -> [String] {
        let regex: NSRegularExpression
        switch marker {
        case .bullet: regex = bulletRegex
        case .numbered: regex = numberedRegex
        case .quote: regex = quoteRegex
        }
        let nonEmpty = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let already = !nonEmpty.isEmpty && nonEmpty.allSatisfy {
            regex.firstMatch(in: $0, range: NSRange(location: 0, length: ($0 as NSString).length)) != nil
        }

        if nonEmpty.isEmpty {
            let emptyPrefix: String
            switch marker {
            case .bullet: emptyPrefix = "- "
            case .numbered: emptyPrefix = "1. "
            case .quote: emptyPrefix = "> "
            }
            return lines.enumerated().map { index, line in
                index == 0 ? emptyPrefix : line
            }
        }

        if already {
            return lines.map { line in
                guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return line }
                return replacing(blockPrefixRegex, in: line, template: "$1")
            }
        }

        var counter = 0
        return lines.map { line in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return line }
            let stripped = replacing(blockPrefixRegex, in: line, template: "$1")
            counter += 1
            let prefix: String
            switch marker {
            case .bullet: prefix = "- "
            case .numbered: prefix = "\(counter). "
            case .quote: prefix = "> "
            }
            return inserting(prefix, afterIndentOf: stripped)
        }
    }

    private static func headingLevel(of line: String) -> Int? {
        let range = NSRange(location: 0, length: (line as NSString).length)
        guard let match = headingRegex.firstMatch(in: line, range: range) else { return nil }
        return match.range(at: 2).length
    }

    private static func inserting(_ marker: String, afterIndentOf line: String) -> String {
        let indent = line.prefix { $0 == " " || $0 == "\t" }
        return String(indent) + marker + String(line.dropFirst(indent.count))
    }

    private static func replacing(_ regex: NSRegularExpression, in line: String, template: String) -> String {
        regex.stringByReplacingMatches(
            in: line,
            range: NSRange(location: 0, length: (line as NSString).length),
            withTemplate: template
        )
    }

    // MARK: - Inline actions

    private static func wrapSelection(in textView: NSTextView, prefix: String, suffix: String) {
        let ns = textView.string as NSString
        let selection = textView.selectedRange()
        guard NSMaxRange(selection) <= ns.length else { return }

        if selection.length == 0 {
            replace(
                in: textView,
                range: selection,
                with: prefix + suffix,
                selection: NSRange(location: selection.location + prefix.utf16.count, length: 0)
            )
            return
        }

        let selected = ns.substring(with: selection)
        if selected.utf16.count >= prefix.utf16.count + suffix.utf16.count,
           selected.hasPrefix(prefix), selected.hasSuffix(suffix) {
            let innerRange = NSRange(
                location: selection.location + prefix.utf16.count,
                length: selection.length - prefix.utf16.count - suffix.utf16.count
            )
            let inner = ns.substring(with: innerRange)
            replace(
                in: textView,
                range: selection,
                with: inner,
                selection: NSRange(location: selection.location, length: inner.utf16.count)
            )
        } else {
            let replacement = prefix + selected + suffix
            replace(
                in: textView,
                range: selection,
                with: replacement,
                selection: NSRange(location: selection.location + prefix.utf16.count, length: selected.utf16.count)
            )
        }
    }

    private static func wrapLink(in textView: NSTextView) {
        let ns = textView.string as NSString
        let selection = textView.selectedRange()
        guard NSMaxRange(selection) <= ns.length else { return }

        let label = selection.length > 0 ? ns.substring(with: selection) : "text"
        let replacement = "[\(label)](url)"
        let labelOffset = 1
        let urlOffset = labelOffset + label.utf16.count + 2 // ](
        let urlLength = 3
        let newSelection: NSRange
        if selection.length > 0 {
            newSelection = NSRange(location: selection.location + urlOffset, length: urlLength)
        } else {
            newSelection = NSRange(location: selection.location + labelOffset, length: label.utf16.count)
        }
        replace(in: textView, range: selection, with: replacement, selection: newSelection)
    }

    private static func insertCodeBlock(in textView: NSTextView) {
        let ns = textView.string as NSString
        let selection = textView.selectedRange()
        guard NSMaxRange(selection) <= ns.length else { return }

        if selection.length > 0 {
            let content = ns.substring(with: selection)
            let replacement = "```\n\(content)\n```"
            let contentStart = selection.location + 4
            replace(
                in: textView,
                range: selection,
                with: replacement,
                selection: NSRange(location: contentStart, length: content.utf16.count)
            )
        } else {
            let replacement = "```\n\n```"
            replace(
                in: textView,
                range: selection,
                with: replacement,
                selection: NSRange(location: selection.location + 4, length: 0)
            )
        }
    }

    private static func insertTable(in textView: NSTextView) {
        let ns = textView.string as NSString
        let selection = textView.selectedRange()
        guard NSMaxRange(selection) <= ns.length else { return }

        var insertion = """
        | Column 1 | Column 2 | Column 3 |
        | -------- | -------- | -------- |
        |          |          |          |
        """
        var location = selection.location

        if selection.location > 0 {
            let previousIsNewline = ns.character(at: selection.location - 1) == 0x0A
            let previousLineIsEmpty = selection.location < 2 || ns.character(at: selection.location - 2) == 0x0A
            if !previousIsNewline {
                insertion = "\n\n" + insertion
                location += 2
            } else if !previousLineIsEmpty {
                insertion = "\n" + insertion
                location += 1
            }
        }
        if selection.location < ns.length, ns.character(at: selection.location) != 0x0A {
            insertion += "\n"
        }

        let cellRange = (insertion as NSString).range(of: "Column 1")
        let newSelection = cellRange.location == NSNotFound
            ? NSRange(location: location, length: 0)
            : NSRange(location: location + cellRange.location, length: cellRange.length)

        replace(in: textView, range: selection, with: insertion, selection: newSelection)
    }

    private static func insertHorizontalRule(in textView: NSTextView) {
        let ns = textView.string as NSString
        let selection = textView.selectedRange()
        guard NSMaxRange(selection) <= ns.length else { return }

        var insertion = "---\n"
        var location = selection.location
        if selection.location > 0, ns.character(at: selection.location - 1) != 0x0A {
            insertion = "\n" + insertion
            location += 1
        }
        if selection.location < ns.length, ns.character(at: selection.location) != 0x0A {
            insertion += "\n"
        }

        replace(
            in: textView,
            range: selection,
            with: insertion,
            selection: NSRange(location: location + 4, length: 0)
        )
    }

    // MARK: - Replacement

    private static func replace(
        in textView: NSTextView,
        range: NSRange,
        with string: String,
        selection: NSRange
    ) {
        guard textView.shouldChangeText(in: range, replacementString: string) else { return }
        textView.textStorage?.replaceCharacters(in: range, with: string)
        textView.didChangeText()

        let length = (textView.string as NSString).length
        let location = min(max(0, selection.location), length)
        let selectionLength = min(selection.length, length - location)
        textView.setSelectedRange(NSRange(location: location, length: selectionLength))
    }
}
