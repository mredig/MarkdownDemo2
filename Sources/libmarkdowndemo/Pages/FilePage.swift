import Foundation
import Ink
import yaHDSL

struct FilePage: HTMLContentProvider {
	let breadcrumbPath: [String]

	let fileURL: URL

	var title: String { fileURL.lastPathComponent }

	func content() throws -> Group {
		let markdownData = try Data(contentsOf: fileURL)

		let parser = MarkdownParser()

		let result = parser.parse(String(decoding: markdownData, as: UTF8.self))

		result.html
	}
}
