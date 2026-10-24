import Foundation

enum TokenKind: Sendable, Equatable {
    case keyword
    case type
    case key
    case string
    case number
    case comment
    case literal
    case boolean
    case null
    case punctuation
    case heading(Int)
    case strong
    case emphasis
    case code
    case codeBlock
    case link
    case marker
    case quote
    case hr
}

struct HighlightToken: Sendable {
    let range: NSRange
    let kind: TokenKind
}

/// A small, dependency-free tokenizer. It highlights whole documents off the
/// main thread and returns value-only tokens; colors are applied on the main
/// thread where AppKit fonts/colors live.
enum SyntaxEngine {
    static func tokens(for text: String, kind: FileKind) -> [HighlightToken] {
        guard !text.isEmpty else { return [] }
        switch kind {
        case .json: return jsonTokens(text)
        case .sql: return sqlTokens(text)
        case .markdown: return markdownTokens(text)
        case .plain: return []
        case .code(let language): return CodeSyntaxEngine.tokens(for: text, language: language)
        }
    }

    // MARK: - JSON

    private static func jsonTokens(_ text: String) -> [HighlightToken] {
        let ns = text as NSString
        let length = ns.length
        var tokens: [HighlightToken] = []
        var i = 0

        while i < length {
            let c = ns.character(at: i)
            if c == 0x22 { // "
                let start = i
                i += 1
                while i < length {
                    let ch = ns.character(at: i)
                    if ch == 0x5C { // backslash
                        i += (i + 1 < length) ? 2 : 1
                        continue
                    }
                    if ch == 0x22 { i += 1; break }
                    i += 1
                }
                let end = min(i, length)
                var j = end
                while j < length, isWhitespace(ns.character(at: j)) { j += 1 }
                let isKey = j < length && ns.character(at: j) == 0x3A // :
                tokens.append(HighlightToken(
                    range: NSRange(location: start, length: end - start),
                    kind: isKey ? .key : .string
                ))
            } else if c == 0x2D || (c >= 0x30 && c <= 0x39) { // - or digit
                let start = i
                i += 1
                while i < length {
                    let ch = ns.character(at: i)
                    if (ch >= 0x30 && ch <= 0x39) || ch == 0x2E || ch == 0x65 || ch == 0x45 || ch == 0x2B || ch == 0x2D {
                        i += 1
                    } else {
                        break
                    }
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .number))
            } else if isWordStart(c) {
                let start = i
                i += 1
                while i < length, isWordCharacter(ns.character(at: i)) { i += 1 }
                let word = ns.substring(with: NSRange(location: start, length: i - start))
                if word == "true" || word == "false" {
                    tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .boolean))
                } else if word == "null" {
                    tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .null))
                }
            } else if isJSONPunctuation(c) {
                tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
                i += 1
            } else {
                i += 1
            }
        }
        return tokens
    }

    // MARK: - SQL

    private static let sqlKeywords: Set<String> = [
        "ADD", "ALL", "ALTER", "ANALYZE", "AND", "ANY", "AS", "ASC", "ATTACH", "AUTOINCREMENT",
        "BEGIN", "BETWEEN", "BY", "CASCADE", "CASE", "CAST", "CHECK", "COLLATE", "COLUMN",
        "COMMIT", "CONFLICT", "CONSTRAINT", "CREATE", "CROSS", "CURRENT", "CURRENT_DATE",
        "CURRENT_TIME", "CURRENT_TIMESTAMP", "DATABASE", "DECLARE", "DEFAULT", "DELETE", "DESC",
        "DETACH", "DISTINCT", "DO", "DROP", "EACH", "ELSE", "END", "ESCAPE", "EXCEPT", "EXISTS",
        "EXPLAIN", "FAIL", "FETCH", "FIRST", "FOLLOWING", "FOR", "FOREIGN", "FROM", "FULL",
        "FUNCTION", "GLOB", "GRANT", "GROUP", "HAVING", "IF", "IGNORE", "ILIKE", "IN", "INDEX",
        "INNER", "INSERT", "INSTEAD", "INTERSECT", "INTO", "IS", "JOIN", "KEY", "LAST", "LEFT",
        "LIKE", "LIMIT", "MATCH", "NATURAL", "NO", "NOT", "NOTHING", "NULL", "NULLS", "OF",
        "OFFSET", "ON", "OR", "ORDER", "OUTER", "OVER", "PARTITION", "PRAGMA", "PRECEDING",
        "PRIMARY", "PROCEDURE", "RAISE", "RANGE", "RECURSIVE", "REFERENCES", "REGEXP", "REINDEX",
        "RELEASE", "RENAME", "REPLACE", "RESTRICT", "RETURN", "RETURNING", "REVOKE", "RIGHT",
        "ROLLBACK", "ROW", "ROWS", "SAVEPOINT", "SCHEMA", "SELECT", "SET", "TABLE", "TEMP",
        "TEMPORARY", "THEN", "TO", "TRANSACTION", "TRIGGER", "TRUNCATE", "UNBOUNDED", "UNION",
        "UNIQUE", "UPDATE", "USING", "VACUUM", "VALUES", "VIEW", "WHEN", "WHERE", "WINDOW", "WITH"
    ]

    private static let sqlTypes: Set<String> = [
        "ARRAY", "BIGINT", "BIGSERIAL", "BLOB", "BOOL", "BOOLEAN", "BYTEA", "CHAR", "DATE",
        "DATETIME", "DECIMAL", "DOUBLE", "ENUM", "FLOAT", "INT", "INTEGER", "INTERVAL", "JSON",
        "JSONB", "MONEY", "NCHAR", "NUMERIC", "NVARCHAR", "PRECISION", "REAL", "SERIAL",
        "SMALLINT", "TEXT", "TIME", "TIMESTAMP", "TINYINT", "UUID", "VARBINARY", "VARCHAR", "XML"
    ]

    private static func sqlTokens(_ text: String) -> [HighlightToken] {
        let ns = text as NSString
        let length = ns.length
        var tokens: [HighlightToken] = []
        var i = 0

        while i < length {
            let c = ns.character(at: i)

            if c == 0x2D, i + 1 < length, ns.character(at: i + 1) == 0x2D { // --
                let start = i
                while i < length, ns.character(at: i) != 0x0A { i += 1 }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .comment))
            } else if c == 0x2F, i + 1 < length, ns.character(at: i + 1) == 0x2A { // /*
                let start = i
                i += 2
                while i + 1 < length, !(ns.character(at: i) == 0x2A && ns.character(at: i + 1) == 0x2F) {
                    i += 1
                }
                i = min(i + 2, length)
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .comment))
            } else if c == 0x27 { // '
                let start = i
                i += 1
                while i < length {
                    if ns.character(at: i) == 0x27 {
                        if i + 1 < length, ns.character(at: i + 1) == 0x27 {
                            i += 2
                            continue
                        }
                        i += 1
                        break
                    }
                    i += 1
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .string))
            } else if c == 0x22 || c == 0x60 { // " or `
                let quote = c
                let start = i
                i += 1
                while i < length {
                    if ns.character(at: i) == quote { i += 1; break }
                    i += 1
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .key))
            } else if c >= 0x30 && c <= 0x39 {
                let start = i
                i += 1
                while i < length {
                    let ch = ns.character(at: i)
                    if (ch >= 0x30 && ch <= 0x39) || ch == 0x2E || ch == 0x65 || ch == 0x45 || ch == 0x2B || ch == 0x2D {
                        i += 1
                    } else {
                        break
                    }
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .number))
            } else if isWordStart(c) {
                let start = i
                i += 1
                while i < length, isWordCharacter(ns.character(at: i)) { i += 1 }
                let word = ns.substring(with: NSRange(location: start, length: i - start))
                let upper = word.uppercased()
                let tokenKind: TokenKind?
                if sqlKeywords.contains(upper) {
                    tokenKind = .keyword
                } else if sqlTypes.contains(upper) {
                    tokenKind = .type
                } else {
                    tokenKind = nil
                }
                if let tokenKind {
                    tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: tokenKind))
                }
            } else if isSQLPunctuation(c) {
                tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
                i += 1
            } else {
                i += 1
            }
        }
        return tokens
    }

    // MARK: - Markdown

    private static let codeSpanRegex = try! NSRegularExpression(pattern: "`([^`\\n]+)`")
    private static let strongRegex = try! NSRegularExpression(pattern: "\\*\\*([^*\\n]+)\\*\\*|__([^_\\n]+)__")
    private static let emphasisRegex = try! NSRegularExpression(
        pattern: "(?<![*_A-Za-z0-9])([*_])(?![*_\\s])([^*_\\n]+?)\\1(?![*_A-Za-z0-9])"
    )
    private static let linkRegex = try! NSRegularExpression(pattern: "\\[([^\\]\\n]+)\\]\\(([^)\\n]+)\\)")

    private static func markdownTokens(_ text: String) -> [HighlightToken] {
        let ns = text as NSString
        let length = ns.length
        var tokens: [HighlightToken] = []
        var index = 0
        var inFence = false
        var fenceCharacter: unichar = 0x60
        var fenceStart = 0

        while index < length {
            var start = 0
            var end = 0
            var contentsEnd = 0
            ns.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: NSRange(location: index, length: 0))
            let lineRange = NSRange(location: start, length: contentsEnd - start)
            let line = ns.substring(with: lineRange)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lineLength = lineRange.length

            if inFence {
                let fenceString = fenceCharacter == 0x7E ? "~~~" : "```"
                if trimmed.hasPrefix(fenceString) {
                    tokens.append(HighlightToken(
                        range: NSRange(location: fenceStart, length: contentsEnd - fenceStart),
                        kind: .codeBlock
                    ))
                    tokens.append(HighlightToken(range: lineRange, kind: .marker))
                    inFence = false
                }
                index = end
                continue
            }

            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                fenceCharacter = trimmed.hasPrefix("~~~") ? 0x7E : 0x60
                fenceStart = lineRange.location
                inFence = true
                tokens.append(HighlightToken(range: lineRange, kind: .marker))
                index = end
                continue
            }

            if lineLength > 0 {
                let lineStart = lineRange.location
                var lead = 0
                while lead < lineLength {
                    let ch = ns.character(at: lineStart + lead)
                    if ch == 0x20 || ch == 0x09 { lead += 1 } else { break }
                }

                let contentStart = lineStart + lead
                let restLength = lineLength - lead

                // Horizontal rule
                if let hrRange = horizontalRuleRange(ns, location: contentStart, length: restLength) {
                    tokens.append(HighlightToken(range: hrRange, kind: .hr))
                } else if restLength > 0, ns.character(at: contentStart) == 0x23 { // #
                    var hashes = 0
                    while hashes < restLength, ns.character(at: contentStart + hashes) == 0x23 { hashes += 1 }
                    var content = contentStart + hashes
                    if hashes <= 6 {
                        while content < lineStart + lineLength {
                            let ch = ns.character(at: content)
                            if ch == 0x20 || ch == 0x09 { content += 1 } else { break }
                        }
                        tokens.append(HighlightToken(
                            range: NSRange(location: contentStart, length: hashes),
                            kind: .marker
                        ))
                        if content < lineStart + lineLength {
                            tokens.append(HighlightToken(
                                range: NSRange(location: content, length: lineStart + lineLength - content),
                                kind: .heading(hashes)
                            ))
                        }
                    }
                    tokens.append(contentsOf: inlineTokens(in: line, base: lineStart))
                } else if restLength > 0, ns.character(at: contentStart) == 0x3E { // >
                    var content = contentStart + 1
                    if content < lineStart + lineLength, ns.character(at: content) == 0x20 { content += 1 }
                    tokens.append(HighlightToken(
                        range: NSRange(location: contentStart, length: content - contentStart),
                        kind: .marker
                    ))
                    if content < lineStart + lineLength {
                        tokens.append(HighlightToken(
                            range: NSRange(location: content, length: lineStart + lineLength - content),
                            kind: .quote
                        ))
                    }
                    tokens.append(contentsOf: inlineTokens(in: line, base: lineStart))
                } else {
                    if let marker = listMarkerRange(ns, location: contentStart, length: restLength) {
                        tokens.append(HighlightToken(range: marker, kind: .marker))
                        // Task list checkbox
                        var after = NSMaxRange(marker)
                        while after < lineStart + lineLength, ns.character(at: after) == 0x20 { after += 1 }
                        if after + 2 < lineStart + lineLength,
                           ns.character(at: after) == 0x5B,
                           ns.character(at: after + 2) == 0x5D {
                            tokens.append(HighlightToken(
                                range: NSRange(location: after, length: 3),
                                kind: .literal
                            ))
                        }
                    }
                    tokens.append(contentsOf: inlineTokens(in: line, base: lineStart))
                }
            }

            index = end
            if end == start { break }
        }

        if inFence {
            tokens.append(HighlightToken(
                range: NSRange(location: fenceStart, length: length - fenceStart),
                kind: .codeBlock
            ))
        }
        return tokens
    }

    private static func horizontalRuleRange(_ ns: NSString, location: Int, length: Int) -> NSRange? {
        guard length > 0 else { return nil }
        var marker: unichar = 0
        var count = 0
        for offset in 0..<length {
            let ch = ns.character(at: location + offset)
            if ch == 0x20 || ch == 0x09 { continue }
            if ch == 0x2D || ch == 0x2A || ch == 0x5F {
                if marker == 0 { marker = ch }
                guard ch == marker else { return nil }
                count += 1
            } else {
                return nil
            }
        }
        return count >= 3 ? NSRange(location: location, length: length) : nil
    }

    private static func listMarkerRange(_ ns: NSString, location: Int, length: Int) -> NSRange? {
        guard length > 0 else { return nil }
        let first = ns.character(at: location)
        if first == 0x2D || first == 0x2A || first == 0x2B { // - * +
            if length == 1 { return NSRange(location: location, length: 1) }
            let next = ns.character(at: location + 1)
            if next == 0x20 || next == 0x09 { return NSRange(location: location, length: 1) }
            return nil
        }
        var digits = 0
        while digits < length {
            let ch = ns.character(at: location + digits)
            if ch >= 0x30 && ch <= 0x39 { digits += 1 } else { break }
        }
        guard digits > 0, digits < length else { return nil }
        let punctuation = ns.character(at: location + digits)
        guard punctuation == 0x2E || punctuation == 0x29 else { return nil } // . or )
        let after = location + digits + 1
        if after < location + length {
            let ch = ns.character(at: after)
            guard ch == 0x20 || ch == 0x09 else { return nil }
        }
        return NSRange(location: location, length: digits + 1)
    }

    private static func inlineTokens(in line: String, base: Int) -> [HighlightToken] {
        let ns = line as NSString
        let full = NSRange(location: 0, length: ns.length)
        var tokens: [HighlightToken] = []

        // Inline code
        for match in codeSpanRegex.matches(in: line, range: full) {
            let whole = match.range
            guard whole.length >= 2 else { continue }
            tokens.append(HighlightToken(range: offset(NSRange(location: whole.location, length: 1), base), kind: .marker))
            tokens.append(HighlightToken(range: offset(NSRange(location: NSMaxRange(whole) - 1, length: 1), base), kind: .marker))
            let content = match.range(at: 1)
            if content.location != NSNotFound, content.length > 0 {
                tokens.append(HighlightToken(range: offset(content, base), kind: .code))
            }
        }

        // Links
        for match in linkRegex.matches(in: line, range: full) {
            let label = match.range(at: 1)
            let url = match.range(at: 2)
            if label.location != NSNotFound {
                tokens.append(HighlightToken(range: offset(label, base), kind: .link))
            }
            if url.location != NSNotFound {
                tokens.append(HighlightToken(range: offset(url, base), kind: .marker))
            }
        }

        // Strong
        for match in strongRegex.matches(in: line, range: full) {
            let whole = match.range
            guard whole.length >= 4 else { continue }
            tokens.append(HighlightToken(range: offset(NSRange(location: whole.location, length: 2), base), kind: .marker))
            tokens.append(HighlightToken(range: offset(NSRange(location: NSMaxRange(whole) - 2, length: 2), base), kind: .marker))
            let group = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            if group.location != NSNotFound, group.length > 0 {
                tokens.append(HighlightToken(range: offset(group, base), kind: .strong))
            }
        }

        // Emphasis
        for match in emphasisRegex.matches(in: line, range: full) {
            let whole = match.range
            guard whole.length >= 3 else { continue }
            tokens.append(HighlightToken(range: offset(NSRange(location: whole.location, length: 1), base), kind: .marker))
            tokens.append(HighlightToken(range: offset(NSRange(location: NSMaxRange(whole) - 1, length: 1), base), kind: .marker))
            let content = match.range(at: 2)
            if content.location != NSNotFound, content.length > 0 {
                tokens.append(HighlightToken(range: offset(content, base), kind: .emphasis))
            }
        }

        return tokens
    }

    private static func offset(_ range: NSRange, _ base: Int) -> NSRange {
        NSRange(location: base + range.location, length: range.length)
    }

    // MARK: - Character helpers

    private static func isWhitespace(_ c: unichar) -> Bool {
        c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D
    }

    private static func isWordStart(_ c: unichar) -> Bool {
        (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c == 0x5F
    }

    private static func isWordCharacter(_ c: unichar) -> Bool {
        isWordStart(c) || (c >= 0x30 && c <= 0x39) || c == 0x24
    }

    private static func isJSONPunctuation(_ c: unichar) -> Bool {
        c == 0x7B || c == 0x7D || c == 0x5B || c == 0x5D || c == 0x2C || c == 0x3A
    }

    private static func isSQLPunctuation(_ c: unichar) -> Bool {
        switch c {
        case 0x28, 0x29, 0x5B, 0x5D, 0x7B, 0x7D, 0x2C, 0x3B, 0x2E, 0x3A,
             0x2B, 0x2D, 0x2A, 0x2F, 0x25, 0x3D, 0x3C, 0x3E, 0x21, 0x7C, 0x26, 0x5E, 0x7E:
            return true
        default:
            return false
        }
    }
}
