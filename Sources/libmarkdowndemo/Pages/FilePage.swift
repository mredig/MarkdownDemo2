import Foundation
import Hummingbird
import Markdown
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
		let markdownDocument = try attempt({
			try Document(parsing: fileURL)
		}, catch: {
			throw HTTPError(.badRequest, debugError: $0)
		})

		var imageLinker = ImageLinker(breadcrumbPath: breadcrumbPath.joined(separator: "/"))
		if let cleanDocument = imageLinker.visit(markdownDocument) {
			HTMLFormatter.format(cleanDocument, options: .parseInlineAttributeClass)
		} else {
			throw HTTPError(.badRequest, debugMessage: "image linker failed")
		}
	}

	func footerContent() throws -> any HTMLNode {
		let formattedDate = modificationDate.map(Self.dateFormatter.string(from:)) ?? "Unknown Date"
		P("this document last modified: \(formattedDate)")
			.addClass("mdrTimestamp")
	}
}

private struct ImageLinker: MarkupRewriter {
	let breadcrumbPath: String

	func visitImage(_ image: Image) -> Optional<any Markup> {
		guard let imageName = image.source else {
			return image
		}

		var fixed = image
		fixed.source = "/image?directory=\(breadcrumbPath)&file=\(imageName)"

		return fixed
	}
}
