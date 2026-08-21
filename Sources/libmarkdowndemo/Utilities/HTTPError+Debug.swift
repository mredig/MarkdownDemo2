import Hummingbird

extension HTTPError {
	init(_ status: HTTPResponse.Status, headers: HTTPFields = [:], debugMessage: String? = nil, releaseMessage: String? = nil) {
		#if DEBUG
		self.init(status, headers: headers, message: debugMessage)
		#else
		self.init(status, headers: headers, message: releaseMessage)
		#endif
	}

	init(_ status: HTTPResponse.Status, headers: HTTPFields = [:], debugError: (any Error)?, releaseMessage: String? = nil) {
		self.init(
			status,
			headers: headers,
			debugMessage: debugError.map { "Got error: \($0)" },
			releaseMessage: releaseMessage)
	}
}
