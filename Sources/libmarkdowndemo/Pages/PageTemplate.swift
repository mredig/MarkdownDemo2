import Foundation
import yaHDSL

struct PageTemplate<Content: HTMLContentProvider>: HTMLPage {
	var title: String { content.title }

	var breadcrumbPath: [String] { content.breadcrumbPath }

	let content: Content

	var head: any HeadProtocol {
		Head {
			Title(title)

			Meta(attributes: [.charset: AttributeValue.string("utf-8")])
			Meta(attributes: [
				.name: AttributeValue.string("viewport"),
				.content: AttributeValue.list(["width=device-width", "initial-scale=1", "user-scalable=no"]),
			])

			Link(href: URL(string: "/css/modern.css"), rel: .Link.stylesheet)

			Script(src: "/js/livesearch.js")
		}
	}

	private var breadcrumbParagraph: P {
		// for some reason, the result builder couldn't handle this, so I had to write it more manually
		var p = P()
		p.addChildNode(A("Home", href: "/"))
		p.addChildNode(" / ")

		var builder: [String] = []

		for ancestorDirectory in breadcrumbPath {
			guard ancestorDirectory != "" else { continue }
			builder.append(ancestorDirectory)

			let linkPath = builder.joined(separator: "/")
			p.addChildNode(A(href: "?directory=\(linkPath)") { ancestorDirectory })
			p.addChildNode(" / ")
		}

		return p
	}

	var body: any BodyProtocol {
		get throws {
			try Body {
				Form {
					Div {
						Input(inputType: .search, name: "search", id: "search")
							.addClass("form-control")
							.withPlaceholder("search")
							.withValue("")
							.setOnKeyUp("showResult(this.value)")
							.setOnSearch("showResult(this.value)")
							.withAutoComplete(.off)
					}
					.addClass("form-group")

					Div().setID("markdownRepoLiveSearch")
				}
				.setClasses(["form-inline", "headerSearch"])

				let breadcrumbs = breadcrumbParagraph
				breadcrumbs
				
				try content.content()
				
				Hr()

				try content.footerContent()

				breadcrumbs
			}
		}
	}
}
