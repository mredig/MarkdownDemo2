import Foundation
import Hummingbird

struct NavigatorController<C: RequestContext> {
	let baseDirectory: URL

	func addRoutes(_ group: RouterGroup<C>) {
		group
			.get("", use: rootPath)
	}

	private func rootPath(from request: Request, context: C) async throws -> some ResponseGenerator {
		let path = context.parameters.get("directory")?.split(separator: "/").map(String.init) ?? ["/"]
		let file = context.parameters.get("file")

		if let file {
			throw NSError(domain: "Foo", code: 847)
		} else {
			let contents = try contentsOf(path: path)

			return IndexPage(content: contents)
		}
	}

	enum PathType {
		case files
		case directories
	}

	private func contentsOf(path: [String]) throws -> IndexPage.DirectoryContent {
		let dir = baseDirectory.appending(path: path.joined(separator: "/"))
		let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)

		let filteredContent = contents.nfurcate { url in
			if url.hasDirectoryPath {
				return PathType.directories
			} else {
				return PathType.files
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
