import Combine
import Foundation

final class EditorStatus: ObservableObject {
    @Published var line = 1
    @Published var column = 1
    @Published var selectionLength = 0
    @Published var characterCount = 0
    @Published var wordCount = 0

    private var statsWork: DispatchWorkItem?

    func updateSelection(range: NSRange, line: Int, column: Int) {
        self.line = line
        self.column = column
        selectionLength = range.length
    }

    func updateText(_ text: String) {
        characterCount = (text as NSString).length
        statsWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            let words = Self.wordCount(in: text)
            DispatchQueue.main.async {
                self?.wordCount = words
            }
        }
        statsWork = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    func reset(for text: String) {
        characterCount = (text as NSString).length
        wordCount = 0
        selectionLength = 0
    }

    private static func wordCount(in text: String) -> Int {
        var count = 0
        text.enumerateSubstrings(
            in: text.startIndex..<text.endIndex,
            options: [.byWords, .substringNotRequired]
        ) { _, _, _, _ in
            count += 1
        }
        return count
    }
}
