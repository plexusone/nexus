import XCTest
@testable import PlexusOneDesktop

final class SessionManagerTests: XCTestCase {

    func testSessionStatusDisplayName() {
        XCTAssertEqual(SessionStatus.running.displayName, "Running")
        XCTAssertEqual(SessionStatus.idle.displayName, "Idle")
        XCTAssertEqual(SessionStatus.stuck.displayName, "Stuck")
        XCTAssertEqual(SessionStatus.detached.displayName, "Detached")
    }

    func testSessionInitialization() {
        let session = Session(name: "test-session")

        XCTAssertEqual(session.name, "test-session")
        XCTAssertEqual(session.tmuxSession, "test-session")
        XCTAssertEqual(session.status, .detached)
        XCTAssertNil(session.agentType)
    }

    func testSessionWithCustomTmuxSession() {
        let session = Session(
            name: "My Session",
            tmuxSession: "my-tmux-session",
            agentType: .claude
        )

        XCTAssertEqual(session.name, "My Session")
        XCTAssertEqual(session.tmuxSession, "my-tmux-session")
        XCTAssertEqual(session.agentType, .claude)
    }

    func testAgentTypeDisplayNames() {
        XCTAssertEqual(AgentType.claude.displayName, "Claude")
        XCTAssertEqual(AgentType.codex.displayName, "Codex")
        XCTAssertEqual(AgentType.gemini.displayName, "Gemini")
        XCTAssertEqual(AgentType.kiro.displayName, "Kiro")
        XCTAssertEqual(AgentType.custom.displayName, "Custom")
    }
}
