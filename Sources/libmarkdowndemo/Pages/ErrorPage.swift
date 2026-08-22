import Hummingbird
import yaHDSL

struct ErrorPage: HTMLPage {

	let error: HTTPError

	var head: any HeadProtocol {
		Head {
			Title("Error")
		}
	}

	var body: any BodyProtocol {
		Body {
			H1("Error")
			
			P(error.status.reasonPhrase)
			#if DEBUG
			if let body = error.body {
				H4("Debug info:")
				P(body)
			}
			#endif
		}
	}
}
