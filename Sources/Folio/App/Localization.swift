import Foundation

enum ResolvedLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"

    var localeIdentifier: String {
        switch self {
        case .english: return "en_US"
        case .simplifiedChinese: return "zh_Hans_CN"
        case .traditionalChinese: return "zh_Hant_TW"
        case .japanese: return "ja_JP"
        case .korean: return "ko_KR"
        case .french: return "fr_FR"
        case .german: return "de_DE"
        }
    }

    static func preferred() -> ResolvedLanguage {
        let languages = UserDefaults.standard.stringArray(forKey: "AppleLanguages")
            ?? Locale.preferredLanguages
        for language in languages {
            if let match = match(language) { return match }
        }
        return .english
    }

    private static func match(_ code: String) -> ResolvedLanguage? {
        let lower = code.lowercased().replacingOccurrences(of: "_", with: "-")
        if lower.hasPrefix("zh") {
            if lower.contains("hant") || lower.contains("tw") || lower.contains("hk") || lower.contains("mo") {
                return .traditionalChinese
            }
            return .simplifiedChinese
        }
        if lower.hasPrefix("ja") { return .japanese }
        if lower.hasPrefix("ko") { return .korean }
        if lower.hasPrefix("fr") { return .french }
        if lower.hasPrefix("de") { return .german }
        if lower.hasPrefix("en") { return .english }
        return nil
    }
}

enum L10n {
    static var language: ResolvedLanguage { ResolvedLanguage.preferred() }

    static func t(_ key: String) -> String {
        guard let table = LocalizationTables.tables[language] else { return key }
        return table[key] ?? key
    }

    static func t(_ key: String, _ arguments: CVarArg...) -> String {
        let format = t(key)
        guard !arguments.isEmpty else { return format }
        return String(
            format: format,
            locale: Locale(identifier: language.localeIdentifier),
            arguments: arguments
        )
    }
}
