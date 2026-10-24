import AppKit

final class CodeTextView: NSTextView {
    var highlightsCurrentLine = true {
        didSet { needsDisplay = true }
    }

    private func droppedFileURLs(_ info: NSDraggingInfo) -> [URL] {
        let objects = info.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [NSURL] ?? []
        return objects.map { $0 as URL }.filter(\.isFileURL)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if !droppedFileURLs(sender).isEmpty { return .copy }
        return super.draggingEntered(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if !droppedFileURLs(sender).isEmpty { return .copy }
        return super.draggingUpdated(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = droppedFileURLs(sender)
        if !urls.isEmpty {
            DispatchQueue.main.async {
                DocumentStore.shared.open(urls: urls)
            }
            return true
        }
        return super.performDragOperation(sender)
    }

    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)
        guard highlightsCurrentLine, window?.firstResponder === self else { return }
        guard let layoutManager, let textContainer else { return }

        let ns = string as NSString
        let location = min(selectedRange().location, ns.length)
        let lineRange = ns.lineRange(for: NSRange(location: location, length: 0))

        var rect: NSRect
        if lineRange.length > 0 {
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        } else {
            rect = layoutManager.extraLineFragmentRect
        }
        rect.origin.y += textContainerOrigin.y
        if rect.height < 1 {
            rect.size.height = font?.pointSize ?? 13
        }
        let highlight = NSRect(
            x: 0,
            y: rect.minY - 2,
            width: bounds.width,
            height: rect.height + 4
        )
        EditorTheme.currentLine.setFill()
        highlight.fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}

final class GutterView: NSView {
    weak var textView: NSTextView?
    var lineStarts: [Int] = [0]
    var currentLine: Int = 0
    var fontSize: CGFloat = 13.5

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let clip = dirtyRect.intersection(bounds)
        EditorTheme.gutter.setFill()
        clip.fill()

        EditorTheme.gutterSeparator.setFill()
        NSRect(x: bounds.width - 1, y: 0, width: 1, height: bounds.height).fill()

        guard let textView, let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else {
            return
        }

        let numberFont = NSFont.monospacedDigitSystemFont(
            ofSize: max(9, fontSize * 0.72),
            weight: .regular
        )
        let visible = textView.visibleRect
        let origin = textView.textContainerOrigin
        let ns = textView.string as NSString

        if ns.length == 0 {
            drawNumber(1, y: origin.y - visible.minY + 2, height: numberFont.pointSize, font: numberFont, isCurrent: currentLine == 0)
            return
        }

        let glyphRange = layoutManager.glyphRange(forBoundingRect: visible, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        var line = lineIndex(at: characterRange.location)
        if line > 0 { line -= 1 }

        while line < lineStarts.count {
            let start = lineStarts[line]
            if start >= ns.length {
                let used = layoutManager.usedRect(for: textContainer)
                let y = used.maxY + origin.y - visible.minY
                if y >= -fontSize, y <= bounds.height + fontSize {
                    drawNumber(line + 1, y: y, height: max(numberFont.pointSize, 1), font: numberFont, isCurrent: line == currentLine)
                }
                break
            }

            let glyph = layoutManager.glyphIndexForCharacter(at: start)
            let rect = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            let y = rect.minY + origin.y - visible.minY
            if y > bounds.height + fontSize { break }
            if y + rect.height >= -fontSize {
                drawNumber(
                    line + 1,
                    y: y + max(0, (rect.height - numberFont.pointSize) / 2),
                    height: numberFont.pointSize,
                    font: numberFont,
                    isCurrent: line == currentLine
                )
            }
            line += 1
        }
    }

    private func drawNumber(_ number: Int, y: CGFloat, height: CGFloat, font: NSFont, isCurrent: Bool) {
        let color = isCurrent ? EditorTheme.gutterActive : EditorTheme.tertiaryInk
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let label = "\(number)" as NSString
        let size = label.size(withAttributes: attributes)
        let point = NSPoint(
            x: bounds.width - 12 - size.width,
            y: y + max(0, (height - size.height) / 2)
        )
        label.draw(at: point, withAttributes: attributes)
    }

    private func lineIndex(at location: Int) -> Int {
        guard !lineStarts.isEmpty else { return 0 }
        var low = 0
        var high = lineStarts.count - 1
        var result = 0
        while low <= high {
            let mid = (low + high) / 2
            if lineStarts[mid] <= location {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    override func scrollWheel(with event: NSEvent) {
        textView?.enclosingScrollView?.scrollWheel(with: event)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}

final class EditorContainerView: NSView {
    let gutter = GutterView()
    let scrollView = NSScrollView()
    let textView = CodeTextView()
    var gutterWidth: CGFloat = 50 {
        didSet { needsLayout = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = EditorTheme.paper
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.contentView.postsBoundsChangedNotifications = true

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 22, height: 18)
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = false
        textView.usesFontPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.insertionPointColor = EditorTheme.accent

        gutter.wantsLayer = true
        gutter.layer?.masksToBounds = true
        addSubview(gutter)
        addSubview(scrollView)
        scrollView.documentView = textView
        gutter.textView = textView
    }

    override func layout() {
        super.layout()
        let width = gutter.isHidden ? 0 : gutterWidth
        gutter.frame = NSRect(x: 0, y: 0, width: width, height: bounds.height)
        scrollView.frame = NSRect(x: width, y: 0, width: max(0, bounds.width - width), height: bounds.height)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        scrollView.backgroundColor = EditorTheme.paper
        guttersInvalidate()
    }

    func guttersInvalidate() {
        gutter.needsDisplay = true
        textView.needsDisplay = true
        needsDisplay = true
    }
}
