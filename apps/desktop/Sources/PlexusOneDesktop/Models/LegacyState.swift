import Foundation

/// Legacy v1 state format (single-window)
/// Kept for migration purposes - new state uses MultiWindowState
struct LegacyState: Codable {
    /// Grid layout configuration
    var gridColumns: Int
    var gridRows: Int

    /// Pane to tmux session mappings (paneId -> tmux session name)
    var paneAttachments: [String: String]

    /// Timestamp when state was saved
    var savedAt: Date

    /// Version for future compatibility
    var version: Int = 1

    var gridConfig: GridConfig {
        GridConfig(columns: gridColumns, rows: gridRows)
    }
}
