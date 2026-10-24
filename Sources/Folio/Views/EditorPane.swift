import SwiftUI

struct EditorPane: View {
    @EnvironmentObject private var store: DocumentStore
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var document: EditorDocument

    @StateObject private var controller = EditorController()
    @StateObject private var status = EditorStatus()
    @State private var showFind = false
    @State private var validationWork: DispatchWorkItem?
    @State private var previewText = ""
    @State private var previewWork: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 0) {
            if document.kind == .markdown, document.viewMode != .preview {
                MarkdownToolbar(controller: controller)
            }

            content

            StatusBar(document: document, status: status)
        }
        .background(Theme.paper)
        .onAppear {
            store.activeEditor = controller
            status.reset(for: document.text)
            status.updateText(document.text)
            previewText = document.text
            scheduleValidation(document.text)
        }
        .onDisappear {
            if store.activeEditor === controller {
                store.activeEditor = nil
            }
            previewWork?.cancel()
        }
        .onReceive(store.$findRequestID.dropFirst()) { _ in
            if document.viewMode == .preview {
                document.viewMode = .split
            }
            showFind = true
        }
        .onChange(of: showFind) { _, newValue in
            if !newValue { controller.clear() }
        }
        .onChange(of: document.viewMode) { _, mode in
            previewWork?.cancel()
            previewText = document.text
            if mode == .preview {
                showFind = false
                controller.clear()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    controller.focusEditor()
                }
            }
        }
        .onChange(of: document.kind) { _, _ in
            scheduleValidation(document.text)
        }
    }

    @ViewBuilder
    private var content: some View {
        if document.kind == .markdown {
            switch document.viewMode {
            case .edit:
                editorArea
            case .split:
                HSplitView {
                    editorArea
                        .frame(minWidth: 280)
                    MarkdownPreviewView(text: previewText)
                        .frame(minWidth: 280)
                }
            case .preview:
                ZStack(alignment: .topTrailing) {
                    MarkdownPreviewView(text: previewText)
                    MarkdownEditButton {
                        document.viewMode = .split
                    }
                    .padding(.top, 18)
                    .padding(.trailing, 20)
                }
            }
        } else {
            editorArea
        }
    }

    private var editorArea: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                CodeEditorView(
                    document: document,
                    settings: settings,
                    controller: controller,
                    onTextChange: handleTextChange,
                    onSelectionChange: { range, line, column in
                        status.updateSelection(range: range, line: line, column: column)
                    }
                )

                if showFind {
                    FindBar(controller: controller, isPresented: $showFind)
                        .frame(width: min(430, max(260, geometry.size.width - 32)))
                        .padding(.top, 10)
                        .padding(.trailing, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.18), value: showFind)
        }
    }

    private func handleTextChange(_ text: String) {
        document.text = text
        document.markEdited()
        status.updateText(text)
        scheduleValidation(text)
        schedulePreviewUpdate(text)
        if showFind {
            controller.refreshFind()
        }
    }

    private func schedulePreviewUpdate(_ text: String) {
        guard document.kind == .markdown else { return }
        previewWork?.cancel()
        let work = DispatchWorkItem {
            DispatchQueue.main.async {
                guard document.text == text else { return }
                previewText = text
            }
        }
        previewWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: work)
    }

    private func scheduleValidation(_ text: String) {
        guard document.kind == .json else { return }
        validationWork?.cancel()
        let work = DispatchWorkItem {
            let message = JSONTools.validationError(text)
            DispatchQueue.main.async {
                guard document.text == text else { return }
                document.jsonError = message
            }
        }
        validationWork = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.45, execute: work)
    }
}


private struct MarkdownEditButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 10.5, weight: .semibold))
                Text(L10n.t("Edit"))
                    .font(.system(size: 11.5, weight: .medium))
            }
            .foregroundStyle(Theme.paper)
            .padding(.horizontal, 12)
            .frame(height: 29)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.accent)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: Theme.accent.opacity(0.24), radius: 10, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(hovering ? 0.9 : 1)
        .onHover { hovering = $0 }
        .help(L10n.t("Edit"))
        .accessibilityLabel(L10n.t("Edit"))
    }
}
