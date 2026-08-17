import Foundation
import Hummingbird
import Logging
import Synchronization

@MainActor
public class LibMarkdownDemo2Entry {
	public struct Config: Sendable {
		public let serverName: String
		public let serverAddress: String
		public let serverPort: UInt16
		public let localCheckoutCache: URL
		public let remoteMarkdownGitRepo: URL
		public let logLevel: Logger.Level

		public init(
			serverName: String,
			serverAddress: String,
			serverPort: UInt16,
			localCheckoutCache: URL?,
			remoteMarkdownGitRepo: URL,
			logLevel: Logger.Level
		) throws {
			self.serverName = serverName
			self.serverAddress = serverAddress
			self.serverPort = serverPort

			let applicationSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

			self.localCheckoutCache = localCheckoutCache ?? applicationSupportDir
				.appending(component: "pizza.appsby.MarkdownDemo2")
				.appending(component: "Checkout", directoryHint: .isDirectory)
			self.remoteMarkdownGitRepo = remoteMarkdownGitRepo
			self.logLevel = logLevel
		}
	}

	public let config: Config

	private var gitController: GitController?

	public init(_ config: Config) {
		self.config = config
	}

	public func start() async throws {
		let logger = createLogger(labelled: "MarkdownDemo2")
		logger.info("Starting MarkdownDemo2")

		logger.info("Using \(config.localCheckoutCache.path(percentEncoded: false)) for local checkout")

		try await checkoutRepo()

		let router = try configureRoutes()

		let config = ApplicationConfiguration(
			address: .hostname(config.serverAddress, port: Int(config.serverPort)),
			serverName: config.serverName)
		let app = Application(router: router, configuration: config, services: [], logger: logger)

		logger.info("Start listening...")
		try await app.runService()
	}

	private func configureRoutes() throws -> Router<BasicRequestContext> {
		let router = Router(context: BasicRequestContext.self, options: .autoGenerateHeadEndpoints)

		router.add(middleware: LogRequestsMiddleware(.info))
//		router.add(middleware: ErrorPage)
		router.add(middleware: FileMiddleware("site_assets/public"))
		router.get("/health") { _, _ in
			HTTPResponse.Status.ok
		}

		try FileManager.default.createDirectory(at: config.localCheckoutCache, withIntermediateDirectories: true)

		let navigationGroup = router.group("/")
		let navigationController = NavigatorController<BasicRequestContext>(siteTitle: config.serverName, baseDirectory: config.localCheckoutCache)
		navigationController.addRoutes(navigationGroup)

		print("Routes:")
		router.routes.forEach { print($0) }

		return router
	}

	private func checkoutRepo() async throws {
		let gitController = try await GitController(
			checkoutLocation: config.localCheckoutCache,
			remote: config.remoteMarkdownGitRepo)
		self.gitController = gitController
	}

	private func createLogger(labelled label: String) -> Logger {
		Logger(label: label)
			.with {
				$0.logLevel = config.logLevel
			}
	}
}
