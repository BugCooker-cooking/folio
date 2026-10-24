import Foundation

enum JSONTools {
    /// Returns a human-readable validation message, or `nil` when valid.
    static func validationError(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if hasTrailingComma(text) { return L10n.t("Trailing commas are not allowed in JSON.") }
        guard let data = text.data(using: .utf8) else { return L10n.t("The text is not valid UTF-8.") }
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return nil
        } catch {
            let nsError = error as NSError
            if let detail = nsError.userInfo[NSDebugDescriptionErrorKey] as? String {
                return detail
            }
            return nsError.localizedDescription
        }
    }

    private static func hasTrailingComma(_ text: String) -> Bool {
        var inString = false
        var escaped = false
        var previous: Character?
        for character in text {
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                    previous = character
                }
                continue
            }
            if character == "\"" {
                inString = true
                previous = character
                continue
            }
            if character.isWhitespace { continue }
            if (character == "}" || character == "]"), previous == "," {
                return true
            }
            previous = character
        }
        return false
    }

    static func prettyPrinted(_ text: String) -> String? {
        guard validationError(text) == nil else { return nil }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }

        var out = ""
        var depth = 0
        var inString = false
        var escaped = false
        let indentation = "  "

        func newline() {
            out.append("\n")
            out.append(String(repeating: indentation, count: depth))
        }

        for character in text {
            if inString {
                out.append(character)
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }

            switch character {
            case "\"":
                inString = true
                out.append(character)
            case "{", "[":
                out.append(character)
                depth += 1
                newline()
            case "}", "]":
                depth = max(0, depth - 1)
                if !out.hasSuffix("\n") && !out.hasSuffix("[") && !out.hasSuffix("{") {
                    out.append("\n")
                    out.append(String(repeating: indentation, count: depth))
                }
                out.append(character)
            case ",":
                out.append(character)
                newline()
            case ":":
                out.append(": ")
            case " ", "\n", "\r", "\t":
                continue
            default:
                out.append(character)
            }
        }

        return out
            .replacingOccurrences(of: "\\{\\s*\\n\\s*\\}", with: "{}", options: .regularExpression)
            .replacingOccurrences(of: "\\[\\s*\\n\\s*\\]", with: "[]", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .appending("\n")
    }

    static func minified(_ text: String) -> String? {
        guard validationError(text) == nil else { return nil }
        var out = ""
        var inString = false
        var escaped = false
        for character in text {
            if inString {
                out.append(character)
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }
            switch character {
            case "\"":
                inString = true
                out.append(character)
            case " ", "\n", "\r", "\t":
                continue
            default:
                out.append(character)
            }
        }
        return out
    }
}
