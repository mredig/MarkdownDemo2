import Foundation
import Logging
import HTTPTypes
import Hummingbird
import SwiftPizzaSnips

struct RateLimitUserAgentMiddleware<Context: RequestContext>: RouterMiddleware {
	nonisolated(unsafe)
	let cache: NSwiftCache<String, [Date]>

	let rate: Int
	let window: TimeInterval

	let logger: Logger

	private let cacheLock = MutexLock()

	private let limitedUserAgentKeywords = Set([
		"bot",
		"facebook",
	])

	func handle(
		_ input: Request,
		context: Context,
		next: (Request, Context) async throws -> Response
	) async throws -> Response {
		guard
			let rawUserAgent = input.headers[.userAgent],
			case let userAgent = rawUserAgent.lowercased(),
			userAgent.count > 10
		else {
			logger.debug("Encountered malformed user agent", metadata: ["UserAgent": .string(input.headers[.userAgent] ?? "[missing]")])
			#if DEBUG
			throw HTTPError(.badRequest, message: "Legitimate user agent required")
			#else
			throw HTTPError(.badRequest)
			#endif
		}

		keywordSearch: for keyword in limitedUserAgentKeywords {
			if userAgent.contains(keyword) {
				cacheLock.lock()
				defer { cacheLock.unlock() }

				var agentHistory = cache[userAgent] ?? []
				let now = Date.now
				agentHistory.append(now)

				agentHistory = agentHistory.filter({
					now.timeIntervalSince($0) < window
				})
				cache[userAgent] = agentHistory

				guard agentHistory.count <= rate else {
					logger.debug("Rejected rate abusing user agent", metadata: ["UserAgent": .string(rawUserAgent)])
					throw HTTPError(.tooManyRequests)
				}
				break keywordSearch
			}
		}

		return try await next(input, context)
	}
}
