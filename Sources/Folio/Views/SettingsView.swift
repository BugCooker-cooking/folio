import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker(selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                } label: {
                    Text(L10n.t("Theme"))
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $settings.showLineNumbers) {
                    Text(L10n.t("Show line numbers"))
                }
                Toggle(isOn: $settings.highlightCurrentLine) {
                    Text(L10n.t("Highlight current line"))
                }
                Toggle(isOn: $settings.highlightSelectionMatches) {
                    Text(L10n.t("Highlight selection matches"))
                }
            } header: {
                Text(L10n.t("Appearance"))
            }

            Section {
                HStack(spacing: 10) {
                    Text(L10n.t("Font size"))
                    Slider(value: $settings.fontSize, in: 10...24, step: 0.5)
                    Text(String(format: "%.1f", settings.fontSize))
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            } header: {
                Text(L10n.t("Text"))
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Folio 1.0")
                        .font(.system(size: 12, weight: .semibold))
                    Text(L10n.t("A lightweight native editor for Markdown, JSON, SQL, code, and plain text."))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 340)
        .preferredColorScheme(settings.appearance.colorScheme)
        .tint(Theme.accent)
    }
}
