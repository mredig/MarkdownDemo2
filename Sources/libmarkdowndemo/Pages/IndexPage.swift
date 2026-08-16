import Foundation
import yaHDSL

struct IndexPage: HTMLPage {
	let content: DirectoryContent

	let givenTitle: String?

	private var renderedTitle: String {
		[
			(givenTitle ?? "MarkdownDemo"),
			(content.path.last ?? "")
		]
			.joined(separator: " ")
	}

	var head: any HeadProtocol {
		Head {
			Title("MarkdownDemo")
		}
	}

	private var breadcrumbParagraph: P {
		// for some reason, the result builder couldn't handle this, so I had to write it more manually
		var p = P()
		p.addChildNode(A("Home", href: "/"))
		p.addChildNode("/")

		var builder: [String] = []

		for ancestorDirectory in content.path {
			guard ancestorDirectory != "" else { continue }
			builder.append(ancestorDirectory)

			let linkPath = builder.joined(separator: "/")
			p.addChildNode(A(href: "?directory=\(linkPath)") { ancestorDirectory })
			p.addChildNode("/")
		}

		return p
	}

	var body: any BodyProtocol {
		Body {
			let breadcrumbs = breadcrumbParagraph
			breadcrumbs

			H1(renderedTitle)

			if content.directories.isOccupied {
				H3("Directories")
				for dir in content.directories {
					H4 {
						A(href: content.directoryLink(dir)) { dir }
					}
				}
			}

			if content.files.isOccupied {
				H3("Files")
				Ul {
					for file in content.files {
						Li {
							A(href: content.fileLink(file)) { file }
						}
					}
				}

				Hr()
			}

			breadcrumbs
		}
	}

	struct DirectoryContent: Sendable {
		let path: [String]
		let directories: [String]
		let files: [String]

		func directoryLink(_ directory: String) -> String {
			"?directory=\((path + [directory]).joined(separator: "/"))"
		}

		func fileLink(_ file: String) -> String {
			"\(directoryLink(""))&file=\(file)"
		}
	}
}
