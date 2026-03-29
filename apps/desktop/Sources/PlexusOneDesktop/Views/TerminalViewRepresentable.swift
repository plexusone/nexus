import SwiftUI
import AppKit
import SwiftTerm

/// Container view that hosts AppTerminalView and forwards scroll events
class TerminalContainerView: NSView {
    let terminalView: AppTerminalView

    init(terminalView: AppTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)

        addSubview(terminalView)
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            terminalView.topAnchor.constraint(equalTo: topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        // Forward scroll events to SwiftTerm's handler
        terminalView.scrollWheel(with: event)
    }

    override func becomeFirstResponder() -> Bool {
        // Forward first responder to terminal
        return terminalView.becomeFirstResponder()
    }
}

/// SwiftUI wrapper for AppTerminalView using NSViewRepresentable
/// This approach follows SwiftTerm's own iOS SwiftUI implementation pattern
struct AppTerminalViewRepresentable: NSViewRepresentable {
    typealias NSViewType = TerminalContainerView

    @Binding var attachedSession: Session?
    let sessionManager: SessionManager
    var onSessionEnded: (() -> Void)?

    func makeNSView(context: Context) -> TerminalContainerView {
        let terminalView = AppTerminalView(frame: .zero)
        terminalView.processDelegate = context.coordinator
        context.coordinator.terminalView = terminalView

        // Configure appearance
        configureAppearance(terminalView)

        // Add local event monitor for scroll wheel events (trackpad two-finger scroll)
        context.coordinator.scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
            context.coordinator.handleScrollEvent(event)
            return event
        }

        let container = TerminalContainerView(terminalView: terminalView)
        return container
    }

    func updateNSView(_ container: TerminalContainerView, context: Context) {
        let view = container.terminalView

        // Ensure layout is current
        view.updateSizeIfNeeded()

        // Handle session attachment changes
        if let session = attachedSession {
            // Attach if not already attached to this session
            if view.attachedSessionId() != session.id {
                view.attach(to: session)
            }
        } else if view.isSessionAttached {
            view.detach()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func configureAppearance(_ view: AppTerminalView) {
        // Use system monospace font
        let fontSize: CGFloat = 13
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        view.font = font

        // Configure colors
        view.nativeBackgroundColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        view.nativeForegroundColor = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

        // Cursor style
        view.caretColor = NSColor.white

        // Configure scrollback buffer (default is only 500 lines)
        // AI agent output can be lengthy, so use 10,000 lines
        view.changeScrollback(10000)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var parent: AppTerminalViewRepresentable
        weak var terminalView: AppTerminalView?
        var scrollMonitor: Any?

        init(_ parent: AppTerminalViewRepresentable) {
            self.parent = parent
        }

        deinit {
            if let monitor = scrollMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        func handleScrollEvent(_ event: NSEvent) {
            guard let terminalView = terminalView else { return }

            // Check if the event is within the terminal view's bounds
            guard terminalView.window != nil else { return }
            let locationInWindow = event.locationInWindow
            let locationInView = terminalView.convert(locationInWindow, from: nil)

            guard terminalView.bounds.contains(locationInView) else { return }

            // First try to send mouse wheel events to the terminal app (e.g., tmux)
            // If mouse reporting is not enabled, fall back to native scrollback
            if !terminalView.handleMouseWheelEvent(event) {
                terminalView.scrollWheel(with: event)
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.onSessionEnded?()
            }
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            // Terminal size changed - tmux handles via SIGWINCH
        }

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            // Could propagate title changes if needed
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            // Could be used to update UI with current directory
        }

        func requestOpenLink(source: LocalProcessTerminalView, link: String, params: [String: String]) {
            // Handle link clicks (e.g., URLs in terminal output)
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
