import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return L10n.t("System")
        case .light: return L10n.t("Light")
        case .dark: return L10n.t("Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    @Published var showLineNumbers: Bool {
        didSet { defaults.set(showLineNumbers, forKey: Keys.lineNumbers) }
    }
    @Published var highlightCurrentLine: Bool {
        didSet { defaults.set(highlightCurrentLine, forKey: Keys.currentLine) }
    }
    @Published var highlightSelectionMatches: Bool {
        didSet { defaults.set(highlightSelectionMatches, forKey: Keys.selectionMatches) }
    }
    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let appearance = "folio.appearance"
        static let lineNumbers = "folio.lineNumbers"
        static let currentLine = "folio.highlightCurrentLine"
        static let selectionMatches = "folio.highlightSelectionMatches"
        static let fontSize = "folio.fontSize"
    }

    private init() {
        let storedAppearance = defaults.string(forKey: Keys.appearance)
        appearance = AppearanceMode(rawValue: storedAppearance ?? "") ?? .system
        showLineNumbers = defaults.object(forKey: Keys.lineNumbers) as? Bool ?? true
        highlightCurrentLine = defaults.object(forKey: Keys.currentLine) as? Bool ?? true
        highlightSelectionMatches = defaults.object(forKey: Keys.selectionMatches) as? Bool ?? true
        let storedSize = defaults.double(forKey: Keys.fontSize)
        fontSize = min(24, max(10, storedSize > 0 ? storedSize : 13.5))
    }
}
