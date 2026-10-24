import AppKit
import SwiftUI

/// AppKit colors used by the text system. All colors are dynamic so the editor
/// follows the system appearance without re-highlighting.
enum EditorTheme {
    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
        NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    static let paper = dynamic(light: rgb(251, 250, 247), dark: rgb(27, 26, 24))
    static let chrome = dynamic(light: rgb(247, 245, 240), dark: rgb(22, 21, 19))
    static let sidebar = dynamic(light: rgb(243, 240, 234), dark: rgb(20, 19, 17))
    static let gutter = dynamic(light: rgb(247, 245, 240), dark: rgb(24, 23, 21))

    static let ink = dynamic(light: rgb(40, 37, 32), dark: rgb(232, 227, 218))
    static let secondaryInk = dynamic(light: rgb(122, 115, 104), dark: rgb(150, 144, 133))
    static let tertiaryInk = dynamic(light: rgb(165, 157, 145), dark: rgb(100, 95, 87))
    static let separator = dynamic(light: rgb(0, 0, 0, 0.085), dark: rgb(255, 255, 255, 0.09))
    static let gutterSeparator = dynamic(light: rgb(0, 0, 0, 0.06), dark: rgb(255, 255, 255, 0.06))

    static let accent = dynamic(light: rgb(184, 85, 51), dark: rgb(226, 138, 100))
    static let success = dynamic(light: rgb(55, 128, 80), dark: rgb(126, 199, 148))
    static let error = dynamic(light: rgb(184, 62, 54), dark: rgb(235, 126, 116))

    // Syntax palette: muted, paper-friendly, legible in both appearances.
    static let keyword = dynamic(light: rgb(128, 66, 132), dark: rgb(210, 158, 213))
    static let boolean = dynamic(light: rgb(139, 74, 143), dark: rgb(213, 162, 218))
    static let null = dynamic(light: rgb(132, 125, 114), dark: rgb(145, 139, 128))
    static let type = dynamic(light: rgb(44, 120, 116), dark: rgb(135, 204, 198))
    static let key = dynamic(light: rgb(48, 104, 152), dark: rgb(144, 190, 230))
    static let string = dynamic(light: rgb(74, 118, 54), dark: rgb(166, 202, 137))
    static let number = dynamic(light: rgb(161, 92, 30), dark: rgb(226, 174, 116))
    static let comment = dynamic(light: rgb(148, 141, 130), dark: rgb(112, 107, 98))
    static let punctuation = dynamic(light: rgb(126, 119, 108), dark: rgb(125, 119, 110))
    static let heading = dynamic(light: rgb(38, 35, 30), dark: rgb(240, 235, 226))
    static let link = dynamic(light: rgb(44, 103, 156), dark: rgb(139, 187, 232))
    static let marker = dynamic(light: rgb(175, 165, 151), dark: rgb(112, 106, 97))
    static let code = dynamic(light: rgb(150, 82, 42), dark: rgb(226, 164, 119))
    static let codeBackground = dynamic(
        light: rgb(40, 37, 32, 0.055),
        dark: rgb(255, 255, 255, 0.065)
    )
    static let codeBlockBackground = dynamic(
        light: rgb(40, 37, 32, 0.04),
        dark: rgb(255, 255, 255, 0.045)
    )

    static let selectionMatch = dynamic(
        light: rgb(44, 120, 116, 0.16),
        dark: rgb(135, 204, 198, 0.18)
    )
    static let currentLine = dynamic(
        light: rgb(40, 37, 32, 0.035),
        dark: rgb(255, 255, 255, 0.04)
    )
    static let findMatch = dynamic(
        light: rgb(228, 178, 60, 0.32),
        dark: rgb(230, 174, 74, 0.34)
    )
    static let findCurrent = dynamic(
        light: rgb(184, 85, 51, 0.35),
        dark: rgb(226, 138, 100, 0.45)
    )
    static let gutterActive = dynamic(light: rgb(62, 57, 50), dark: rgb(220, 214, 204))

    static func editorFont(size: CGFloat) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    static func paragraphStyle(fontSize: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = max(3.0, fontSize * 0.28)
        style.paragraphSpacing = 0
        style.defaultTabInterval = fontSize * 2.2
        style.tabStops = []
        return style
    }
}

/// SwiftUI palette. Kept alongside the AppKit palette so both layers agree.
enum Theme {
    static let paper = Color(nsColor: EditorTheme.paper)
    static let chrome = Color(nsColor: EditorTheme.chrome)
    static let sidebar = Color(nsColor: EditorTheme.sidebar)
    static let ink = Color(nsColor: EditorTheme.ink)
    static let secondary = Color(nsColor: EditorTheme.secondaryInk)
    static let tertiary = Color(nsColor: EditorTheme.tertiaryInk)
    static let separator = Color(nsColor: EditorTheme.separator)
    static let accent = Color(nsColor: EditorTheme.accent)
    static let success = Color(nsColor: EditorTheme.success)
    static let error = Color(nsColor: EditorTheme.error)

    static let kindMarkdown = Color(nsColor: EditorTheme.number)
    static let kindJSON = Color(nsColor: EditorTheme.string)
    static let kindSQL = Color(nsColor: EditorTheme.key)
    static let kindPlain = Color(nsColor: EditorTheme.secondaryInk)
    static let kindCode = Color(nsColor: EditorTheme.type)

    static let hover = Color.primary.opacity(0.055)
    static let selection = Color.primary.opacity(0.075)
    static let codeBackground = Color(nsColor: EditorTheme.codeBlockBackground)
}
