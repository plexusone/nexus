import SwiftUI

/// Main content view for a Nexus window
struct ContentView: View {
    @State private var sessionManager = SessionManager()
    @State private var paneManager = PaneManager()
    @State private var stateManager = StateManager()
    @State private var gridConfig = GridConfig(columns: 2, rows: 1)
    @State private var showNewSessionSheet = false
    @State private var showRestorePrompt = false
    @State private var isReady = false

    var body: some View {
        VStack(spacing: 0) {
            if !isReady {
                // Loading state
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Grid layout with panes
                GridLayoutView(
                    config: gridConfig,
                    sessions: sessionManager.sessions,
                    sessionManager: sessionManager,
                    paneManager: paneManager,
                    onRequestNewSession: {
                        showNewSessionSheet = true
                    }
                )
            }

            // Status bar
            if isReady {
                GridStatusBarView(
                    sessions: sessionManager.sessions,
                    paneManager: paneManager,
                    gridConfig: gridConfig,
                    onCreateNew: {
                        showNewSessionSheet = true
                    }
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                // Layout picker
                if isReady {
                    LayoutPickerView(config: $gridConfig)
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if isReady {
                    // New session button
                    Button(action: { showNewSessionSheet = true }) {
                        Image(systemName: "plus")
                    }
                    .help("New Session (⌘N)")

                    // Refresh button
                    Button(action: { Task { await sessionManager.refresh() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Sessions")
                }
            }
        }
        .sheet(isPresented: $showNewSessionSheet) {
            NewSessionSheet(
                sessionManager: sessionManager,
                onSessionCreated: { session in
                    // Attach to first empty pane
                    attachToFirstEmptyPane(session)
                }
            )
        }
        .alert("Restore Previous Session?", isPresented: $showRestorePrompt) {
            Button("Restore") {
                restoreState()
                // Save immediately after restore
                saveState()
            }
            Button("Start Fresh", role: .destructive) {
                stateManager.clearState()
                // Save the fresh state
                saveState()
            }
        } message: {
            if let timeAgo = stateManager.savedAtDescription(),
               let state = stateManager.savedState {
                let attachmentCount = state.paneAttachments.count
                Text("Found a saved session from \(timeAgo) with \(state.gridColumns)×\(state.gridRows) layout and \(attachmentCount) attached pane(s).")
            } else {
                Text("Would you like to restore your previous session?")
            }
        }
        .task {
            await initialize()
        }
        .onChange(of: gridConfig) { _, newConfig in
            saveState()
        }
        .onChange(of: paneManager.attachedSessions) { _, _ in
            saveState()
        }
    }

    private func initialize() async {
        // Small delay to let the window appear
        try? await Task.sleep(for: .milliseconds(100))

        // Check tmux availability
        let tmuxAvailable = await sessionManager.checkTmuxAvailable()
        if !tmuxAvailable {
            print("Warning: tmux is not installed")
        }

        // Initial refresh
        await sessionManager.refresh()

        // Start monitoring
        sessionManager.startMonitoring()

        // Mark as ready
        isReady = true

        // Check for saved state after sessions are loaded
        if stateManager.hasSavedState {
            showRestorePrompt = true
        } else {
            // No saved state - save the initial state
            saveState()
        }
    }

    private func restoreState() {
        guard let state = stateManager.savedState else { return }

        // Restore grid config
        gridConfig = state.gridConfig

        // Restore pane attachments
        for (paneIdStr, tmuxSessionName) in state.paneAttachments {
            guard let paneId = Int(paneIdStr) else { continue }

            // Find the session by tmux session name
            if let session = sessionManager.sessions.first(where: { $0.tmuxSession == tmuxSessionName }) {
                paneManager.attach(session: session, to: paneId)
            }
        }
    }

    private func saveState() {
        guard isReady else { return }
        stateManager.saveState(gridConfig: gridConfig, paneManager: paneManager)
    }

    private func attachToFirstEmptyPane(_ session: NexusSession) {
        // Find first empty pane and attach
        for paneId in 1...gridConfig.paneCount {
            if paneManager.session(for: paneId) == nil {
                paneManager.attach(session: session, to: paneId)
                return
            }
        }
        // If all panes are full, attach to pane 1
        paneManager.attach(session: session, to: 1)
    }
}

/// Status bar adapted for grid layout
struct GridStatusBarView: View {
    let sessions: [NexusSession]
    let paneManager: PaneManager
    let gridConfig: GridConfig
    let onCreateNew: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Pane indicators
            HStack(spacing: 8) {
                ForEach(1...gridConfig.paneCount, id: \.self) { paneId in
                    if let session = paneManager.session(for: paneId) {
                        HStack(spacing: 4) {
                            Text("#\(paneId)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            StatusIndicatorView(status: session.status)
                            Text(session.name)
                                .font(.system(size: 10))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                    } else {
                        HStack(spacing: 4) {
                            Text("#\(paneId)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text("empty")
                                .font(.system(size: 10))
                                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Session count
            Text("\(sessions.count) sessions")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.trailing, 8)

            // New session button
            Button(action: onCreateNew) {
                Image(systemName: "plus")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .frame(height: 24)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(nsColor: .separatorColor)),
            alignment: .top
        )
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 600)
}
