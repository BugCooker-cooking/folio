import AppKit
import SwiftUI

extension View {
    /// Shows a small styled tooltip after a short hover. Used for icon-only
    /// controls so their purpose is always discoverable.
    func hoverTip(_ text: String) -> some View {
        modifier(HoverTipModifier(text: text))
    }
}

private struct HoverTipModifier: ViewModifier {
    let text: String
    @State private var work: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                work?.cancel()
                if hovering {
                    let item = DispatchWorkItem {
                        TooltipPanel.shared.show(text: text)
                    }
                    work = item
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: item)
                } else {
                    TooltipPanel.shared.hide()
                }
            }
            .onDisappear {
                work?.cancel()
                TooltipPanel.shared.hide()
            }
    }
}

private struct TooltipContent: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.chrome)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: 1)
            }
            .fixedSize()
    }
}

/// A borderless, non-activating panel so tips can extend beyond toolbars and
/// scroll views without being clipped.
final class TooltipPanel {
    static let shared = TooltipPanel()

    private let panel: NSPanel
    private var autoHide: DispatchWorkItem?
    private var currentText = ""

    private init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.animationBehavior = .none

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hide()
        }

        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.hide()
            return event
        }
    }

    func show(text: String) {
        guard !text.isEmpty else { return }
        autoHide?.cancel()
        panel.appearance = NSApp.keyWindow?.effectiveAppearance ?? NSApp.effectiveAppearance

        let size = installContent(text)
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        var origin = NSPoint(x: mouse.x + 12, y: mouse.y - size.height - 16)
        if let visible = screen?.visibleFrame {
            if origin.y < visible.minY + 6 {
                origin.y = mouse.y + 18
            }
            origin.x = min(max(origin.x, visible.minX + 6), visible.maxX - size.width - 6)
            origin.y = min(max(origin.y, visible.minY + 6), visible.maxY - size.height - 6)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.orderFrontRegardless()

        let work = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        autoHide = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5, execute: work)
    }

    func hide() {
        autoHide?.cancel()
        autoHide = nil
        panel.orderOut(nil)
        currentText = ""
    }

    private func installContent(_ text: String) -> NSSize {
        let font = NSFont.systemFont(ofSize: 11, weight: .medium)
        let textSize = (text as NSString).size(withAttributes: [.font: font])
        let width = max(1, min(420, ceil(textSize.width) + 20))
        let height = max(1, ceil(textSize.height) + 14)

        let hosting: NSHostingView<TooltipContent>
        if currentText == text, let existing = panel.contentView as? NSHostingView<TooltipContent> {
            hosting = existing
        } else {
            hosting = NSHostingView(rootView: TooltipContent(text: text))
            panel.contentView = hosting
            currentText = text
        }

        panel.setContentSize(NSSize(width: width, height: height))
        hosting.frame = NSRect(x: 0, y: 0, width: width, height: height)
        return NSSize(width: width, height: height)
    }
}
