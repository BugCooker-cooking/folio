import SwiftUI

struct MarkdownToolbar: View {
    let controller: EditorController

    var body: some View {
        HStack(spacing: 1) {
            FormatButton(title: "H1", help: L10n.t("Heading 1")) { controller.applyMarkdown(.heading(1)) }
            FormatButton(title: "H2", help: L10n.t("Heading 2")) { controller.applyMarkdown(.heading(2)) }
            FormatButton(title: "H3", help: L10n.t("Heading 3")) { controller.applyMarkdown(.heading(3)) }

            toolbarDivider

            FormatButton(symbol: "bold", help: L10n.t("Bold")) { controller.applyMarkdown(.bold) }
            FormatButton(symbol: "italic", help: L10n.t("Italic")) { controller.applyMarkdown(.italic) }
            FormatButton(symbol: "strikethrough", help: L10n.t("Strikethrough")) { controller.applyMarkdown(.strikethrough) }
            FormatButton(symbol: "chevron.left.forwardslash.chevron.right", help: L10n.t("Inline Code")) {
                controller.applyMarkdown(.inlineCode)
            }
            FormatButton(symbol: "curlybraces.square", help: L10n.t("Code Block")) {
                controller.applyMarkdown(.codeBlock)
            }
            FormatButton(symbol: "link", help: L10n.t("Link")) { controller.applyMarkdown(.link) }

            toolbarDivider

            FormatButton(symbol: "list.bullet", help: L10n.t("Bulleted List")) { controller.applyMarkdown(.bulletList) }
            FormatButton(symbol: "list.number", help: L10n.t("Numbered List")) { controller.applyMarkdown(.numberedList) }
            FormatButton(symbol: "text.quote", help: L10n.t("Quote")) { controller.applyMarkdown(.quote) }

            toolbarDivider

            FormatButton(symbol: "tablecells", help: L10n.t("Table")) { controller.applyMarkdown(.table) }
            FormatButton(symbol: "minus", help: L10n.t("Horizontal Rule")) { controller.applyMarkdown(.horizontalRule) }

            Spacer(minLength: 4)

            Text("MARKDOWN")
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(Theme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
        }
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(width: 1, height: 15)
            .padding(.horizontal, 5)
    }
}

private struct FormatButton: View {
    var title: String?
    var symbol: String?
    let help: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Group {
                if let title {
                    Text(title)
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 11.5, weight: .medium))
                }
            }
            .foregroundStyle(hovering ? Theme.ink : Theme.secondary)
            .frame(width: 27, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(hovering ? Theme.hover : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .hoverTip(help)
        .accessibilityLabel(help)
    }
}
