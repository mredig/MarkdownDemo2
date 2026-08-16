import Foundation
import yaHDSL

struct PageTemplate<Content: HTMLContentProvider, FooterContent: HTMLNode>: HTMLPage {
	var title: String { content.title }

	var breadcrumbPath: [String] { content.breadcrumbPath }

	let content: Content
	let footerContent: FooterContent

	init(content: Content) where FooterContent == Empty {
		self.content = content
		self.footerContent = Empty()
	}

	init(content: Content, footerContent: FooterContent) {
		self.content = content
		self.footerContent = footerContent
	}

	var head: any HeadProtocol {
		Head {
			Title(title)

			Meta(attributes: [.charset: AttributeValue.string("utf-8")])
			Meta(attributes: [
				.name: AttributeValue.string("viewport"),
				.content: AttributeValue.list(["width=device-width", "initial-scale=1", "user-scalable=no"]),
			])

			Link(href: URL(string: "/css/modern.css"), rel: .Link.stylesheet)
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
				let breadcrumbs = breadcrumbParagraph
				breadcrumbs
				
				try content.content()
				
				Hr()

				footerContent

				breadcrumbs
			}
		}
	}
}
