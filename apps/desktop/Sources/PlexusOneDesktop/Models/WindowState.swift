import Foundation

/// Frame information for window restoration
struct WindowFrame: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

/// Configuration for a single window
struct WindowConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var gridColumns: Int
    var gridRows: Int
    var paneAttachments: [String: String]  // paneId -> tmux session name
    var frame: WindowFrame?

    var gridConfig: GridConfig {
        GridConfig(columns: gridColumns, rows: gridRows)
    }

    init(id: UUID = UUID(), gridConfig: GridConfig = GridConfig(columns: 2, rows: 1), paneAttachments: [String: String] = [:], frame: WindowFrame? = nil) {
        self.id = id
        self.gridColumns = gridConfig.columns
        self.gridRows = gridConfig.rows
        self.paneAttachments = paneAttachments
        self.frame = frame
    }

    mutating func update(gridConfig: GridConfig, paneManager: PaneManager) {
        self.gridColumns = gridConfig.columns
        self.gridRows = gridConfig.rows

        // Convert pane attachments to string keys for JSON compatibility
        var attachments: [String: String] = [:]
        for (paneId, session) in paneManager.attachedSessions {
            attachments[String(paneId)] = session.tmuxSession
        }
        self.paneAttachments = attachments
    }
}

/// Multi-window state for persistence
struct MultiWindowState: Codable {
    var windows: [WindowConfig]
    var savedAt: Date
    var version: Int = 2

    init(windows: [WindowConfig] = []) {
        self.windows = windows
        self.savedAt = Date()
    }
}
