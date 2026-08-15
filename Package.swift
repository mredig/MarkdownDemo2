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
//		.package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", .upToNextMajor(from: "2.0.2")),
//		.package(url: "https://github.com/hummingbird-project/hummingbird-fluent", .upToNextMajor(from: "2.0.0")),
//		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", .upToNextMajor(from: "4.7.0")),
		.package(url: "https://github.com/mredig/PizzaMacros.git", .upToNextMajor(from: "0.1.0")),
		.package(url: "https://github.com/mredig/yaHDSL.git", branch: "0.0.5h"),
		.package(url: "https://github.com/ibrahimcetin/SwiftGitX.git", from: "0.4.0"),
		.package(url: "https://github.com/JohnSundell/Ink.git", from: "0.6.0")
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
//				.product(name: "HummingbirdAuth", package: "hummingbird-auth"),
//				.product(name: "HummingbirdBasicAuth", package: "hummingbird-auth"),
//				.product(name: "HummingbirdFluent", package: "hummingbird-fluent"),
//				.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
				"PizzaMacros",
				"yaHDSL",
				.product(name: "Logging", package: "swift-log"),
			]
		)
	],
	swiftLanguageModes: [.v6]
)
