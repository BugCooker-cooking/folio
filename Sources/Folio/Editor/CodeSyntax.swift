import Foundation

struct CodeConfiguration {
    let lineComments: [String]
    let blockComments: Bool
    let quotes: Set<unichar>
    let backtickStrings: Bool
    let tripleQuotes: Bool
    let atAnnotations: Bool
    let dollarVariables: Bool
    let rubySymbols: Bool
    let keyBeforeColon: Bool
    let keyBeforeEquals: Bool
    let functionCalls: Bool
    let keywords: Set<String>
    let types: Set<String>
    let booleans: Set<String>
    let nulls: Set<String>
}

enum CodeSyntaxEngine {
    private static func words(_ text: String) -> Set<String> {
        Set(text.split(separator: " ").map(String.init))
    }

    private static let baseKeywords = words("""
    alignas alignof and as asm async await auto base begin break case catch chan class const constexpr continue \
    crate data debugger declare def default defer del delete do dyn echo elif else elseif end ensure enum eval \
    except export extends extern fallthrough final finally fn for foreach from func function fun get global go \
    goto group guard if impl implements import in include infix inline instanceof interface internal is join \
    lambda let local loop macro_rules match mod module move mut namespace native new next not of on open operator \
    or out override package pass print private protected protocol pub public raise range readonly record ref \
    reified require rescue retry return sealed select self Self set sizeof static struct super switch synchronized \
    tailrec then throw throws trait transient try type typedef typealias typeof union unsafe until use using val \
    var vararg virtual volatile when where while with yield
    """)

    private static let baseTypes = words("""
    Any Array Boolean Byte Character Date Double Error Exception Float Integer List Long Map Number Object Set \
    Short String Void bool boolean byte char double float int long object short string void
    """)

    private static let baseBooleans = words("true false")
    private static let baseNulls = words("null nil None nullptr undefined")

    private static let configurations: [CodeLanguage: CodeConfiguration] = {
        var result: [CodeLanguage: CodeConfiguration] = [:]
        for language in CodeLanguage.allCases {
            result[language] = configuration(for: language)
        }
        return result
    }()

    private static func programming(
        _ language: CodeLanguage,
        extraKeywords: Set<String> = [],
        extraTypes: Set<String> = [],
        lineComments: [String] = ["//"],
        blockComments: Bool = true,
        quotes: Set<unichar> = [0x22, 0x27],
        backtickStrings: Bool = false,
        tripleQuotes: Bool = false,
        atAnnotations: Bool = false,
        dollarVariables: Bool = false,
        rubySymbols: Bool = false,
        keyBeforeColon: Bool = false,
        keyBeforeEquals: Bool = false,
        functionCalls: Bool = true,
        booleans: Set<String>? = nil,
        nulls: Set<String>? = nil
    ) -> CodeConfiguration {
        CodeConfiguration(
            lineComments: lineComments,
            blockComments: blockComments,
            quotes: quotes,
            backtickStrings: backtickStrings,
            tripleQuotes: tripleQuotes,
            atAnnotations: atAnnotations,
            dollarVariables: dollarVariables,
            rubySymbols: rubySymbols,
            keyBeforeColon: keyBeforeColon,
            keyBeforeEquals: keyBeforeEquals,
            functionCalls: functionCalls,
            keywords: baseKeywords.union(extraKeywords),
            types: baseTypes.union(extraTypes),
            booleans: booleans ?? baseBooleans,
            nulls: nulls ?? baseNulls
        )
    }

    private static func configuration(for language: CodeLanguage) -> CodeConfiguration {
        switch language {
        case .java:
            return programming(
                language,
                extraKeywords: words("assert native strictfp transient volatile synchronized record sealed permits non-sealed"),
                extraTypes: words("ArrayList HashMap HashSet Optional Stream"),
                tripleQuotes: true,
                atAnnotations: true
            )
        case .kotlin:
            return programming(
                language,
                extraKeywords: words("by companion constructor delegate dynamic field file init lateinit noinline reified setparam suspend vararg"),
                extraTypes: words("Any Boolean Byte Char Double Float Int Long Short Unit Nothing MutableList MutableMap MutableSet Pair Triple"),
                tripleQuotes: true,
                atAnnotations: true
            )
        case .scala:
            return programming(
                language,
                extraKeywords: words("case class def given implicit object opaque trait using val var"),
                extraTypes: words("AnyRef Either Future List Map Nothing Option Set"),
                tripleQuotes: true,
                atAnnotations: true
            )
        case .python:
            return programming(
                language,
                extraKeywords: words("and assert del elif global nonlocal not or pass"),
                extraTypes: words("bytes bytearray complex dict enumerate filter float format frozenset hash id input int isinstance issubclass iter len list map max min object open print range repr set sorted str sum super tuple type zip"),
                lineComments: ["#"],
                blockComments: false,
                tripleQuotes: true,
                atAnnotations: true,
                booleans: words("True False true false"),
                nulls: words("None")
            )
        case .javascript:
            return programming(
                language,
                extraKeywords: words("debugger delete export get set of satisfies keyof infer readonly declare namespace abstract asserts unique override require module exports"),
                extraTypes: words("Promise RegExp Function Symbol BigInt"),
                backtickStrings: true
            )
        case .typescript:
            return programming(
                language,
                extraKeywords: words("debugger delete export get set of satisfies keyof infer readonly declare namespace abstract asserts unique override require module exports interface type enum implements"),
                extraTypes: words("Promise RegExp Function Symbol BigInt"),
                backtickStrings: true
            )
        case .c:
            return programming(
                language,
                extraKeywords: words("define endif ifdef ifndef include pragma undef restrict signed typedef unsigned"),
                extraTypes: words("int8_t int16_t int32_t int64_t size_t uint8_t uint16_t uint32_t uint64_t")
            )
        case .cpp:
            return programming(
                language,
                extraKeywords: words("co_await co_return co_yield concept const_cast constexpr decltype define dynamic_cast endif friend ifdef ifndef include mutable namespace noexcept operator pragma reinterpret_cast requires restrict signed static_assert static_cast template thread_local typedef typename unsigned using virtual"),
                extraTypes: words("int8_t int16_t int32_t int64_t size_t uint8_t uint16_t uint32_t uint64_t unique_ptr shared_ptr vector map set"),
                tripleQuotes: false
            )
        case .csharp:
            return programming(
                language,
                extraKeywords: words("as base checked decimal delegate event explicit fixed implicit internal lock out params partial ref sbyte sealed sizeof stackalloc typeof unchecked unsafe ushort using virtual"),
                extraTypes: words("decimal dynamic Task IEnumerable Dictionary"),
                tripleQuotes: true,
                atAnnotations: true
            )
        case .go:
            return programming(
                language,
                extraKeywords: words("chan defer fallthrough go range select"),
                extraTypes: words("any append bool byte cap complex64 complex128 copy delete error float32 float64 int int8 int16 int32 int64 len make map new panic print println recover rune string uint uint8 uint16 uint32 uint64 uintptr"),
                backtickStrings: true,
                nulls: words("nil")
            )
        case .rust:
            return programming(
                language,
                extraKeywords: words("crate dyn impl macro_rules mod move mut pub ref trait unsafe use where yield"),
                extraTypes: words("i8 i16 i32 i64 i128 isize u8 u16 u32 u64 u128 usize f32 f64 char str String Vec Option Result Box Rc Arc HashMap HashSet BTreeMap"),
                quotes: [0x22],
                nulls: words("None")
            )
        case .ruby:
            return programming(
                language,
                extraKeywords: words("alias attr_accessor attr_reader attr_writer begin defined? elsif end ensure extend include redo rescue retry unless until yield"),
                extraTypes: words("Array Hash String Integer Float Symbol Proc Range Regexp"),
                lineComments: ["#"],
                blockComments: false,
                rubySymbols: true,
                keyBeforeColon: true,
                nulls: words("nil")
            )
        case .php:
            return programming(
                language,
                extraKeywords: words("die echo empty eval exit include_once isset list require_once unset"),
                extraTypes: words("array callable iterable mixed never parent self"),
                lineComments: ["//", "#"],
                dollarVariables: true,
                nulls: words("null")
            )
        case .swift:
            return programming(
                language,
                extraKeywords: words("associatedtype actor any deinit extension fileprivate guard inout open rethrows some subscript typealias"),
                extraTypes: words("Int Int8 Int16 Int32 Int64 UInt UInt8 UInt16 UInt32 UInt64 Float Double Bool Character Array Dictionary Optional Result Error Never AnyObject"),
                tripleQuotes: true,
                atAnnotations: true,
                nulls: words("nil")
            )
        case .shell:
            return programming(
                language,
                extraKeywords: words("alias builtin case cd command coproc declare do done echo elif esac eval exec exit export fi for function getopts hash if in jobs kill let local printf pwd read readonly select set shift source then time trap type typeset ulimit umask unalias unset until wait while"),
                extraTypes: words("awk basename cat chmod chown cp cut date dirname echo find grep head ln ls mkdir mv printf pwd read rm sed sort tail tee touch tr uniq wc xargs"),
                lineComments: ["#"],
                blockComments: false,
                quotes: [0x22, 0x27],
                functionCalls: true,
                booleans: [],
                nulls: []
            )
        case .css:
            return CodeConfiguration(
                lineComments: ["//"],
                blockComments: true,
                quotes: [0x22, 0x27],
                backtickStrings: false,
                tripleQuotes: false,
                atAnnotations: false,
                dollarVariables: false,
                rubySymbols: false,
                keyBeforeColon: true,
                keyBeforeEquals: false,
                functionCalls: true,
                keywords: words("media import supports keyframes font-face page charset namespace important from to and or not only screen print all layer container"),
                types: [],
                booleans: [],
                nulls: []
            )
        case .yaml:
            return CodeConfiguration(
                lineComments: ["#"],
                blockComments: false,
                quotes: [0x22, 0x27],
                backtickStrings: false,
                tripleQuotes: false,
                atAnnotations: false,
                dollarVariables: false,
                rubySymbols: false,
                keyBeforeColon: true,
                keyBeforeEquals: false,
                functionCalls: false,
                keywords: [],
                types: [],
                booleans: words("true false yes no on off True False Yes No On Off"),
                nulls: words("null Null NULL ~")
            )
        case .toml:
            return CodeConfiguration(
                lineComments: ["#"],
                blockComments: false,
                quotes: [0x22, 0x27],
                backtickStrings: false,
                tripleQuotes: false,
                atAnnotations: false,
                dollarVariables: false,
                rubySymbols: false,
                keyBeforeColon: false,
                keyBeforeEquals: true,
                functionCalls: false,
                keywords: [],
                types: [],
                booleans: words("true false"),
                nulls: []
            )
        case .html, .xml:
            return CodeConfiguration(
                lineComments: [],
                blockComments: false,
                quotes: [],
                backtickStrings: false,
                tripleQuotes: false,
                atAnnotations: false,
                dollarVariables: false,
                rubySymbols: false,
                keyBeforeColon: false,
                keyBeforeEquals: false,
                functionCalls: false,
                keywords: [],
                types: [],
                booleans: [],
                nulls: []
            )
        }
    }

    static func tokens(for text: String, language: CodeLanguage) -> [HighlightToken] {
        if language == .html || language == .xml {
            return markupTokens(text)
        }
        guard let configuration = configurations[language] else { return [] }
        return codeTokens(text, configuration: configuration)
    }

    // MARK: - Prose-like source code

    private static func codeTokens(_ text: String, configuration: CodeConfiguration) -> [HighlightToken] {
        let ns = text as NSString
        let length = ns.length
        var tokens: [HighlightToken] = []
        var i = 0

        while i < length {
            let c = ns.character(at: i)

            if configuration.blockComments, c == 0x2F, next(in: ns, i) == 0x2A {
                let start = i
                i += 2
                while i + 1 < length, !(ns.character(at: i) == 0x2A && ns.character(at: i + 1) == 0x2F) {
                    i += 1
                }
                if i + 1 < length { i += 2 } else { i = length }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .comment))
                continue
            }

            if let marker = configuration.lineComments.first(where: { matches($0, in: ns, at: i) }) {
                let start = i
                i += marker.utf16.count
                while i < length, ns.character(at: i) != 0x0A { i += 1 }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .comment))
                continue
            }

            if configuration.tripleQuotes, (c == 0x22 || c == 0x27),
               i + 2 < length,
               ns.character(at: i + 1) == c,
               ns.character(at: i + 2) == c {
                let start = i
                let quote = c
                i += 3
                while i + 2 < length {
                    if ns.character(at: i) == quote,
                       ns.character(at: i + 1) == quote,
                       ns.character(at: i + 2) == quote {
                        i += 3
                        break
                    }
                    if ns.character(at: i) == 0x5C, i + 1 < length {
                        i += 2
                    } else {
                        i += 1
                    }
                }
                if i + 2 >= length { i = length }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .string))
                continue
            }

            if configuration.quotes.contains(c) || (configuration.backtickStrings && c == 0x60) {
                let start = i
                let quote = c
                let allowsNewline = quote == 0x60
                i += 1
                while i < length {
                    let ch = ns.character(at: i)
                    if ch == 0x5C {
                        i += (i + 1 < length) ? 2 : 1
                        continue
                    }
                    if ch == quote {
                        i += 1
                        break
                    }
                    if !allowsNewline, ch == 0x0A { break }
                    i += 1
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .string))
                continue
            }

            if configuration.atAnnotations, c == 0x40 {
                let start = i
                i += 1
                while i < length, isWordCharacter(ns.character(at: i)) || ns.character(at: i) == 0x2E {
                    i += 1
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .key))
                continue
            }

            if configuration.dollarVariables, c == 0x24 {
                let start = i
                i += 1
                if i < length, ns.character(at: i) == 0x7B {
                    while i < length, ns.character(at: i) != 0x7D { i += 1 }
                    if i < length { i += 1 }
                } else {
                    while i < length, isWordCharacter(ns.character(at: i)) || "?!#@$*-".utf16.contains(ns.character(at: i)) {
                        i += 1
                    }
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .key))
                continue
            }

            if configuration.rubySymbols, c == 0x3A,
               next(in: ns, i) != 0x3A,
               previous(in: ns, i) != 0x3A,
               isWordStart(next(in: ns, i)) {
                let start = i
                i += 1
                while i < length, isWordCharacter(ns.character(at: i)) { i += 1 }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .key))
                continue
            }

            if isWordStart(c) {
                let start = i
                i += 1
                while i < length, isWordCharacter(ns.character(at: i)) { i += 1 }
                let word = ns.substring(with: NSRange(location: start, length: i - start))
                let tokenKind: TokenKind?
                if configuration.booleans.contains(word) {
                    tokenKind = .boolean
                } else if configuration.nulls.contains(word) {
                    tokenKind = .null
                } else if configuration.keywords.contains(word) {
                    tokenKind = .keyword
                } else if configuration.types.contains(word) {
                    tokenKind = .type
                } else if configuration.functionCalls, nextNonSpace(in: ns, from: i) == 0x28 {
                    tokenKind = .type
                } else if configuration.keyBeforeColon, nextNonSpace(in: ns, from: i) == 0x3A {
                    tokenKind = .key
                } else if configuration.keyBeforeEquals, nextNonSpace(in: ns, from: i) == 0x3D {
                    tokenKind = .key
                } else {
                    tokenKind = nil
                }
                if let tokenKind {
                    tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: tokenKind))
                }
                continue
            }

            if c >= 0x30 && c <= 0x39 {
                let start = i
                if c == 0x30, let n = Optional(next(in: ns, i)), n == 0x78 || n == 0x58 {
                    i += 2
                    while i < length, isHexDigit(ns.character(at: i)) || ns.character(at: i) == 0x5F { i += 1 }
                } else if c == 0x30, next(in: ns, i) == 0x62 || next(in: ns, i) == 0x42 {
                    i += 2
                    while i < length, ns.character(at: i) == 0x30 || ns.character(at: i) == 0x31 || ns.character(at: i) == 0x5F { i += 1 }
                } else {
                    i += 1
                    while i < length, (ns.character(at: i) >= 0x30 && ns.character(at: i) <= 0x39) || ns.character(at: i) == 0x5F {
                        i += 1
                    }
                    if i < length, ns.character(at: i) == 0x2E {
                        i += 1
                        while i < length, (ns.character(at: i) >= 0x30 && ns.character(at: i) <= 0x39) || ns.character(at: i) == 0x5F {
                            i += 1
                        }
                    }
                    if i < length, ns.character(at: i) == 0x65 || ns.character(at: i) == 0x45 {
                        i += 1
                        if i < length, ns.character(at: i) == 0x2B || ns.character(at: i) == 0x2D { i += 1 }
                        while i < length, ns.character(at: i) >= 0x30 && ns.character(at: i) <= 0x39 { i += 1 }
                    }
                }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .number))
                continue
            }

            if isPunctuation(c) {
                tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
            }
            i += 1
        }

        return tokens
    }

    // MARK: - HTML / XML

    private static func markupTokens(_ text: String) -> [HighlightToken] {
        let ns = text as NSString
        let length = ns.length
        var tokens: [HighlightToken] = []
        var i = 0

        while i < length {
            let c = ns.character(at: i)

            if c == 0x26 { // &
                let start = i
                while i < length, ns.character(at: i) != 0x3B, ns.character(at: i) != 0x20, ns.character(at: i) != 0x0A {
                    i += 1
                }
                if i < length, ns.character(at: i) == 0x3B { i += 1 }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .number))
                continue
            }

            guard c == 0x3C else { // <
                i += 1
                continue
            }

            if hasPrefix("<!--", in: ns, at: i) {
                let start = i
                i += 4
                while i + 2 < length, !(ns.character(at: i) == 0x2D && ns.character(at: i + 1) == 0x2D && ns.character(at: i + 2) == 0x3E) {
                    i += 1
                }
                i = min(length, i + 3)
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .comment))
                continue
            }

            if hasPrefix("<![CDATA[", in: ns, at: i) {
                let start = i
                i += 9
                while i + 2 < length, !(ns.character(at: i) == 0x5D && ns.character(at: i + 1) == 0x5D && ns.character(at: i + 2) == 0x3E) {
                    i += 1
                }
                i = min(length, i + 3)
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .string))
                continue
            }

            if hasPrefix("<!", in: ns, at: i) || hasPrefix("<?", in: ns, at: i) {
                let start = i
                while i < length, ns.character(at: i) != 0x3E { i += 1 }
                if i < length { i += 1 }
                tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .comment))
                continue
            }

            let next = self.next(in: ns, i)
            guard isWordStart(next) || next == 0x2F else {
                i += 1
                continue
            }

            tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
            i += 1
            if i < length, ns.character(at: i) == 0x2F {
                tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
                i += 1
            }

            while i < length, isMarkupNameCharacter(ns.character(at: i)) { i += 1 }
            if i > 0 {
                let nameStart = previousTagNameStart(in: ns, before: i)
                if nameStart < i {
                    tokens.append(HighlightToken(
                        range: NSRange(location: nameStart, length: i - nameStart),
                        kind: .keyword
                    ))
                }
            }

            while i < length, ns.character(at: i) != 0x3E {
                let ch = ns.character(at: i)
                if ch == 0x2F {
                    tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
                    i += 1
                } else if ch == 0x3D {
                    tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
                    i += 1
                } else if ch == 0x22 || ch == 0x27 {
                    let start = i
                    let quote = ch
                    i += 1
                    while i < length, ns.character(at: i) != quote {
                        if ns.character(at: i) == 0x0A { break }
                        i += 1
                    }
                    if i < length, ns.character(at: i) == quote { i += 1 }
                    tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .string))
                } else if isMarkupNameCharacter(ch) {
                    let start = i
                    while i < length, isMarkupNameCharacter(ns.character(at: i)) { i += 1 }
                    tokens.append(HighlightToken(range: NSRange(location: start, length: i - start), kind: .key))
                } else if ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D {
                    i += 1
                } else {
                    tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
                    i += 1
                }
            }

            if i < length, ns.character(at: i) == 0x3E {
                tokens.append(HighlightToken(range: NSRange(location: i, length: 1), kind: .punctuation))
                i += 1
            }
        }

        return tokens
    }

    private static func previousTagNameStart(in ns: NSString, before index: Int) -> Int {
        var i = index
        while i > 0, isMarkupNameCharacter(ns.character(at: i - 1)) { i -= 1 }
        return i
    }

    // MARK: - Character helpers

    private static func next(in ns: NSString, _ index: Int) -> unichar {
        index + 1 < ns.length ? ns.character(at: index + 1) : 0
    }

    private static func previous(in ns: NSString, _ index: Int) -> unichar {
        index > 0 ? ns.character(at: index - 1) : 0
    }

    private static func matches(_ marker: String, in ns: NSString, at index: Int) -> Bool {
        let count = marker.utf16.count
        guard index + count <= ns.length else { return false }
        return ns.substring(with: NSRange(location: index, length: count)) == marker
    }

    private static func hasPrefix(_ marker: String, in ns: NSString, at index: Int) -> Bool {
        matches(marker, in: ns, at: index)
    }

    private static func nextNonSpace(in ns: NSString, from index: Int) -> unichar {
        var i = index
        while i < ns.length {
            let c = ns.character(at: i)
            if c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D { i += 1 } else { return c }
        }
        return 0
    }

    private static func isWordStart(_ c: unichar) -> Bool {
        (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c == 0x5F
    }

    private static func isWordCharacter(_ c: unichar) -> Bool {
        isWordStart(c) || (c >= 0x30 && c <= 0x39)
    }

    private static func isMarkupNameCharacter(_ c: unichar) -> Bool {
        isWordCharacter(c) || c == 0x2D || c == 0x3A || c == 0x2E || c == 0x40
    }

    private static func isHexDigit(_ c: unichar) -> Bool {
        (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x46) || (c >= 0x61 && c <= 0x66)
    }

    private static func isPunctuation(_ c: unichar) -> Bool {
        switch c {
        case 0x21, 0x23, 0x25, 0x26, 0x28...0x2F, 0x3A...0x40, 0x5B...0x5E, 0x60, 0x7B...0x7E:
            return true
        default:
            return false
        }
    }
}
