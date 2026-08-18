import ArgumentParser
import Foundation
import libmarkdowndemo
import Logging
import SwiftlyDotEnv

@main
struct MarkdownDemo2: AsyncParsableCommand {

	@Option(name: .shortAndLong)
	var address: String = "127.0.0.1"
	@Option(name: .shortAndLong)
	var port: UInt16 = 8080

	@Option(name: .shortAndLong)
	var serverName: String?

	@Option(
		name: [.customShort("v"), .customLong("verbosity")],
		help: """
			Verbosity threshold. Only log statements at this value or higher will be logged. Valid values from lowest \
			to highest are `trace`, `debug`, `info`, `notice`, `warning`, `error`, and `critical`
			""",
		transform: {
			try Logger.Level(rawValue: $0).unwrap("Invalid log level '\($0)'")
		})
	var verbosityThreshold: Logger.Level = .info

	@Option(
		name: [.customShort("c"), .customLong("cache")],
		help: "Local checkout cache - where the remote repo will be stored locally.",
		transform: { URL(filePath: $0) })
	var localCheckoutCache: URL?

	@Option(
		name: [.customShort("r"), .customLong("remote")],
		help: "Remote repo - a repo with markdown notes accessible via git",
		transform: {
			try URL(string: $0).unwrap("Must provide a legitimate remote url")
		})
	var remoteRepo: URL?

    mutating func run() async throws {
		let dotEnv = SwiftlyDotEnv<EnvKey>()
		try SwiftlyDotEnv.loadDotEnv(requiringKeys: [EnvKey.remoteRepo.rawValue])

		guard
			let envRemoteRepo = dotEnv[.remoteRepo].flatMap({ URL(string: $0) })
		else { throw MarkdownDemoError.invalidRemoteRepo }

		let config = try LibMarkdownDemo2Entry.Config(
			serverName: serverName ?? dotEnv[.serverName] ?? "MarkdownDemo2",
			serverAddress: address,
			serverPort: port,
			localCheckoutCache: localCheckoutCache ?? dotEnv[.localCheckoutCache].flatMap(URL.init(string:)),
			remoteMarkdownGitRepo: remoteRepo ?? envRemoteRepo,
			logLevel: verbosityThreshold)

		let markdownDemo = await LibMarkdownDemo2Entry(config)
		try await markdownDemo.start()
    }
}

enum MarkdownDemoError: Error {
	case invalidRemoteRepo
}
