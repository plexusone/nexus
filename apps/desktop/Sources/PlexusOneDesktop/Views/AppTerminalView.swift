import AppKit
import SwiftTerm

/// Custom LocalProcessTerminalView subclass for SwiftUI integration
/// Handles explicit size tracking and layout updates following SwiftTerm's iOS pattern
class AppTerminalView: LocalProcessTerminalView {
    private var lastAppliedSize: CGSize = .zero
    private var currentSessionId: UUID?

    override func layout() {
        super.layout()
        updateSizeIfNeeded()
    }

    func updateSizeIfNeeded() {
        let newSize = bounds.size
        guard newSize.width > 0, newSize.height > 0 else { return }
        guard newSize != lastAppliedSize else { return }

        lastAppliedSize = newSize
        // SwiftTerm recalculates terminal dimensions on layout
        // The parent class layout() handles this
    }

    // MARK: - Mouse Wheel Event Handling

    /// Send mouse wheel event to terminal application (e.g., tmux with mouse mode)
    /// Returns true if event was handled, false if should use native scrollback
    func handleMouseWheelEvent(_ event: NSEvent) -> Bool {
        // Check if we should send mouse wheel events to the terminal application
        guard allowMouseReporting && terminal.mouseMode != .off else {
            return false
        }

        // Get cell size from terminal
        guard let cellSize = cellSizeInPixels(source: terminal) else {
            return false
        }

        // Calculate position in terminal grid
        let locationInView = convert(event.locationInWindow, from: nil)
        let col = Int(locationInView.x / CGFloat(cellSize.width))
        let row = Int((bounds.height - locationInView.y) / CGFloat(cellSize.height))

        // Mouse wheel: button 64 = up, 65 = down
        let scrollCount = max(1, Int(abs(event.scrollingDeltaY) / 3))
        let buttonCode = event.scrollingDeltaY > 0 ? 64 : 65

        for _ in 0..<scrollCount {
            terminal.sendEvent(buttonFlags: buttonCode, x: col, y: row)
        }
        return true
    }

    // MARK: - Session Management

    var isSessionAttached: Bool {
        currentSessionId != nil
    }

    func attachedSessionId() -> UUID? {
        currentSessionId
    }

    func attach(to session: Session) {
        currentSessionId = session.id

        let (tmuxPath, baseArgs) = findTmuxExecutable()
        let args = baseArgs + ["attach", "-t", session.tmuxSession]

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        if env["LANG"] == nil {
            env["LANG"] = "en_US.UTF-8"
        }

        let envArray = env.map { "\($0.key)=\($0.value)" }

        startProcess(
            executable: tmuxPath,
            args: args,
            environment: envArray,
            execName: "tmux"
        )
    }

    func detach() {
        currentSessionId = nil
        // The process termination is handled by SwiftTerm
        // tmux session continues running in background
    }

    private func findTmuxExecutable() -> (path: String, baseArgs: [String]) {
        let paths = [
            "/usr/local/bin/tmux",      // Homebrew Intel
            "/opt/homebrew/bin/tmux",   // Homebrew Apple Silicon
            "/usr/bin/tmux"             // System
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return (path, [])
            }
        }

        // Fallback - use env to find tmux in PATH
        return ("/usr/bin/env", ["tmux"])
    }
}
