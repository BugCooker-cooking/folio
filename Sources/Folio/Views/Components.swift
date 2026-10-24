import SwiftUI

struct ToolButton: View {
    let systemName: String
    var isActive: Bool = false
    var help: String = ""
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? Theme.accent : (hovering ? Theme.ink : Theme.secondary))
                .frame(width: 28, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isActive ? Theme.accent.opacity(0.14) : (hovering ? Theme.hover : .clear))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .hoverTip(help)
        .accessibilityLabel(help.isEmpty ? systemName : help)
    }
}

struct KindGlyph: View {
    let kind: FileKind
    var size: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(kind.tint.opacity(0.14))
            .overlay {
                Image(systemName: kind.symbolName)
                    .font(.system(size: size * 0.47, weight: .medium))
                    .foregroundStyle(kind.tint)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct BrandMark: View {
    var size: CGFloat = 68

    private let terracotta = Color(red: 0.76, green: 0.40, blue: 0.25)
    private let terracottaDark = Color(red: 0.56, green: 0.24, blue: 0.17)
    private let paper = Color(red: 0.973, green: 0.949, blue: 0.902)
    private let foldPaper = Color(red: 0.902, green: 0.851, blue: 0.765)
    private let ink = Color(red: 0.165, green: 0.153, blue: 0.133)

    var body: some View {
        let pageWidth = size * 0.39
        let pageHeight = size * 0.47
        let pageRadius = pageWidth * 0.118
        let fold = size * 0.086

        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.169, green: 0.153, blue: 0.129),
                            Color(red: 0.078, green: 0.075, blue: 0.067)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RadialGradient(
                        colors: [terracotta.opacity(0.19), .clear],
                        center: UnitPoint(x: 0.32, y: 0.25),
                        startRadius: 0,
                        endRadius: size * 0.76
                    )
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
                }

            ZStack {
                RoundedRectangle(cornerRadius: pageRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [terracotta, terracottaDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(x: size * 0.026, y: -size * 0.026)
                    .shadow(color: .black.opacity(0.32), radius: size * 0.025, y: size * 0.012)

                FoldedPageShape(fold: fold, cornerRadius: pageRadius)
                    .fill(paper, style: FillStyle(eoFill: true))
                    .frame(width: pageWidth, height: pageHeight)
                    .overlay(alignment: .topTrailing) {
                        FoldTriangle()
                            .fill(foldPaper)
                            .frame(width: fold, height: fold)
                    }
                    .overlay(alignment: .topLeading) {
                        pageLines
                    }
                    .offset(x: -size * 0.006, y: size * 0.006)
                    .shadow(color: .black.opacity(0.38), radius: size * 0.022, y: size * 0.012)
            }

            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .strokeBorder(Color.white.opacity(0.09), lineWidth: max(1, size * 0.002))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: size * 0.1, y: size * 0.04)
        .accessibilityHidden(true)
    }

    private var pageLines: some View {
        HStack(alignment: .top, spacing: size * 0.018) {
            RoundedRectangle(cornerRadius: size * 0.005, style: .continuous)
                .fill(terracotta)
                .frame(width: size * 0.009, height: size * 0.27)

            VStack(alignment: .leading, spacing: size * 0.024) {
                pageLine(width: 0.21)
                pageLine(width: 0.165)
                pageLine(width: 0.19)
                pageLine(width: 0.125)
            }
        }
        .padding(.leading, size * 0.045)
        .padding(.top, size * 0.075)
    }

    private func pageLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.006, style: .continuous)
            .fill(ink.opacity(0.72))
            .frame(width: size * width, height: size * 0.011)
    }
}

private struct FoldedPageShape: Shape {
    let fold: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
        var cut = Path()
        cut.move(to: CGPoint(x: rect.maxX - fold, y: rect.minY))
        cut.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        cut.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
        cut.closeSubpath()
        path.addPath(cut)
        return path
    }
}

private struct FoldTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Theme.tertiary)
            .padding(.horizontal, 8)
    }
}

struct PrimaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 32)
            .foregroundStyle(Theme.paper)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.accent)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .frame(height: 32)
            .foregroundStyle(Theme.ink)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.paper)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}

struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window { configure(window) }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window { configure(window) }
    }
}
