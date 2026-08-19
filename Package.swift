// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "MarkdownDemo2",
	platforms: [
		.macOS(.v15),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
		.package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.6.1")),
		.package(url: "https://github.com/mredig/SwiftPizzaSnips.git", .upToNextMajor(from: "0.5.0")),
		.package(url: "https://github.com/hummingbird-project/hummingbird", .upToNextMajor(from: "2.26.0")),
		.package(url: "https://github.com/mredig/PizzaMacros.git", .upToNextMajor(from: "0.1.0")),
		.package(url: "https://github.com/mredig/yaHDSL.git", branch: "0.0.6c"),
		.package(url: "https://github.com/johnxnguyen/Down.git", from: "0.11.0"),
		.package(url: "https://github.com/mredig/SwiftlyDotEnv.git", from: "0.2.9"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "MarkdownDemo2",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"libmarkdowndemo",
			]
		),
		.target(
			name: "libmarkdowndemo",
			dependencies: [
				"SwiftPizzaSnips",
				.product(name: "Hummingbird", package: "hummingbird"),
				"PizzaMacros",
				.product(name: "Down", package: "down"),
				.product(name: "yaHDSL", package: "yaHDSL"),
				.product(name: "yaHDSL-Utilities", package: "yaHDSL"),
				.product(name: "Logging", package: "swift-log"),
				"SwiftlyDotEnv",
			]
		)
	],
	swiftLanguageModes: [.v6]
)
