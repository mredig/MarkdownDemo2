import Hummingbird
import yaHDSL_Utilities

protocol HTMLPage: HTMLPageGenerator, ResponseGenerator {}

extension HTMLPage {
	func response(from request: Request, context: some RequestContext) throws -> Response {
		let str = try render()
		let buffer = ByteBuffer(string: str)
		return Response(
			status: .ok,
			headers: [
				.contentType: "text/html",
				.contentLength: buffer.readableBytes.description
			],
			body: ResponseBody(byteBuffer: buffer))
	}
}
