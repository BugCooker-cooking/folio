import Foundation

enum FileIOError: LocalizedError {
    case unreadable(String)
    case unsupportedEncoding
    case binaryFile
    case tooLarge(Int)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadable(let message): return message
        case .unsupportedEncoding: return L10n.t("The file uses a text encoding Folio could not decode.")
        case .binaryFile: return L10n.t("This looks like a binary file, not text.")
        case .tooLarge(let bytes):
            let mb = Double(bytes) / 1_048_576
            return L10n.t("The file is %.1f MB. Folio opens text files up to 24 MB.", mb)
        case .writeFailed(let message): return message
        }
    }
}

struct LoadedFile {
    let text: String
    let encoding: String.Encoding
    let lineEnding: LineEnding
    let hadBOM: Bool
}

enum FileIO {
    static let maximumFileSize = 24 * 1024 * 1024

    static func load(url: URL) throws -> LoadedFile {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .isDirectoryKey])
        if values?.isDirectory == true {
            throw FileIOError.unreadable(L10n.t("“%@” is a folder. Open a file instead.", url.lastPathComponent))
        }
        if let size = values?.fileSize, size > maximumFileSize {
            throw FileIOError.tooLarge(size)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url, options: [.mappedIfSafe])
        } catch {
            throw FileIOError.unreadable(error.localizedDescription)
        }

        let (encoding, hadBOM) = detectEncoding(data)
        var decoded: String
        if let value = String(data: data, encoding: encoding) {
            decoded = value
        } else if let latin = String(data: data, encoding: .isoLatin1) {
            return finish(latin, encoding: .isoLatin1, hadBOM: false)
        } else {
            throw FileIOError.unsupportedEncoding
        }

        if decoded.unicodeScalars.contains(where: { $0.value == 0 }) {
            throw FileIOError.binaryFile
        }
        if decoded.hasPrefix("\u{FEFF}") {
            decoded.removeFirst()
        }
        return finish(decoded, encoding: encoding, hadBOM: hadBOM)
    }

    private static func finish(_ text: String, encoding: String.Encoding, hadBOM: Bool) -> LoadedFile {
        let lineEnding = LineEnding.detect(in: text)
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        return LoadedFile(
            text: normalized,
            encoding: encoding,
            lineEnding: lineEnding,
            hadBOM: hadBOM
        )
    }

    private static func detectEncoding(_ data: Data) -> (String.Encoding, Bool) {
        let bytes = [UInt8](data.prefix(4))
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) { return (.utf8, true) }
        if bytes.starts(with: [0xFF, 0xFE]) { return (.utf16LittleEndian, true) }
        if bytes.starts(with: [0xFE, 0xFF]) { return (.utf16BigEndian, true) }
        if String(data: data, encoding: .utf8) != nil { return (.utf8, false) }
        if String(data: data, encoding: .utf16) != nil { return (.utf16, false) }
        return (.isoLatin1, false)
    }

    static func save(
        text: String,
        to url: URL,
        encoding: String.Encoding,
        lineEnding: LineEnding,
        hadBOM: Bool
    ) throws {
        let output = text.replacingOccurrences(of: "\n", with: lineEnding.sequence)
        guard var data = output.data(using: encoding, allowLossyConversion: false) else {
            throw FileIOError.unsupportedEncoding
        }
        if hadBOM {
            if encoding == .utf8 {
                data.insert(contentsOf: [0xEF, 0xBB, 0xBF], at: 0)
            } else if encoding == .utf16LittleEndian {
                data.insert(contentsOf: [0xFF, 0xFE], at: 0)
            } else if encoding == .utf16BigEndian {
                data.insert(contentsOf: [0xFE, 0xFF], at: 0)
            }
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw FileIOError.writeFailed(error.localizedDescription)
        }
    }
}
