# CLAUDE.md

Project context for Claude Code sessions.

## Project Overview

**PlexusOne Apps** is a multi-agent orchestration platform for AI CLI tools (Claude Code, Kiro CLI, etc.). It provides a unified interface to monitor and control multiple AI agents running in tmux sessions.

## Repository Structure

```
plexusone-apps/
├── apps/
│   ├── desktop/              # PlexusOne Desktop (macOS) - Swift/SwiftUI
│   │   ├── Sources/PlexusOneDesktop/
│   │   │   ├── App/          # App entry point, AppDelegate
│   │   │   ├── Models/       # Data models (Session, WindowState)
│   │   │   ├── Services/     # Business logic (SessionManager, AppState)
│   │   │   └── Views/        # SwiftUI views
│   │   └── Tests/PlexusOneDesktopTests/
│   └── mobile/               # PlexusOne Mobile (Flutter) - iOS/Android
├── services/
│   └── tuiparser/            # WebSocket bridge for mobile (Go)
│       ├── cmd/tuiparser/    # Entry point
│       ├── internal/         # Server, session management
│       └── pkg/              # Protocol definitions
├── docs/                     # MkDocs documentation site
│   ├── guide/desktop/        # Desktop app user guide
│   ├── guide/mobile/         # Mobile app user guide
│   ├── design/               # PRDs and design docs
│   └── releases/             # Release notes
└── CHANGELOG.json            # Structured changelog (use schangelog to generate CHANGELOG.md)
```

## Components

### PlexusOne Desktop (macOS)

Native terminal multiplexer built with Swift and SwiftTerm.

**Key Features:**
- Multi-window support with independent grid layouts
- Pop-out sessions to dedicated windows
- Attach/detach tmux sessions
- 10,000 line scrollback buffer
- State persistence across restarts

**Build & Run:**
```bash
cd apps/desktop
swift build
open "PlexusOne Desktop.app"
```

**Run Tests:**
```bash
cd apps/desktop
swift test
```

### PlexusOne Mobile (Flutter)

Companion app for remote monitoring via WebSocket.

**Build & Run:**
```bash
cd apps/mobile
flutter pub get
flutter run
```

### TUI Parser (Go)

WebSocket bridge that streams tmux output to mobile clients.

**Build & Run:**
```bash
cd services/tuiparser
go build -o bin/tuiparser ./cmd/tuiparser
./bin/tuiparser --port 9600
```

## Key Technologies

| Component | Stack |
|-----------|-------|
| Desktop | Swift 5.9+, SwiftUI, SwiftTerm, AppKit |
| Mobile | Flutter/Dart |
| TUI Parser | Go 1.22+, gorilla/websocket |
| Sessions | tmux |
| Docs | MkDocs Material |

## Development Conventions

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat(desktop): add multi-window support
fix(mobile): handle WebSocket reconnection
docs: update architecture diagram
refactor(tuiparser): extract session manager
```

### Changelog

Use structured changelog workflow:
```bash
# Update CHANGELOG.json with new entries
# Then regenerate:
schangelog generate CHANGELOG.json -o CHANGELOG.md
cp CHANGELOG.md docs/releases/changelog.md
```

### State Files

Desktop app state is stored in:
```
~/.plexusone/state.json
```

## Architecture Notes

### Desktop App Architecture

```
AppState (Singleton)
├── SessionManager       # Shared across all windows
└── WindowStateManager   # Tracks all window configs

Window A                 Window B
├── PaneManager (local)  ├── PaneManager (local)
└── GridConfig (local)   └── GridConfig (local)
```

- **SessionManager** is shared - sessions sync across windows
- **PaneManager** and **GridConfig** are per-window
- Windows communicate via NotificationCenter

### Key Files

| Purpose | Location |
|---------|----------|
| App entry | `apps/desktop/Sources/PlexusOneDesktop/App/PlexusOneDesktopApp.swift` |
| Shared state | `apps/desktop/Sources/PlexusOneDesktop/Services/AppState.swift` |
| Session logic | `apps/desktop/Sources/PlexusOneDesktop/Services/SessionManager.swift` |
| Window persistence | `apps/desktop/Sources/PlexusOneDesktop/Services/WindowStateManager.swift` |
| Terminal view | `apps/desktop/Sources/PlexusOneDesktop/Views/AppTerminalView.swift` |
| Main content | `apps/desktop/Sources/PlexusOneDesktop/Views/ContentView.swift` |

## Common Tasks

### Add a new feature to Desktop

1. Create/modify models in `Models/`
2. Add business logic in `Services/`
3. Create UI in `Views/`
4. Add tests in `Tests/PlexusOneDesktopTests/`
5. Update docs in `docs/guide/desktop/`

### Prepare a release

1. Update `CHANGELOG.json` with new version
2. Run `schangelog generate CHANGELOG.json -o CHANGELOG.md`
3. Copy to docs: `cp CHANGELOG.md docs/releases/changelog.md`
4. Create `docs/releases/vX.Y.Z.md`
5. Update `Info.plist` version
6. Update `mkdocs.yml` navigation
7. Commit, push, wait for CI, then tag

### Debug the Desktop app

```bash
cd apps/desktop
swift build
# Run directly to see console output:
.build/debug/PlexusOneDesktop
```

## Links

- [MkDocs Site](https://plexusone.github.io/plexusone-apps/)
- [GitHub Repo](https://github.com/plexusone/plexusone-apps)
