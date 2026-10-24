import Foundation

enum CodeLanguage: String, CaseIterable, Sendable {
    case java
    case kotlin
    case scala
    case python
    case javascript
    case typescript
    case c
    case cpp
    case csharp
    case go
    case rust
    case ruby
    case php
    case swift
    case shell
    case html
    case xml
    case css
    case yaml
    case toml

    static func from(extension ext: String) -> CodeLanguage? {
        switch ext.lowercased() {
        case "java": return .java
        case "kt", "kts": return .kotlin
        case "scala", "sc": return .scala
        case "py", "pyw", "pyi": return .python
        case "js", "jsx", "mjs", "cjs": return .javascript
        case "ts", "tsx", "mts", "cts": return .typescript
        case "c", "h": return .c
        case "cpp", "cc", "cxx", "hpp", "hh", "hxx", "ipp", "m", "mm": return .cpp
        case "cs", "csx": return .csharp
        case "go": return .go
        case "rs": return .rust
        case "rb", "rake", "gemspec": return .ruby
        case "php", "phtml": return .php
        case "swift": return .swift
        case "sh", "bash", "zsh", "fish", "ksh": return .shell
        case "html", "htm", "xhtml": return .html
        case "xml", "xsd", "xsl", "xslt", "svg": return .xml
        case "css", "scss", "less": return .css
        case "yaml", "yml": return .yaml
        case "toml": return .toml
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .scala: return "Scala"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .c: return "C"
        case .cpp: return "C++"
        case .csharp: return "C#"
        case .go: return "Go"
        case .rust: return "Rust"
        case .ruby: return "Ruby"
        case .php: return "PHP"
        case .swift: return "Swift"
        case .shell: return "Shell"
        case .html: return "HTML"
        case .xml: return "XML"
        case .css: return "CSS"
        case .yaml: return "YAML"
        case .toml: return "TOML"
        }
    }

    var defaultExtension: String {
        switch self {
        case .java: return "java"
        case .kotlin: return "kt"
        case .scala: return "scala"
        case .python: return "py"
        case .javascript: return "js"
        case .typescript: return "ts"
        case .c: return "c"
        case .cpp: return "cpp"
        case .csharp: return "cs"
        case .go: return "go"
        case .rust: return "rs"
        case .ruby: return "rb"
        case .php: return "php"
        case .swift: return "swift"
        case .shell: return "sh"
        case .html: return "html"
        case .xml: return "xml"
        case .css: return "css"
        case .yaml: return "yaml"
        case .toml: return "toml"
        }
    }
}
