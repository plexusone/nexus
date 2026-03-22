import AppKit
import SwiftTerm

/// Controller that manages a SwiftTerm terminal view and its connection to a tmux session
class TerminalViewController: NSViewController {
    private(set) var terminalView: LocalProcessTerminalView!
    private(set) var attachedSession: NexusSession?
    private(set) var isAttached: Bool = false

    var onSessionEnded: (() -> Void)?
    var onTitleChanged: ((String) -> Void)?

    override func loadView() {
        terminalView = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.processDelegate = self

        // Configure terminal appearance
        configureAppearance()

        view = terminalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Public API

    /// Attach to a tmux session
    func attach(to session: NexusSession) {
        // Detach from current session if any
        if isAttached {
            detach()
        }

        attachedSession = session
        isAttached = true

        // Find tmux path and build args
        let (tmuxPath, baseArgs) = findTmuxExecutable()
        let args = baseArgs + ["attach", "-t", session.tmuxSession]

        // Set environment variables
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        if env["LANG"] == nil {
            env["LANG"] = "en_US.UTF-8"
        }

        // Convert environment to array format: ["KEY=VALUE", ...]
        let envArray = env.map { "\($0.key)=\($0.value)" }

        terminalView.startProcess(
            executable: tmuxPath,
            args: args,
            environment: envArray,
            execName: "tmux"
        )
    }

    /// Detach from the current session
    func detach() {
        guard isAttached else { return }

        // Send tmux detach key sequence (prefix + d)
        // Default prefix is Ctrl-B
        // For now, we'll just terminate the process
        // which will leave the tmux session running

        isAttached = false
        attachedSession = nil

        // Notify that we've detached
        onSessionEnded?()
    }

    /// Create a new session and attach to it
    func createAndAttach(name: String, command: String? = nil, sessionManager: SessionManager) async throws {
        let session = try await sessionManager.createSession(name: name, command: command)
        attach(to: session)
    }

    /// Send text to the terminal
    func send(_ text: String) {
        terminalView.send(txt: text)
    }

    /// Send a special key to the terminal
    func sendKey(_ key: UInt8) {
        terminalView.send([key])
    }

    // MARK: - Private Methods

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

    private func configureAppearance() {
        // Use system monospace font
        let fontSize: CGFloat = 13
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        terminalView.font = font

        // Configure colors (can be customized later)
        terminalView.nativeBackgroundColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        terminalView.nativeForegroundColor = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

        // Cursor style
        terminalView.caretColor = NSColor.white

        // Configure scrollback buffer (default is only 500 lines)
        // AI agent output can be lengthy, so use 10,000 lines
        terminalView.changeScrollback(10000)
    }
}

// MARK: - LocalProcessTerminalViewDelegate

extension TerminalViewController: LocalProcessTerminalViewDelegate {
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        DispatchQueue.main.async { [weak self] in
            self?.isAttached = false
            self?.attachedSession = nil
            self?.onSessionEnded?()
        }
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        // Terminal size changed, tmux will handle this via SIGWINCH
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onTitleChanged?(title)
        }
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
