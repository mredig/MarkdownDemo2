import Hummingbird

extension HTTPError {
	init(_ status: HTTPResponse.Status, headers: HTTPFields = [:], debugMessage: String? = nil, releaseMessage: String? = nil) {
		#if DEBUG
		self.init(status, headers: headers, message: debugMessage)
		#else
		self.init(status, headers: headers, message: releaseMessage)
		#endif
	}
}
