import Down
import Foundation
import Hummingbird
import yaHDSL

struct FilePage: HTMLContentProvider {
	static private let dateFormatter = DateFormatter().with {
		$0.dateStyle = .medium
	}

	let breadcrumbPath: [String]

	let fileURL: URL
	let modificationDate: Date?

	var title: String { fileURL.lastPathComponent }

	nonisolated(unsafe)
	private static let imageRegex = /img src="(?<imageName>.*(png|jpg|gif))"/.ignoresCase()

	func content() throws -> Group {
		let markdownData = try attempt({
			try Data(contentsOf: fileURL)
		}, catch: {
			throw HTTPError(.badRequest, debugError: $0)
		})

		let markdownString = String(decoding: markdownData, as: UTF8.self)

		let down = Down(markdownString: markdownString)

		let html = try attempt({
			try down.toHTML([.default])
		}, catch: {
			throw HTTPError(.internalServerError, debugError: $0, releaseMessage: "Markdown error")
		})

		html.replacing(Self.imageRegex) { match in
			"img src=\"/image?directory=\(breadcrumbPath.joined(separator: "/"))&file=\(match.output.imageName)\""
		}
	}

	func footerContent() throws -> any HTMLNode {
		let formattedDate = modificationDate.map(Self.dateFormatter.string(from:)) ?? "Unknown Date"
		P("this document last modified: \(formattedDate)")
			.addClass("mdrTimestamp")
	}
}
