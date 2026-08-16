// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import libmarkdowndemo
import Logging

@main
struct MarkdownDemo2: AsyncParsableCommand {

	@Option(name: .shortAndLong)
	var address: String = "127.0.0.1"
	@Option(name: .shortAndLong)
	var port: UInt16 = 8080

	@Option(name: .shortAndLong)
	var serverName: String = "MarkdownDemo2"

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

    mutating func run() async throws {
		let config = LibMarkdownDemo2Entry.Config(
			serverName: serverName,
			serverAddress: address,
			serverPort: port,
			logLevel: verbosityThreshold)

		let markdownDemo = await LibMarkdownDemo2Entry(config)
		try await markdownDemo.start()
    }
}
