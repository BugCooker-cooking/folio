import SwiftUI

struct FindBar: View {
    @ObservedObject var controller: EditorController
    @Binding var isPresented: Bool

    @State private var query = ""
    @State private var replacement = ""
    @State private var caseSensitive = false
    @State private var regularExpression = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case find
        case replace
    }

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.tertiary)

                TextField(L10n.t("Find"), text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .focused($focusedField, equals: .find)
                    .onSubmit { controller.findNext() }
                    .onChange(of: query) { _, _ in updateSearch() }

                Text(resultLabel)
                    .font(.system(size: 10.5).monospacedDigit())
                    .foregroundStyle(controller.searchError == nil ? Theme.tertiary : Theme.error)
                    .lineLimit(1)
                    .frame(minWidth: 54, alignment: .trailing)

                optionButton("Aa", active: $caseSensitive)
                optionButton(".*", active: $regularExpression)

                ToolButton(systemName: "chevron.up", help: L10n.t("Previous Match (⇧⌘G)")) {
                    controller.findPrevious()
                }
                ToolButton(systemName: "chevron.down", help: L10n.t("Next Match (⌘G)")) {
                    controller.findNext()
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.tertiary)

                TextField(L10n.t("Replace"), text: $replacement)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .focused($focusedField, equals: .replace)
                    .onSubmit { controller.replaceCurrent(with: replacement) }

                Button(L10n.t("Replace")) {
                    controller.replaceCurrent(with: replacement)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .padding(.horizontal, 7)
                .frame(height: 22)
                .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover))

                Button(L10n.t("All")) {
                    controller.replaceAll(with: replacement)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .padding(.horizontal, 7)
                .frame(height: 22)
                .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover))

                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(Theme.tertiary)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Theme.hover))
                }
                .buttonStyle(.plain)
                .hoverTip(L10n.t("Close Find"))
                .accessibilityLabel(L10n.t("Close Find"))
            }

            if let error = controller.searchError {
                HStack {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.error)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.chrome)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 18, y: 7)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                focusedField = .find
            }
        }
        .onExitCommand {
            close()
        }
    }

    private var resultLabel: String {
        if controller.searchError != nil { return L10n.t("Invalid") }
        if query.isEmpty { return "" }
        if controller.matchCount == 0 { return L10n.t("None") }
        return "\(controller.currentMatchIndex + 1)/\(controller.matchCount)"
    }

    private func optionButton(_ label: String, active: Binding<Bool>) -> some View {
        Button {
            active.wrappedValue.toggle()
            updateSearch()
        } label: {
            Text(label)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(active.wrappedValue ? Theme.accent : Theme.tertiary)
                .frame(width: 24, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(active.wrappedValue ? Theme.accent.opacity(0.13) : Theme.hover)
                )
        }
        .buttonStyle(.plain)
        .hoverTip(label == "Aa" ? L10n.t("Match Case") : L10n.t("Regular Expression"))
        .accessibilityLabel(label == "Aa" ? L10n.t("Match Case") : L10n.t("Regular Expression"))
    }

    private func updateSearch() {
        if query.isEmpty {
            controller.clear()
        } else {
            controller.find(
                query,
                options: FindOptions(
                    caseSensitive: caseSensitive,
                    regularExpression: regularExpression
                )
            )
        }
    }

    private func close() {
        controller.clear()
        isPresented = false
        DispatchQueue.main.async {
            controller.focusEditor()
        }
    }
}
