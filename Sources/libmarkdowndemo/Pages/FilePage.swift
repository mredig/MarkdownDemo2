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

	func content() throws -> Group {
		let markdownData = try Data(contentsOf: fileURL)
		let markdownString = String(decoding: markdownData, as: UTF8.self)

		let down = Down(markdownString: markdownString)

		try down.toHTML([.default])
	}

	func footerContent() throws -> any HTMLNode {
		P("this document last modified: \(Self.dateFormatter.string(from: modificationDate))")
			.addClass("mdrTimestamp")
	}
}
