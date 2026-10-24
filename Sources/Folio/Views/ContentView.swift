import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: DocumentStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar()

            ZStack {
                HStack(spacing: 0) {
                    if store.isSidebarVisible {
                        SidebarView()
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        Rectangle()
                            .fill(Theme.separator)
                            .frame(width: 1)
                    }

                    if let doc = store.activeDocument {
                        EditorPane(document: doc)
                            .id(doc.id)
                    } else {
                        WelcomeView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isDropTargeted {
                    DropOverlay()
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: store.isSidebarVisible)
            .animation(.easeOut(duration: 0.14), value: isDropTargeted)
        }
        .background(Theme.paper)
        .frame(minWidth: 900, minHeight: 560)
        .preferredColorScheme(settings.appearance.colorScheme)
        .tint(Theme.accent)
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        .background(
            WindowAccessor { window in
                window.title = "Folio"
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = false
                window.backgroundColor = EditorTheme.paper
                window.minSize = NSSize(width: 900, height: 560)
                WindowCloseHandler.install(on: window)
            }
        )
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                var url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let directURL = item as? URL {
                    url = directURL
                } else if let nsURL = item as? NSURL {
                    url = nsURL as URL
                }
                if let url {
                    DispatchQueue.main.async {
                        store.open(urls: [url])
                    }
                }
            }
        }
        return true
    }
}

private struct DropOverlay: View {
    var body: some View {
        ZStack {
            Theme.paper.opacity(0.86)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    Theme.accent,
                    style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                )
                .padding(18)

            VStack(spacing: 10) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Theme.accent)
                Text(L10n.t("Drop to open"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text(L10n.t("Markdown · JSON · SQL · Code · Text"))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.tertiary)
            }
        }
        .allowsHitTesting(false)
    }
}
