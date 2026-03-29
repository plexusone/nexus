import Foundation

/// Represents a tmux session that can be attached to a pane
struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let tmuxSession: String
    var agentType: AgentType?
    var status: SessionStatus
    var lastActivity: Date
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        tmuxSession: String? = nil,
        agentType: AgentType? = nil,
        status: SessionStatus = .detached,
        lastActivity: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.tmuxSession = tmuxSession ?? name
        self.agentType = agentType
        self.status = status
        self.lastActivity = lastActivity
        self.metadata = metadata
    }
}

/// Status of a tmux session based on activity
enum SessionStatus: String, Codable, Hashable {
    case running    // Active output within threshold
    case idle       // No recent output
    case stuck      // No output for extended period
    case detached   // No pane attached (still running in tmux)

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .idle: return "Idle"
        case .stuck: return "Stuck"
        case .detached: return "Detached"
        }
    }

    var statusColor: String {
        switch self {
        case .running: return "green"
        case .idle: return "yellow"
        case .stuck: return "red"
        case .detached: return "gray"
        }
    }
}

/// Type of AI agent running in the session
enum AgentType: String, Codable, Hashable, CaseIterable {
    case claude
    case codex
    case gemini
    case kiro
    case custom

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        case .gemini: return "Gemini"
        case .kiro: return "Kiro"
        case .custom: return "Custom"
        }
    }
}
