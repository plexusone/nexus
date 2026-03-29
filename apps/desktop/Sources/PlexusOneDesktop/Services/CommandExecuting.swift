import Foundation

/// Protocol for executing shell commands, enabling dependency injection for testing
protocol CommandExecuting: Sendable {
    func execute(_ path: String, arguments: [String]) async throws -> CommandResult
}

/// Default implementation using Process
struct ProcessCommandExecutor: CommandExecuting {
    func execute(_ path: String, arguments: [String]) async throws -> CommandResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
                process.waitUntilExit()

                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let result = CommandResult(
                    exitCode: process.terminationStatus,
                    stdout: String(data: stdoutData, encoding: .utf8) ?? "",
                    stderr: String(data: stderrData, encoding: .utf8) ?? ""
                )
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: SessionManagerError.commandFailed(error.localizedDescription))
            }
        }
    }
}
