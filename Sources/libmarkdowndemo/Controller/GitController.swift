import Foundation
import Logging
import SwiftPizzaSnips

final class GitController: Sendable {
	let checkoutLocation: URL

	let remote: URL

	let logger: Logger

	init(checkoutLocation: URL, remote: URL, logger: Logger) async throws {
		self.checkoutLocation = checkoutLocation
		self.remote = remote
		self.logger = logger

		try await checkoutRepo()

		if try await gitUserName() == nil {
			try runGitCLI(["config", "user.name", "MarkdownDemo2"])
		}

		if try await gitEmail() == nil {
			try runGitCLI(["config", "user.email", "no@email.available"])
		}
	}

	func gitUserName() async throws -> String? {
		try await runGitCLIOutput(["config", "user.name"])
	}

	func gitEmail() async throws -> String? {
		try await runGitCLIOutput(["config", "user.email"])
	}

	nonisolated(unsafe)
	private static let dateFormatter = ISO8601DateFormatter().with {
		$0.formatOptions = .withInternetDateTime
		$0.formatOptions.remove(.withFractionalSeconds)
	}
	func getModificationDate(for file: URL) async throws -> Date {
		guard checkoutLocation.isAParentOf(file) else { throw GitError.invalidFilePath }
		let gitPath = try URL.relativeFilePath(from: checkoutLocation, to: file)

		let dateString = try await runGitCLIOutput(["log", "-1", ##"--pretty=%cI"##, gitPath])
		return dateString.flatMap { Self.dateFormatter.date(from: $0) } ?? .distantPast
	}

	func pullUpdates() async throws {
		try await runGitCLIOutput(["pull", "--rebase"], shouldFowardOutputToConsole: true)
	}

	enum GitError: Error {
		case invalidFilePath
	}

	func checkoutRepo() async throws {
		if checkoutLocation.appending(path: ".git", directoryHint: .isDirectory).checkResourceIsAccessible() {
			try await pullUpdates()
		} else {
			try await runGitCLIOutput(["clone", self.remote.absoluteString, "."], shouldFowardOutputToConsole: true)
		}
	}

	@discardableResult
	private func runGitCLIOutput(_ args: [String], shouldFowardOutputToConsole: Bool = true) async throws -> String? {
		let pipes = try runGitCLI(args)

		func getLines(_ stream: FileHandle) async throws -> String {
			var accumulator = ""
			for try await line in stream.lines {
				accumulator.append(contentsOf: line)
				guard shouldFowardOutputToConsole else { continue }
				line.emptyIsNil.map { logger.debug("subprocess output:", metadata: ["output": "\($0)"]) }
			}

			return accumulator.trimmingCharacters(in: .whitespacesAndNewlines)
		}

		async let stdOut = getLines(pipes.stdOut)
		async let stdErr = getLines(pipes.stdErr)

		_ = try await stdErr

		return try await stdOut.emptyIsNil
	}

	struct CLIOutput: Sendable {
		let stdOut: FileHandle
		let stdErr: FileHandle
	}

	@discardableResult
	private func runGitCLI(_ args: [String], stdOut: Pipe? = nil, stdErr: Pipe? = nil) throws -> CLIOutput {
		let process = Process()

		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["git"] + args
		process.currentDirectoryURL = checkoutLocation

		let loggingString = (process.arguments ?? []).joined(separator: " ")
		logger.debug("Running subprocess", metadata: ["Command": "\(loggingString)"])

		let pipeOut = stdOut ?? Pipe()
		let pipeError = stdErr ?? Pipe()
		process.standardOutput = pipeOut
		process.standardError = pipeError

		let output = CLIOutput(stdOut: pipeOut.fileHandleForReading, stdErr: pipeError.fileHandleForReading)

		try process.run()

		return output
	}
}

