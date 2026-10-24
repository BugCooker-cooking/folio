import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if !store.documents.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: L10n.t("Open"))
                            ForEach(store.documents) { doc in
                                DocumentRow(
                                    doc: doc,
                                    isActive: doc.id == store.activeID
                                )
                            }
                        }
                    }

                    if !store.recents.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: L10n.t("Recent"))
                            ForEach(store.recents.prefix(6)) { recent in
                                RecentRow(recent: recent)
                            }
                        }
                    }

                    if store.documents.isEmpty, store.recents.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.t("Nothing open"))
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(Theme.secondary)
                            Text(L10n.t("Open a Markdown, JSON, SQL, text, or code file to begin."))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)

            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)

            VStack(spacing: 2) {
                SidebarAction(title: L10n.t("Open File…"), symbol: "folder", shortcut: "⌘O") {
                    store.presentOpenPanel()
                }
                SidebarAction(title: L10n.t("New Document"), symbol: "square.and.pencil", shortcut: "⌘N") {
                    store.newDocument()
                }
            }
            .padding(8)
        }
        .frame(width: 248)
        .background(Theme.sidebar)
    }
}

private struct DocumentRow: View {
    @EnvironmentObject private var store: DocumentStore
    @ObservedObject var doc: EditorDocument
    let isActive: Bool

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 9) {
            KindGlyph(kind: doc.kind, size: 22)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(doc.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if doc.isDirty, !hovering {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 5, height: 5)
                    }
                }
                Text(doc.url?.deletingLastPathComponent().lastPathComponent ?? L10n.t("Unsaved"))
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 2)

            if hovering {
                Button {
                    store.close(doc)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.tertiary)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Theme.hover))
                }
                .buttonStyle(.plain)
                .hoverTip(L10n.t("Close"))
                .accessibilityLabel(L10n.t("Close"))
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? Theme.selection : (hovering ? Theme.hover : .clear))
        )
        .overlay(alignment: .leading) {
            if isActive {
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: 2, height: 16)
                    .offset(x: 0)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { store.activate(doc) }
        .contextMenu {
            Button(L10n.t("Save")) { store.save(doc, as: false) }
            Button(L10n.t("Save As…")) { store.save(doc, as: true) }
            Divider()
            Button(L10n.t("Reveal in Finder")) {
                if let url = doc.url { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            }
            .disabled(doc.url == nil)
            Button(L10n.t("Copy Path")) {
                if let url = doc.url {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.path, forType: .string)
                }
            }
            .disabled(doc.url == nil)
            Divider()
            Button(L10n.t("Close")) { store.close(doc) }
        }
        .help(doc.displayPath)
    }
}

private struct RecentRow: View {
    @EnvironmentObject private var store: DocumentStore
    let recent: RecentFile

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 9) {
            KindGlyph(kind: recent.kind, size: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(recent.name)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text((recent.url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(hovering ? Theme.hover : .clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { store.open(urls: [recent.url]) }
        .contextMenu {
            Button(L10n.t("Open")) { store.open(urls: [recent.url]) }
            Button(L10n.t("Remove from Recents")) { store.removeRecent(path: recent.path) }
        }
    }
}

private struct SidebarAction: View {
    let title: String
    let symbol: String
    let shortcut: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 11.5, weight: .medium))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(shortcut)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.tertiary)
            }
            .foregroundStyle(Theme.secondary)
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hovering ? Theme.hover : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
