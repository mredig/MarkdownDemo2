import Foundation
import Hummingbird
import Logging
import Synchronization

@MainActor
public struct LibMarkdownDemo2Entry {
	public struct Config: Sendable {
		public let serverName: String
		public let serverAddress: String
		public let serverPort: UInt16
		public let logLevel: Logger.Level

		public init(
			serverName: String,
			serverAddress: String,
			serverPort: UInt16,
			logLevel: Logger.Level
		) {
			self.serverName = serverName
			self.serverAddress = serverAddress
			self.serverPort = serverPort
			self.logLevel = logLevel
		}
	}

	public let config: Config

	public init(_ config: Config) {
		self.config = config
	}

	public func start() async throws {
		let logger = createLogger(labelled: "MarkdownDemo2")
		logger.info("Starting MarkdownDemo2")

		let router = configureRoutes()

		let config = ApplicationConfiguration(
			address: .hostname(config.serverAddress, port: Int(config.serverPort)),
			serverName: config.serverName)
		let app = Application(router: router, configuration: config, services: [], logger: logger)

		logger.info("Start listening...")
		try await app.runService()
	}

	private func configureRoutes() -> Router<BasicRequestContext> {
		let router = Router(context: BasicRequestContext.self, options: .autoGenerateHeadEndpoints)

		router.add(middleware: LogRequestsMiddleware(.info))
//		router.add(middleware: ErrorPage)
		router.add(middleware: FileMiddleware("site_assets/public"))
		router.get("/health") { _, _ in
			HTTPResponse.Status.ok
		}

		let navigationGroup = router.group("/")
		let navigationController = NavigatorController<BasicRequestContext>(baseDirectory: .currentDirectory(), siteTitle: config.serverName)
		navigationController.addRoutes(navigationGroup)

		print("Routes:")
		router.routes.forEach { print($0) }

		return router
	}

	private func createLogger(labelled label: String) -> Logger {
		Logger(label: label)
			.with {
				$0.logLevel = config.logLevel
			}
	}
}
