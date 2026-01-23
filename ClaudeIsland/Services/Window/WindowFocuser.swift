//
//  WindowFocuser.swift
//  ClaudeIsland
//
//  Focuses windows using yabai or native macOS activation
//

import AppKit
import Foundation

/// Focuses windows using yabai
actor WindowFocuser {
    static let shared = WindowFocuser()

    private init() {}

    /// Focus a window by ID
    func focusWindow(id: Int) async -> Bool {
        guard let yabaiPath = await WindowFinder.shared.getYabaiPath() else { return false }

        do {
            _ = try await ProcessExecutor.shared.run(yabaiPath, arguments: [
                "-m", "window", "--focus", String(id)
            ])
            return true
        } catch {
            return false
        }
    }

    /// Focus the tmux window for a terminal
    func focusTmuxWindow(terminalPid: Int, windows: [YabaiWindow]) async -> Bool {
        // Try to find actual tmux window
        if let tmuxWindow = WindowFinder.shared.findTmuxWindow(forTerminalPid: terminalPid, windows: windows) {
            return await focusWindow(id: tmuxWindow.id)
        }

        // Fall back to any non-Claude window
        if let window = WindowFinder.shared.findNonClaudeWindow(forTerminalPid: terminalPid, windows: windows) {
            return await focusWindow(id: window.id)
        }

        return false
    }

    /// Activate a terminal app and raise a specific window matching the working directory
    /// Uses Accessibility API to raise the correct window when multiple exist
    @MainActor
    func activateTerminal(pid: Int, cwd: String? = nil) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else {
            return false
        }

        // First, try to raise the specific window using Accessibility API
        if let cwd = cwd {
            let raised = raiseWindowMatchingCwd(pid: pid, cwd: cwd)
            if raised {
                // Also activate the app to ensure it's frontmost
                app.activate(options: .activateIgnoringOtherApps)
                return true
            }
        }

        // Fallback: just activate the app (brings any window to front)
        return app.activate(options: .activateIgnoringOtherApps)
    }

    /// Use Accessibility API to raise a specific window whose title contains the cwd
    @MainActor
    private func raiseWindowMatchingCwd(pid: Int, cwd: String) -> Bool {
        let appElement = AXUIElementCreateApplication(pid_t(pid))

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return false
        }

        // Extract the last path component for matching (e.g., "claude-island" from full path)
        let cwdName = (cwd as NSString).lastPathComponent

        for window in windows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)

            if let title = titleRef as? String {
                // Match if window title contains the directory name
                if title.contains(cwdName) || title.contains(cwd) {
                    AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                    return true
                }
            }
        }

        // If no match found by cwd, raise the first window (better than nothing)
        if let firstWindow = windows.first {
            AXUIElementPerformAction(firstWindow, kAXRaiseAction as CFString)
            return true
        }

        return false
    }
}
