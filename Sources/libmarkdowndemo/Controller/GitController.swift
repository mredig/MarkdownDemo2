import Foundation
import SwiftGitX
import SwiftPizzaSnips

final class GitController: Sendable {
	let repo: Repository

	let checkoutLocation: URL

	let remote: URL

	init(checkoutLocation: URL, remote: URL) async throws {
		let repo: Repository
		do {
			repo = try Repository(at: checkoutLocation, createIfNotExists: false)
		} catch {
			guard error.code == .notFound, error.category == .repository else { throw error }
			repo = try await Repository.clone(from: remote, to: checkoutLocation, options: .default, transferProgressHandler: nil)
		}

		self.repo = repo
		self.checkoutLocation = checkoutLocation
		self.remote = remote

		if try await gitUserName() == nil {
			try runGitCLI(["config", "user.name", "MarkdownDemo2"])
		}

		if try await gitEmail() == nil {
			try runGitCLI(["config", "user.email", "no@email.available"])
		}
	}

	func gitUserName() async throws -> String? {
		try await runGitCLIString(["config", "user.name"])
	}

	func gitEmail() async throws -> String? {
		try await runGitCLIString(["config", "user.email"])
	}

	nonisolated(unsafe)
	private static let dateFormatter = ISO8601DateFormatter().with {
		$0.formatOptions = .withInternetDateTime
		$0.formatOptions.remove(.withFractionalSeconds)
	}
	func getModificationDate(for file: URL) async throws -> Date {
		guard checkoutLocation.isAParentOf(file) else { throw GitError.invalidFilePath }
		let gitPath = try URL.relativeFilePath(from: checkoutLocation, to: file)

		let dateString = try await runGitCLIString(["log", "-1", ##"--pretty=%cI"##, gitPath])
		return dateString.flatMap { Self.dateFormatter.date(from: $0) } ?? .distantPast
	}

	enum GitError: Error {
		case invalidFilePath
	}

	private func runGitCLIString(_ args: [String]) async throws -> String? {
		let pipes = try runGitCLI(args)

		var accumulator = ""
		for try await line in pipes.stdOut.lines {
			print(line)
			accumulator.append(contentsOf: line)
		}

		return accumulator.trimmingCharacters(in: .whitespacesAndNewlines).emptyIsNil
	}

	struct CLIOutput: Sendable {
		let stdOut: FileHandle.AsyncBytes
		let stdErr: FileHandle.AsyncBytes
	}

	@discardableResult
	private func runGitCLI(_ args: [String], stdOut: Pipe? = nil, stdErr: Pipe? = nil) throws -> CLIOutput {
		let process = Process()

		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["git"] + args
		process.currentDirectoryURL = checkoutLocation

		let pipeOut = stdOut ?? Pipe()
		let pipeError = stdErr ?? Pipe()
		process.standardOutput = pipeOut
		process.standardError = pipeError

		let output = CLIOutput(stdOut: pipeOut.fileHandleForReading.bytes, stdErr: pipeError.fileHandleForReading.bytes)

		try process.run()

		return output
	}
}
