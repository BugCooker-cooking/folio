import AppKit
import ObjectiveC

/// A single-window app should quit when its close button is pressed, but only
/// after unsaved work has been confirmed. Taking over the close button avoids
/// AppKit's close-then-terminate path, which can leave a windowless app when
/// the user cancels the quit.
final class WindowCloseHandler: NSObject {
    private static var associationKey: UInt8 = 0

    static func install(on window: NSWindow) {
        guard objc_getAssociatedObject(window, &associationKey) == nil else { return }
        let handler = WindowCloseHandler()
        objc_setAssociatedObject(window, &associationKey, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if let button = window.standardWindowButton(.closeButton) {
            button.target = handler
            button.action = #selector(closeTapped)
        }
    }

    @objc private func closeTapped() {
        let store = DocumentStore.shared
        guard store.confirmTermination() else { return }
        store.bypassTerminationPrompt = true
        NSApp.terminate(nil)
    }
}
