import Foundation

/// Represents the persisted state of Nexus
struct NexusState: Codable {
    /// Grid layout configuration
    var gridColumns: Int
    var gridRows: Int

    /// Pane to tmux session mappings (paneId -> tmux session name)
    var paneAttachments: [String: String]

    /// Timestamp when state was saved
    var savedAt: Date

    /// Version for future compatibility
    var version: Int = 1

    init(gridConfig: GridConfig, paneManager: PaneManager) {
        self.gridColumns = gridConfig.columns
        self.gridRows = gridConfig.rows
        self.savedAt = Date()

        // Convert pane attachments to string keys for JSON compatibility
        var attachments: [String: String] = [:]
        for (paneId, session) in paneManager.attachedSessions {
            attachments[String(paneId)] = session.tmuxSession
        }
        self.paneAttachments = attachments
    }

    var gridConfig: GridConfig {
        GridConfig(columns: gridColumns, rows: gridRows)
    }
}

/// Manages persistence of Nexus state to disk
@Observable
class StateManager {
    private let stateDirectory: URL
    private let stateFileURL: URL

    /// Whether a previous state exists that can be restored
    private(set) var hasSavedState: Bool = false

    /// The loaded state (if any)
    private(set) var savedState: NexusState?

    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.stateDirectory = homeDir.appendingPathComponent(".plexusone")
        self.stateFileURL = stateDirectory.appendingPathComponent("nexus_state.json")

        // Check for existing state
        loadState()
    }

    /// Load state from disk
    func loadState() {
        guard FileManager.default.fileExists(atPath: stateFileURL.path) else {
            hasSavedState = false
            savedState = nil
            return
        }

        do {
            let data = try Data(contentsOf: stateFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            savedState = try decoder.decode(NexusState.self, from: data)
            hasSavedState = true
        } catch {
            print("Failed to load state: \(error)")
            hasSavedState = false
            savedState = nil
        }
    }

    /// Save current state to disk
    func saveState(gridConfig: GridConfig, paneManager: PaneManager) {
        let state = NexusState(gridConfig: gridConfig, paneManager: paneManager)

        do {
            // Ensure directory exists
            try FileManager.default.createDirectory(
                at: stateDirectory,
                withIntermediateDirectories: true
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(state)
            try data.write(to: stateFileURL, options: .atomic)

            savedState = state
            hasSavedState = true
        } catch {
            print("Failed to save state: \(error)")
        }
    }

    /// Delete saved state
    func clearState() {
        do {
            if FileManager.default.fileExists(atPath: stateFileURL.path) {
                try FileManager.default.removeItem(at: stateFileURL)
            }
            hasSavedState = false
            savedState = nil
        } catch {
            print("Failed to clear state: \(error)")
        }
    }

    /// Format the saved timestamp for display
    func savedAtDescription() -> String? {
        guard let state = savedState else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: state.savedAt, relativeTo: Date())
    }
}
