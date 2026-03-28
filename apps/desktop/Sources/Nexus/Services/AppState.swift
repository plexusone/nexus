import Foundation
import Observation

/// Shared application state singleton for multi-window support
@Observable
final class AppState {
    /// Shared singleton instance
    static let shared = AppState()

    /// Session manager shared across all windows
    let sessionManager: SessionManager

    /// Window state manager for persistence
    let windowStateManager: WindowStateManager

    /// Whether the app has completed initial setup
    private(set) var isInitialized = false

    private init() {
        self.sessionManager = SessionManager()
        self.windowStateManager = WindowStateManager()
    }

    /// Start monitoring sessions (call once at app launch)
    func startMonitoring() async {
        guard !isInitialized else { return }

        // Check tmux availability
        let tmuxAvailable = await sessionManager.checkTmuxAvailable()
        if !tmuxAvailable {
            print("Warning: tmux is not installed")
        }

        // Initial refresh
        await sessionManager.refresh()

        // Start periodic monitoring
        sessionManager.startMonitoring()

        isInitialized = true
    }
}
