import SwiftUI

struct HeaderBar: View {
    @EnvironmentObject private var store: DocumentStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            ToolButton(
                systemName: "sidebar.leading",
                isActive: store.isSidebarVisible,
                help: L10n.t("Toggle Sidebar")
            ) {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) {
                    store.isSidebarVisible.toggle()
                }
            }

            if let doc = store.activeDocument {
                DocumentTitle(doc: doc)
            } else {
                Text("Folio")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }

            Spacer(minLength: 12)

            if let doc = store.activeDocument {
                actions(for: doc)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .frame(height: 52)
        .background(WindowDragArea())
        .background(Theme.chrome)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func actions(for doc: EditorDocument) -> some View {
        HStack(spacing: 4) {
            if doc.kind == .json {
                ToolButton(
                    systemName: "text.alignleft",
                    help: L10n.t("Format JSON (⇧⌘F)")
                ) {
                    store.formatActiveJSON()
                }
            }

            if doc.kind == .markdown {
                MarkdownLayoutControl(doc: doc)
            }

            if doc.isDirty {
                ToolButton(
                    systemName: "arrow.down.circle.fill",
                    help: L10n.t("Save (⌘S)")
                ) {
                    store.saveActive()
                }
            }

            Menu {
                Button(L10n.t("Save As…")) { store.saveActiveAs() }
                Divider()
                Button(L10n.t("Reveal in Finder")) { store.revealActiveInFinder() }
                    .disabled(doc.url == nil)
                Button(L10n.t("Copy Path")) { store.copyActivePath() }
                    .disabled(doc.url == nil)
                Divider()
                Button(L10n.t("Close Document")) { store.close(doc) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 28, height: 26)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .hoverTip(L10n.t("More"))
            .accessibilityLabel(L10n.t("More"))
        }
    }
}

private struct MarkdownLayoutControl: View {
    @ObservedObject var doc: EditorDocument

    var body: some View {
        HStack(spacing: 1) {
            ForEach(EditorViewMode.allCases) { mode in
                Button {
                    doc.viewMode = mode
                } label: {
                    Image(systemName: mode.symbolName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(doc.viewMode == mode ? Theme.accent : Theme.secondary)
                        .frame(width: 26, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(doc.viewMode == mode ? Theme.accent.opacity(0.13) : .clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverTip(mode.title)
                .accessibilityLabel(mode.title)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.hover)
        )
    }
}

private struct DocumentTitle: View {
    @ObservedObject var doc: EditorDocument

    var body: some View {
        HStack(spacing: 9) {
            KindGlyph(kind: doc.kind, size: 22)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(doc.title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if doc.isDirty {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 5, height: 5)
                    }
                }
                Text(doc.folderPath)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .help(doc.displayPath)
    }
}
