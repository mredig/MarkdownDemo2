import Foundation
import Logging
import Hummingbird
import SwiftPizzaSnips

struct IPRateLimiter<Context: RemoteAddressRequestContext>: RouterMiddleware {
	let cache: LinuxCache<String, [Date]>

	let rate: Int
	let window: TimeInterval

	let logger: Logger

	private let cacheLock = MutexLock()

	init(cache: LinuxCache<String, [Date]>, rate: Int, window: TimeInterval, logger: Logger) {
		self.cache = cache
		self.rate = rate
		self.window = window
		self.logger = logger

		logger.info("IPRateLimit initialized", metadata: ["AllowRate": .stringConvertible(rate), "AccessWindowSeconds": .stringConvertible(window)])
	}

	func handle(
		_ input: Request,
		context: Context,
		next: (Request, Context) async throws -> Response
	) async throws -> Response {
		guard let ipAddress = context.remoteAddress?.ipAddress else {
			logger.warning("Encountered missing client IP address")
			throw HTTPError(.badRequest, message: "Invalid remote IP address")
		}

		try cacheLock.withLock {
			var ipAccessHistory = cache[ipAddress] ?? []
			logger.trace(
				"Existing history",
				metadata: ["AccessTimestamps": .stringConvertible(ipAccessHistory), "IP": .stringConvertible("\(ipAddress)")])

			let now = Date.now
			ipAccessHistory.append(now)
			ipAccessHistory = ipAccessHistory.filter({
				now.timeIntervalSince($0) < window
			})
			cache[ipAddress] = ipAccessHistory

			guard ipAccessHistory.count <= rate else {
				logger.debug("Rejected rate abusing ip address", metadata: ["IP": .string(ipAddress)])
				throw HTTPError(.tooManyRequests)
			}
			logger.trace("Allowing access", metadata: ["AccessTimestamps": .stringConvertible(ipAccessHistory), "UserAgent": .string(ipAddress)])
		}

		return try await next(input, context)
	}
}
