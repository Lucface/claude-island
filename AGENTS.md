# Claude Island Agent Instructions

Use this file for Codex/agent work in the Claude Island macOS app. Project background lives in `CLAUDE.md`.

## Commands

```bash
xcodebuild -scheme ClaudeIsland -configuration Debug build
xcodebuild -scheme ClaudeIsland -configuration Release build
```

## Working Rules

- Keep changes scoped to the Swift app, hook bridge, or session-state behavior requested.
- Verify with an Xcode build after code edits.
- For hook/session changes, launch the app and verify a live Claude Code session produces visible events when feasible.
- Do not expand analytics or conversation-content collection without explicit approval.
- Treat accessibility, screen, socket, and hook behavior as workflow-critical.

