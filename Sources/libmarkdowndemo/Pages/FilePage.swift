import Foundation
import Down
import yaHDSL

struct FilePage: HTMLContentProvider {
	static private let dateFormatter = DateFormatter().with {
		$0.dateStyle = .medium
	}

	let breadcrumbPath: [String]

	let fileURL: URL
	let modificationDate: Date

	var title: String { fileURL.lastPathComponent }

	nonisolated(unsafe)
	private static let imageRegex = /img src="(?<imageName>.*(png|jpg|gif))"/.ignoresCase()

	func content() throws -> Group {
		let markdownData = try Data(contentsOf: fileURL)
		let markdownString = String(decoding: markdownData, as: UTF8.self)

		let down = Down(markdownString: markdownString)

		let html = try down.toHTML([.default])

		html.replacing(Self.imageRegex) { match in
			"img src=\"/image?directory=\(breadcrumbPath.joined(separator: "/"))&file=\(match.output.imageName)\""
		}
	}

	func footerContent() throws -> any HTMLNode {
		P("this document last modified: \(Self.dateFormatter.string(from: modificationDate))")
			.addClass("mdrTimestamp")
	}
}
