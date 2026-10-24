import SwiftUI

struct StatusBar: View {
    @ObservedObject var document: EditorDocument
    @ObservedObject var status: EditorStatus

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(document.kind.tint)
                .frame(width: 5, height: 5)
            Text(document.languageLabel)
                .fontWeight(.medium)
                .foregroundStyle(Theme.secondary)

            if document.kind == .json {
                separator
                if let issue = document.jsonError {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(L10n.t("Invalid JSON"))
                    }
                    .foregroundStyle(Theme.error)
                    .help(issue)
                } else if !document.text.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                        Text(L10n.t("Valid"))
                    }
                    .foregroundStyle(Theme.success)
                }
            }

            separator
            Text(EncodingLabel.name(for: document.encoding))
                .foregroundStyle(Theme.tertiary)
            Text(document.lineEnding.displayName)
                .foregroundStyle(Theme.tertiary)

            Spacer(minLength: 12)

            if status.selectionLength > 0 {
                Text(L10n.t("%d selected", status.selectionLength))
                    .foregroundStyle(Theme.secondary)
            }
            Text(L10n.t("Ln %d, Col %d", status.line, status.column))
                .foregroundStyle(Theme.secondary)
            separator
            Text(L10n.t("%@ chars", status.characterCount.formatted()))
                .foregroundStyle(Theme.tertiary)
            Text(L10n.t("%@ words", status.wordCount.formatted()))
                .foregroundStyle(Theme.tertiary)
        }
        .font(.system(size: 10.5).monospacedDigit())
        .padding(.horizontal, 14)
        .frame(height: 26)
        .background(Theme.chrome)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
        }
    }

    private var separator: some View {
        Text("·")
            .foregroundStyle(Theme.tertiary)
    }
}
