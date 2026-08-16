import yaHDSL

struct IndexPage: HTMLPage {
	var head: any HeadProtocol {
		Head {
			Title("MarkdownDemo")
		}
	}

	var body: any BodyProtocol {
		Body {
			"Hello World"
		}
	}
}
