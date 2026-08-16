import Foundation
import Down
import yaHDSL

struct FilePage: HTMLContentProvider {
	let breadcrumbPath: [String]

	let fileURL: URL

	var title: String { fileURL.lastPathComponent }

	func content() throws -> Group {
		let markdownData = try Data(contentsOf: fileURL)
		let markdownString = String(decoding: markdownData, as: UTF8.self)

		let down = Down(markdownString: markdownString)

		try down.toHTML([.default])
	}
}
