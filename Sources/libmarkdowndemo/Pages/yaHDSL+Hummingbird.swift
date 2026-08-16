import HTTPTypes
import Hummingbird
import NIOHTTP1
import yaHDSL_Utilities

protocol HTMLPage: HTMLPageGenerator, ResponseGenerator {
	var additionalResponseHeaders: [HTTPField.Name: String] { get }
}

extension HTMLPage {
	var additionalResponseHeaders: [HTTPField.Name: String] { [:] }

	func response(from request: Request, context: some RequestContext) throws -> Response {
		let str = try render()
		let buffer = ByteBuffer(string: str)

		var composedHeaders: [HTTPField.Name: String] = additionalResponseHeaders
		composedHeaders[.contentType] = "text/html"
		composedHeaders[.contentLength] = buffer.readableBytes.description

		let headers = composedHeaders.reduce(into: HTTPFields()) {
			$0.append(HTTPField(name: $1.key, value: $1.value))
		}

		return Response(
			status: .ok,
			headers: headers,
			body: ResponseBody(byteBuffer: buffer))
	}
}
