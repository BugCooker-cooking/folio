import AppKit
import SwiftUI

struct MarkdownPreviewView: View {
    let text: String

    private var blocks: [MarkdownBlock] {
        MarkdownParser.blocks(from: text)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if blocks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.t("Nothing to preview"))
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .foregroundStyle(Theme.secondary)
                        Text(L10n.t("Start writing Markdown and it will appear here."))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.tertiary)
                    }
                    .padding(.top, 30)
                } else {
                    ForEach(blocks) { block in
                        blockView(block)
                    }
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 48)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity, alignment: .center)
            .textSelection(.enabled)
        }
        .background(Theme.paper)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block.kind {
        case .heading(let level, let content):
            Text(inline(content, size: headingSize(level), weight: .semibold, color: Theme.ink))
                .lineSpacing(3)
                .padding(.top, level <= 2 ? 10 : 3)

        case .paragraph(let content):
            Text(inline(content, size: 15.2, weight: .regular, color: Theme.ink))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

        case .code(let language, let code):
            CodeBlockView(language: language, code: code)

        case .quote(let content):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.accent.opacity(0.55))
                    .frame(width: 3)
                Text(inline(content, size: 14.5, weight: .regular, color: Theme.secondary))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .bullet(let items):
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.tertiary)
                            .frame(width: 12, alignment: .trailing)
                        Text(inline(item, size: 15, weight: .regular, color: Theme.ink))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .ordered(let start, let items):
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(items.enumerated()), id: \.offset) { offset, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(start + offset).")
                            .font(.system(size: 12.5).monospacedDigit())
                            .foregroundStyle(Theme.tertiary)
                            .frame(width: 22, alignment: .trailing)
                        Text(inline(item, size: 15, weight: .regular, color: Theme.ink))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .table(let headers, let alignments, let rows):
            tableView(headers: headers, alignments: alignments, rows: rows)

        case .rule:
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
                .padding(.vertical, 6)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 32
        case 2: return 25
        case 3: return 20
        case 4: return 17
        case 5: return 15
        default: return 13.5
        }
    }

    private func tableView(
        headers: [String],
        alignments: [MarkdownTableAlignment],
        rows: [[String]]
    ) -> some View {
        let columnCount = headers.count
        let widths: [CGFloat] = (0..<columnCount).map { column in
            let values = [headers[column]] + rows.map { column < $0.count ? $0[column] : "" }
            let measured = values.map { value in
                (value as NSString).size(
                    withAttributes: [.font: NSFont.systemFont(ofSize: 13.5)]
                ).width
            }.max() ?? 60
            return min(280, max(88, measured + 28))
        }

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<columnCount, id: \.self) { column in
                        tableCell(
                            headers[column],
                            width: widths[column],
                            alignment: alignments[column],
                            isHeader: true,
                            isLastColumn: column == columnCount - 1
                        )
                    }
                }

                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<columnCount, id: \.self) { column in
                            tableCell(
                                column < rows[rowIndex].count ? rows[rowIndex][column] : "",
                                width: widths[column],
                                alignment: alignments[column],
                                isHeader: false,
                                isLastColumn: column == columnCount - 1
                            )
                        }
                    }
                }
            }
            .background(Theme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: 1)
            }
        }
    }

    private func tableCell(
        _ text: String,
        width: CGFloat,
        alignment: MarkdownTableAlignment,
        isHeader: Bool,
        isLastColumn: Bool
    ) -> some View {
        Text(inline(text, size: 13.5, weight: isHeader ? .semibold : .regular, color: Theme.ink))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: width, alignment: alignment.frameAlignment)
            .background(isHeader ? Theme.hover : Color.clear)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.separator)
                    .frame(height: 1)
            }
            .overlay(alignment: .trailing) {
                if !isLastColumn {
                    Rectangle()
                        .fill(Theme.separator)
                        .frame(width: 1)
                }
            }
    }

    private func inline(
        _ source: String,
        size: CGFloat,
        weight: Font.Weight,
        color: Color
    ) -> AttributedString {
        var result: AttributedString
        if let parsed = try? AttributedString(
            markdown: source,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            result = parsed
        } else {
            result = AttributedString(source)
        }

        result.font = .system(size: size, weight: weight, design: .serif)
        result.foregroundColor = color

        for run in result.runs {
            let range = run.range
            if let intent = run.inlinePresentationIntent {
                if intent.contains(.code) {
                    result[range].font = .system(size: size * 0.92, design: .monospaced)
                    result[range].foregroundColor = Theme.accent
                }
                if intent.contains(.stronglyEmphasized) {
                    result[range].font = .system(size: size, weight: .semibold, design: .serif)
                }
                if intent.contains(.emphasized) {
                    result[range].font = .system(size: size, design: .serif).italic()
                }
            }
            if run.link != nil {
                result[range].foregroundColor = Theme.accent
                result[range].underlineStyle = .single
            }
        }
        return result
    }
}

private extension MarkdownTableAlignment {
    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

private struct CodeBlockView: View {
    let language: String?
    let code: String

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text((language ?? L10n.t("Code")).uppercased())
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(Theme.tertiary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        copied = false
                    }
                } label: {
                    Text(copied ? L10n.t("Copied") : L10n.t("Copy"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(copied ? Theme.success : Theme.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 12.5, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Theme.codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 1)
        }
    }
}

enum MarkdownTableAlignment {
    case leading
    case center
    case trailing
}

struct MarkdownBlock: Identifiable {
    enum Kind {
        case heading(Int, String)
        case paragraph(String)
        case code(String?, String)
        case quote(String)
        case bullet([String])
        case ordered(Int, [String])
        case table([String], [MarkdownTableAlignment], [[String]])
        case rule
    }

    let id: Int
    let kind: Kind
}

enum MarkdownParser {
    static func blocks(from text: String) -> [MarkdownBlock] {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        var blocks: [MarkdownBlock] = []
        var index = 0
        var id = 0

        func append(_ kind: MarkdownBlock.Kind) {
            blocks.append(MarkdownBlock(id: id, kind: kind))
            id += 1
        }

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let fence = String(trimmed.prefix(3))
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                index += 1
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    if candidate.hasPrefix(fence) { break }
                    code.append(lines[index])
                    index += 1
                }
                if index < lines.count { index += 1 }
                append(.code(language.isEmpty ? nil : language, code.joined(separator: "\n")))
                continue
            }

            if let heading = heading(in: trimmed) {
                append(.heading(heading.0, heading.1))
                index += 1
                continue
            }

            if isRule(trimmed) {
                append(.rule)
                index += 1
                continue
            }

            if let table = tableStart(lines, at: index) {
                index += 2
                var rows: [[String]] = []
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    if candidate.isEmpty { break }
                    guard let cells = tableCells(lines[index]) else { break }
                    var normalized = cells
                    if normalized.count < table.headers.count {
                        normalized += Array(repeating: "", count: table.headers.count - normalized.count)
                    }
                    if normalized.count > table.headers.count {
                        normalized = Array(normalized.prefix(table.headers.count))
                    }
                    rows.append(normalized)
                    index += 1
                }
                append(.table(table.headers, table.alignments, rows))
                continue
            }

            if trimmed.hasPrefix(">") {
                var quote: [String] = []
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    guard candidate.hasPrefix(">") else { break }
                    var content = String(candidate.dropFirst())
                    if content.hasPrefix(" ") { content.removeFirst() }
                    quote.append(content)
                    index += 1
                }
                append(.quote(quote.joined(separator: " ")))
                continue
            }

            if let first = bulletItem(trimmed) {
                var items = [first]
                index += 1
                while index < lines.count,
                      let item = bulletItem(lines[index].trimmingCharacters(in: .whitespaces)) {
                    items.append(item)
                    index += 1
                }
                append(.bullet(items))
                continue
            }

            if let first = orderedItem(trimmed) {
                var items = [first.0]
                index += 1
                while index < lines.count,
                      let item = orderedItem(lines[index].trimmingCharacters(in: .whitespaces)) {
                    items.append(item.0)
                    index += 1
                }
                append(.ordered(first.1, items))
                continue
            }

            var paragraph = [trimmed]
            index += 1
            while index < lines.count {
                if tableStart(lines, at: index) != nil { break }
                let candidate = lines[index]
                let candidateTrimmed = candidate.trimmingCharacters(in: .whitespaces)
                if candidateTrimmed.isEmpty || isBlockStart(candidateTrimmed) {
                    break
                }
                paragraph.append(candidateTrimmed)
                index += 1
            }
            append(.paragraph(paragraph.joined(separator: " ")))
        }

        return blocks
    }

    private static func heading(in line: String) -> (Int, String)? {
        var level = 0
        for character in line {
            if character == "#" { level += 1 } else { break }
        }
        guard (1...6).contains(level) else { return nil }
        let rest = line.dropFirst(level)
        guard rest.isEmpty || rest.first == " " || rest.first == "\t" else { return nil }
        return (level, rest.trimmingCharacters(in: .whitespaces))
    }

    private static func isRule(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        guard compact.count >= 3, let first = compact.first, "-*_".contains(first) else { return false }
        return compact.allSatisfy { $0 == first }
    }

    private static func bulletItem(_ line: String) -> String? {
        guard line.count >= 2 else { return nil }
        let prefix = String(line.prefix(2))
        guard prefix == "- " || prefix == "* " || prefix == "+ " else { return nil }
        return String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }

    private static func orderedItem(_ line: String) -> (String, Int)? {
        var digits = ""
        for character in line {
            if character.isNumber {
                digits.append(character)
            } else {
                break
            }
        }
        guard !digits.isEmpty, let number = Int(digits) else { return nil }
        var remainder = line.dropFirst(digits.count)
        guard let punctuation = remainder.first, punctuation == "." || punctuation == ")" else { return nil }
        remainder = remainder.dropFirst()
        guard remainder.first == " " else { return nil }
        return (remainder.trimmingCharacters(in: .whitespaces), number)
    }

    private static func tableStart(
        _ lines: [String],
        at index: Int
    ) -> (headers: [String], alignments: [MarkdownTableAlignment])? {
        guard index + 1 < lines.count else { return nil }
        guard let headers = tableCells(lines[index]),
              let alignments = tableAlignments(lines[index + 1]),
              !headers.isEmpty,
              headers.count == alignments.count else {
            return nil
        }
        return (headers, alignments)
    }

    private static func tableCells(_ line: String) -> [String]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else { return nil }
        var content = trimmed
        if content.hasPrefix("|") { content.removeFirst() }
        if content.hasSuffix("|") { content.removeLast() }
        let cells = content
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        return cells.isEmpty ? nil : cells
    }

    private static func tableAlignments(_ line: String) -> [MarkdownTableAlignment]? {
        guard let cells = tableCells(line), !cells.isEmpty else { return nil }
        var alignments: [MarkdownTableAlignment] = []
        for cell in cells {
            let trimmed = cell.trimmingCharacters(in: .whitespaces)
            let leading = trimmed.hasPrefix(":")
            let trailing = trimmed.hasSuffix(":")
            var dashes = trimmed
            if leading { dashes.removeFirst() }
            if trailing { dashes.removeLast() }
            guard dashes.count >= 3, dashes.allSatisfy({ $0 == "-" }) else { return nil }
            if leading && trailing {
                alignments.append(.center)
            } else if trailing {
                alignments.append(.trailing)
            } else {
                alignments.append(.leading)
            }
        }
        return alignments
    }

    private static func isBlockStart(_ line: String) -> Bool {
        if line.hasPrefix("```") || line.hasPrefix("~~~") { return true }
        if line.hasPrefix(">") { return true }
        if heading(in: line) != nil { return true }
        if isRule(line) { return true }
        if bulletItem(line) != nil { return true }
        if orderedItem(line) != nil { return true }
        return false
    }
}
