import Foundation
import Hummingbird

struct NavigatorController<C: RequestContext> {
	let baseDirectory: URL

	let siteTitle: String

	func addRoutes(_ group: RouterGroup<C>) {
		group
			.get("", use: rootPath)
	}

	private func rootPath(from request: Request, context: C) async throws -> some ResponseGenerator {
		let directory = request.uri.queryParameters.get("directory")
		let path = directory?.split(separator: "/").map(String.init) ?? []
		let file = request.uri.queryParameters.get("file")

		if let file {
			throw NSError(domain: "Foo", code: 847)
		} else {
			let contents = try contentsOf(path: path)

			return IndexPage(content: contents, givenTitle: siteTitle)
		}
	}

	enum PathType {
		case files
		case directories
		case discard
	}

	private func contentsOf(path: [String]) throws -> IndexPage.DirectoryContent {
		let dir = baseDirectory.appending(path: path.joined(separator: "/"))
		let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey])

		let filteredContent = try contents.nfurcate { url in
			let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
			if values.isRegularFile == true {
				return PathType.files
			} else if values.isDirectory == true {
				return PathType.directories
			} else {
				return .discard
			}
		}
		.mapValues {
			$0.map(\.lastPathComponent)
		}

		return IndexPage.DirectoryContent(
			path: path,
			directories: filteredContent[.directories] ?? [],
			files: filteredContent[.files] ?? [])
	}
}
