import Foundation
import yaHDSL

struct NavigationPage: HTMLContentProvider {
	let directoryContent: DirectoryContent

	let givenTitle: String?

	var breadcrumbPath: [String] { directoryContent.path }

	private var renderedTitle: String {
		[
			(givenTitle ?? "MarkdownDemo"),
			(directoryContent.path.last ?? "")
		]
			.joined(separator: " ")
	}

	var title: String {
		renderedTitle
	}

	func content() throws -> Group {
		H1(title)

		if directoryContent.directories.isOccupied {
			H3("Directories")
			for dir in directoryContent.directories {
				H4 {
					A(href: directoryContent.directoryLink(dir)) { dir }
				}
			}
		}

		if directoryContent.files.isOccupied {
			H3("Files")
			Ul {
				for file in directoryContent.files {
					Li {
						A(href: directoryContent.fileLink(file)) {
							(file as NSString).deletingPathExtension
						}
					}
				}
			}
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
