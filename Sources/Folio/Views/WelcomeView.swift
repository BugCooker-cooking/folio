import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        ZStack {
            Theme.paper
            RadialGradient(
                colors: [Theme.accent.opacity(0.07), .clear],
                center: .init(x: 0.5, y: 0.28),
                startRadius: 8,
                endRadius: 400
            )
            .allowsHitTesting(false)

            VStack(spacing: 24) {
                Spacer(minLength: 24)

                BrandMark(size: 70)

                VStack(spacing: 7) {
                    Text("Folio")
                        .font(.system(size: 38, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(L10n.t("A quiet place for text, Markdown, JSON, SQL and code."))
                        .font(.system(size: 13.5))
                        .foregroundStyle(Theme.secondary)
                }

                HStack(spacing: 10) {
                    Button {
                        store.presentOpenPanel()
                    } label: {
                        Label(L10n.t("Open a File"), systemImage: "folder")
                    }
                    .buttonStyle(PrimaryActionStyle())

                    Button {
                        store.newDocument()
                    } label: {
                        Label(L10n.t("New Document"), systemImage: "plus")
                    }
                    .buttonStyle(SecondaryActionStyle())
                }

                if !store.recents.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(text: L10n.t("Recent"))
                        ForEach(store.recents.prefix(5)) { recent in
                            WelcomeRecentRow(recent: recent)
                        }
                    }
                    .frame(maxWidth: 430)
                    .padding(.top, 4)
                } else {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 11, weight: .medium))
                        Text(L10n.t("Drop a file anywhere to open it"))
                            .font(.system(size: 11.5))
                    }
                    .foregroundStyle(Theme.tertiary)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
    }
}

private struct WelcomeRecentRow: View {
    @EnvironmentObject private var store: DocumentStore
    let recent: RecentFile

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            KindGlyph(kind: recent.kind, size: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(recent.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text((recent.url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if hovering {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(hovering ? Theme.hover : .clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { store.open(urls: [recent.url]) }
        .contextMenu {
            Button(L10n.t("Remove from Recents")) { store.removeRecent(path: recent.path) }
        }
    }
}
