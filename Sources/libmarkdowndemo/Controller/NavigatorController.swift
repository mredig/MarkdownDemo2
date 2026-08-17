import Foundation
import Hummingbird

struct NavigatorController<C: RequestContext> {
	let baseDirectory: URL

	let siteTitle: String

	init(siteTitle: String, baseDirectory: URL) {
		self.siteTitle = siteTitle
		self.baseDirectory = baseDirectory.resolvingSymlinksInPath()
	}

	func addRoutes(_ group: RouterGroup<C>) {
		group
			.get("", use: rootPath)
	}

	private func rootPath(from request: Request, context: C) async throws -> some ResponseGenerator {
		let directory = request.uri.queryParameters.get("directory")
		let path = directory?.split(separator: "/").map(String.init) ?? []
		let file = request.uri.queryParameters.get("file")

		if let file {
			let fileURL = baseDirectory
				.appending(path: path.joined(separator: "/"))
				.appending(component: file)

			try shouldAllowLocalURL(fileURL)

			return try PageTemplate(content: FilePage(breadcrumbPath: path, fileURL: fileURL))
				.response(from: request, context: context)
		} else {
			let contents = try contentsOf(path: path)

			return try PageTemplate(content: NavigationPage(directoryContent: contents, givenTitle: siteTitle))
				.response(from: request, context: context)
		}
	}

	private func shouldAllowLocalURL(_ fileURL: URL) throws {
		let absoluteFileURL = fileURL.resolvingSymlinksInPath()

		let filePathComponents = absoluteFileURL.pathComponents

		let baseDirPathLength = baseDirectory.pathComponents.count

		guard
			filePathComponents.count >= baseDirPathLength,
			filePathComponents.prefix(upTo: baseDirPathLength) == ArraySlice(baseDirectory.pathComponents),
			case let fileSpecificComponents = filePathComponents[baseDirPathLength...],
			fileSpecificComponents.allSatisfy({ $0.hasPrefix(".") == false })
		else {
			throw HTTPError(.badRequest, message: "Illegal file request")
		}
	}

	enum PathType {
		case files
		case directories
		case discard
	}

	private func contentsOf(path: [String]) throws -> NavigationPage.DirectoryContent {
		let dir = baseDirectory.appending(path: path.joined(separator: "/"))
		try shouldAllowLocalURL(dir)
		let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey])

		let filteredContent = try contents.nfurcate { url in
			guard url.lastPathComponent.hasPrefix(".") == false else { return PathType.discard }

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
			$0.map(\.lastPathComponent).sorted()
		}

		return NavigationPage.DirectoryContent(
			path: path,
			directories: filteredContent[.directories] ?? [],
			files: filteredContent[.files] ?? [])
	}
}
