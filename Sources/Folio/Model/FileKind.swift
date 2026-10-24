import AppKit
import SwiftUI

enum FileKind: Hashable, Sendable {
    case markdown
    case json
    case sql
    case plain
    case code(CodeLanguage)

    static func from(url: URL?) -> FileKind {
        guard let ext = url?.pathExtension.lowercased(), !ext.isEmpty else { return .plain }
        switch ext {
        case "md", "markdown", "mdown", "mkd", "mmd": return .markdown
        case "json", "geojson": return .json
        case "sql", "psql": return .sql
        default:
            if let language = CodeLanguage.from(extension: ext) {
                return .code(language)
            }
            return .plain
        }
    }

    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .json: return "JSON"
        case .sql: return "SQL"
        case .plain: return L10n.t("Plain Text")
        case .code(let language): return language.displayName
        }
    }

    var symbolName: String {
        switch self {
        case .markdown: return "text.alignleft"
        case .json: return "curlybraces"
        case .sql: return "cylinder.split.1x2"
        case .plain: return "doc.plaintext"
        case .code: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var tint: Color {
        switch self {
        case .markdown: return Theme.kindMarkdown
        case .json: return Theme.kindJSON
        case .sql: return Theme.kindSQL
        case .plain: return Theme.kindPlain
        case .code: return Theme.kindCode
        }
    }

    var defaultExtension: String {
        switch self {
        case .markdown: return "md"
        case .json: return "json"
        case .sql: return "sql"
        case .plain: return "txt"
        case .code(let language): return language.defaultExtension
        }
    }

    var storageKey: String {
        switch self {
        case .markdown: return "markdown"
        case .json: return "json"
        case .sql: return "sql"
        case .plain: return "plain"
        case .code(let language): return "code:\(language.rawValue)"
        }
    }

    init?(storageKey: String) {
        switch storageKey {
        case "markdown": self = .markdown
        case "json": self = .json
        case "sql": self = .sql
        case "plain": self = .plain
        default:
            guard storageKey.hasPrefix("code:"),
                  let language = CodeLanguage(rawValue: String(storageKey.dropFirst(5))) else {
                return nil
            }
            self = .code(language)
        }
    }
}

enum LineEnding: String, CaseIterable, Sendable {
    case lf
    case crlf
    case cr

    var displayName: String {
        switch self {
        case .lf: return "LF"
        case .crlf: return "CRLF"
        case .cr: return "CR"
        }
    }

    var sequence: String {
        switch self {
        case .lf: return "\n"
        case .crlf: return "\r\n"
        case .cr: return "\r"
        }
    }

    static func detect(in text: String) -> LineEnding {
        var crlf = 0
        var lf = 0
        var cr = 0
        let chars = Array(text.utf8)
        for (index, byte) in chars.enumerated() {
            if byte == 0x0A {
                if index > 0, chars[index - 1] == 0x0D { crlf += 1 } else { lf += 1 }
            } else if byte == 0x0D {
                if index + 1 < chars.count, chars[index + 1] == 0x0A { continue }
                cr += 1
            }
        }
        if crlf >= lf && crlf >= cr && crlf > 0 { return .crlf }
        if cr > lf && cr > 0 { return .cr }
        return .lf
    }
}

enum EncodingLabel {
    static func name(for encoding: String.Encoding) -> String {
        switch encoding {
        case .utf8: return "UTF-8"
        case .utf16: return "UTF-16"
        case .utf16LittleEndian: return "UTF-16 LE"
        case .utf16BigEndian: return "UTF-16 BE"
        case .isoLatin1: return "Latin-1"
        case .macOSRoman: return "MacRoman"
        case .windowsCP1252: return "Windows-1252"
        default: return "Text"
        }
    }
}
