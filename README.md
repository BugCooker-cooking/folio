<div align="center">
  <img src="docs/icon.png" width="104" alt="Folio app icon">
  <h1>Folio</h1>
  <p><strong>A quiet, native macOS editor for text, Markdown, JSON, SQL, and code.</strong></p>
  <p>
    <img alt="macOS 14 or later" src="https://img.shields.io/badge/macOS-14%2B-111111?logo=apple&logoColor=white">
    <img alt="Swift 5.9 or later" src="https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white">
    <img alt="No third-party dependencies" src="https://img.shields.io/badge/dependencies-none-2ea44f">
    <img alt="MIT license" src="https://img.shields.io/badge/license-MIT-blue">
    <a href="https://github.com/BugCooker-cooking/folio/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/BugCooker-cooking/folio?color=blue"></a>
  </p>
  <p>
    <a href="#features">Features</a> ·
    <a href="#supported-files">Supported files</a> ·
    <a href="#download">Download</a> ·
    <a href="#build-and-run">Build</a> ·
    <a href="#keyboard-shortcuts">Shortcuts</a> ·
    <a href="README.zh-CN.md">简体中文</a>
  </p>
</div>

![Folio reading a Markdown document](docs/screenshots/markdown-reading.png)

Folio is a lightweight native macOS editor for the files you actually work with. Markdown opens in a calm, styled reading view, code opens with syntax highlighting, and JSON and SQL get the small tools they need. It is not an IDE, and that is the point.

Built with SwiftUI and AppKit, with no third-party dependencies. The release binary is about 2 MB; the app speaks seven interface languages and keeps everything in a single, quiet window.

## Why Folio

Most editors are either a browser tab with a text box or a full IDE with a project tree, terminal, and language server. Folio sits in between: it opens instantly, remembers how a file should look, and gives you native text editing when you need it.

- **Read first.** Markdown opens as a styled document. Click **Edit** to open the source beside the preview.
- **Native by default.** Undo, find, native text input, file prompts, menus, and keyboard behavior are AppKit's own.
- **Small on purpose.** No bundled framework, no web view for editing, no telemetry or account.

## Features

### Reading and writing

- Markdown, JSON, SQL, plain text, and common source code files
- Native `NSTextView` editing with undo and redo
- Find and replace with case-sensitive and regular-expression modes
- Selecting text highlights every matching occurrence in the document
- Line numbers, current-line highlighting, and live line/column, character, and word counts
- Automatic encoding detection (UTF-8, UTF-16, Latin-1) and line-ending preservation
- Drag-and-drop opening, recent files, and a sidebar of open documents
- Light, dark, and system appearance with adjustable type size
- Localized hover tips for every icon-only control

### Markdown

- Opens in a **styled reading view** by default
- The floating **Edit** button enters a live **source + preview split**
- Header modes: **Source**, **Split**, and **Preview**
- `⇧⌘P` cycles Preview → Split → Source
- Formatting toolbar: headings, bold, italic, strikethrough, inline code, code blocks, links, lists, quotes, tables, and horizontal rules
- Preview supports headings, emphasis, lists, quotes, fenced code, links, tables, and rules

### JSON

- Distinct colors for keys, strings, numbers, booleans, `null`, and punctuation
- Live validation in the status bar
- Format and minify without reordering keys
- Trailing commas are rejected instead of silently accepted

### SQL and code

- SQL keywords, types, strings, comments, numbers, and operators
- Lexical highlighting for Java, Kotlin, Scala, Python, JavaScript, TypeScript, C/C++, C#, Go, Rust, Ruby, PHP, Swift, Shell, HTML/XML/SVG, CSS/SCSS/LESS, YAML, and TOML
- Annotations, attributes, variables, function calls, markup tags, and config keys are styled where appropriate
- The status bar shows the detected language for every file

### Native macOS details

- Seven interface languages: English, Simplified Chinese, Traditional Chinese, Japanese, Korean, French, and German; follows the system language
- Standard open/save panels and unsaved-change prompts
- Native keyboard shortcuts, menu commands, and drag-and-drop
- Minimal, warm-paper visual system that adapts to light and dark mode

## Screenshots

| Markdown split editing | Java |
| --- | --- |
| ![Markdown split view](docs/screenshots/markdown-split.png) | ![Java syntax highlighting](docs/screenshots/code-java.png) |

![JSON data type colors](docs/screenshots/json-types.png)

## Supported files

| Kind | Extensions | Behavior |
| --- | --- | --- |
| Markdown | `.md`, `.markdown`, `.mdown`, `.mkd`, `.mmd` | Styled reading, split editing, formatting toolbar |
| JSON | `.json`, `.geojson` | Type-aware highlighting, validation, format, minify |
| SQL | `.sql`, `.psql` | Keyword, type, string, comment, and operator highlighting |
| Source code | Java, Kotlin, Scala, Python, JavaScript/TypeScript, C/C++, C#, Go, Rust, Ruby, PHP, Swift, Shell, HTML/XML, CSS, YAML, TOML | Language detection and lexical syntax highlighting |
| Plain text | Any other text file | Native editing, find, line numbers, counts |

Code extensions include `.java`, `.kt`, `.kts`, `.scala`, `.py`, `.pyw`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.ts`, `.tsx`, `.c`, `.h`, `.cpp`, `.cc`, `.hpp`, `.cs`, `.go`, `.rs`, `.rb`, `.php`, `.swift`, `.sh`, `.bash`, `.zsh`, `.html`, `.xml`, `.svg`, `.css`, `.scss`, `.less`, `.yaml`, `.yml`, and `.toml`.

Files are decoded with UTF-8/UTF-16/Latin-1 detection. Unsaved files keep their original encoding, BOM, and line endings when saved. Binary files and files over 24 MB are rejected.

The `Examples/` folder contains a few files to try the app with.

## Download

Prebuilt **universal** app for Apple Silicon and Intel: **[latest release](https://github.com/BugCooker-cooking/folio/releases/latest)**.

1. Download `Folio-1.0.0-macOS-universal.zip`.
2. Unzip it and move `Folio.app` to **Applications**.
3. The build is ad-hoc signed and not notarized. If macOS blocks the first launch, Control-click the app and choose **Open**.

## Build and run

Requirements: **macOS 14 or later**, **Xcode 16 or later** (Swift 5.9+ toolchain).

```sh
./Scripts/build.sh release
open .build/Folio.app
```

For a faster debug build:

```sh
./Scripts/build.sh debug
open .build/Folio.app
```

The app bundle is created at `.build/Folio.app` and is ad-hoc signed for local use. The build script also copies the icon and document-type metadata; use it when you need a complete `.app`.

To work on the code in Xcode:

```sh
open Package.swift
```

The `Folio` scheme runs the SwiftUI app. Use the build script when you need the bundled app with its icon and Finder document types.

## Usage notes

- **Markdown:** open a `.md` file and read. Press the floating **Edit** button or `⇧⌘P` to enter split editing. Use the header to switch between Source, Split, and Preview.
- **JSON:** use the toolbar format button or `⇧⌘F`; minify with `⇧⌘M`. The status bar reports validity.
- **Code:** open any supported source file. The suffix selects the language; the status bar shows it.
- **Find:** `⌘F` opens the find bar. `⌘G` and `⇧⌘G` move between matches. The find bar supports case-sensitive and regular-expression search.
- **Preferences:** `⌘,` opens appearance, line numbers, current-line highlighting, selection highlighting, and type size.
- **Close/quit:** unsaved changes prompt before closing a document or quitting the app.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `⌘N` | New document |
| `⌘O` | Open file |
| `⌘S` | Save |
| `⇧⌘S` | Save as |
| `⌘W` | Close document |
| `⌘F` | Find and replace |
| `⌘G` / `⇧⌘G` | Next / previous match |
| `⌘L` | Go to line |
| `⇧⌘P` | Cycle Markdown layout |
| `⌃⌘S` | Show or hide the sidebar |
| `⌘=` / `⌘-` / `⌘0` | Zoom in / out / actual size |
| `⌘,` | Settings |

## Architecture

Folio is a Swift Package Manager executable with no third-party dependencies:

```
Sources/Folio/
  App/        App entry point, menus, settings, localization
  Model/      Documents, file IO, code language detection, JSON tools, recents
  Editor/     NSTextView bridge, syntax engine, Markdown actions, gutter, find
  Views/      Sidebar, header, welcome, preview, find bar, status bar, tooltips
Examples/     Files to open and explore
Scripts/      Build script and code-drawn app icon
docs/         README assets
```

The editor is a single `NSTextView` wrapped in SwiftUI. Syntax tokens are produced off the main thread and applied when the buffer is idle, so typing stays responsive without a highlighting framework. The Markdown preview is SwiftUI, and all UI strings live in small embedded language tables so the `.app` remains self-contained.

## Scope

Folio is intentionally a focused editor, not an IDE:

- Syntax highlighting is lexical, not semantic. There is no LSP, completion, diagnostics, terminal, or project tree.
- Markdown preview covers core syntax: headings, emphasis, lists, quotes, fenced code, links, tables, and rules. Embedded HTML and MDX are shown as source.
- One window, with open documents in the sidebar. There are no tabs or multiple windows.
- Saves are explicit. There is no autosave.

Ideas that fit the same spirit: code folding, split-ratio persistence, more language grammars, optional autosave, and theme customization.

## Contributing

[Issues](https://github.com/BugCooker-cooking/folio/issues) and [pull requests](https://github.com/BugCooker-cooking/folio/pulls) are welcome. Please keep the app small and native:

- Run `./Scripts/build.sh release` before opening a PR.
- Avoid third-party dependencies unless they clearly earn their place.
- Test the affected file types and both light and dark appearance.
- Describe manual verification in the PR; there is no automated test suite yet.

## License

MIT. See [LICENSE](LICENSE). Release history is in [CHANGELOG.md](CHANGELOG.md).
