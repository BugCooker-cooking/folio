import Foundation

struct RecentFile: Codable, Identifiable, Hashable {
    var path: String
    var name: String
    var kindRaw: String
    var openedAt: Date

    var id: String { path }
    var url: URL { URL(fileURLWithPath: path) }
    var kind: FileKind { FileKind(storageKey: kindRaw) ?? .plain }
}
