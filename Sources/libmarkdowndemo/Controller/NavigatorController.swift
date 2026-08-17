import Foundation
import Hummingbird

struct NavigatorController<C: RequestContext> {
	let siteTitle: String

	let baseDirectory: URL

	let gitController: GitController

	init(siteTitle: String, baseDirectory: URL, gitController: GitController) {
		self.siteTitle = siteTitle
		self.baseDirectory = baseDirectory.resolvingSymlinksInPath()
		self.gitController = gitController
	}

	func addRoutes(_ group: RouterGroup<C>) {
		group
			.get("", use: rootPath)
			.get("livesearch", use: performLiveSearch)
			.get("image", use: imageLoader)
	}

	private func rootPath(from request: Request, context: C) async throws -> some ResponseGenerator {
		let directory = request.uri.queryParameters.get("directory")
		let path = directory?.split(separator: "/").map(String.init) ?? []
		let file = request.uri.queryParameters.get("file")

		if let file {
			let fileURL = baseDirectory
				.appending(path: path.joined(separator: "/"))
				.appending(component: file)
				.resolvingSymlinksInPath()

			try shouldAllowLocalURL(fileURL)

			let modDate = try await gitController.getModificationDate(for: fileURL)

			return try PageTemplate(content: FilePage(breadcrumbPath: path, fileURL: fileURL, modificationDate: modDate))
				.response(from: request, context: context)
		} else {
			let contents = try contentsOf(path: path)

			return try PageTemplate(content: NavigationPage(directoryContent: contents, givenTitle: siteTitle))
				.response(from: request, context: context)
		}
	}

	private func imageLoader(from request: Request, context: C) async throws -> some ResponseGenerator {
		let directory = request.uri.queryParameters.get("directory")
		let path = directory?.split(separator: "/").map(String.init) ?? []
		guard let file = request.uri.queryParameters.get("file") else { throw HTTPError(.notFound, message: "No matching image") }

		let fileURL = baseDirectory
			.appending(path: path.joined(separator: "/"))
			.appending(component: file)
			.resolvingSymlinksInPath()

		try shouldAllowLocalURL(fileURL)
		let allowedImageTypes = Set(["jpg", "jpeg", "png", "gif"])
		guard allowedImageTypes.contains(fileURL.pathExtension.lowercased()) else {
			throw HTTPError(.notFound, message: "Illegal image")
		}

		let imageData = try Data(contentsOf: fileURL)
		let imageBytes = ByteBuffer(bytes: imageData)
		return Response(
			status: .ok,
			headers: [
				.contentType: "image/jpg",
				.contentLength: "\(imageData.count)"
			],
			body: ResponseBody(byteBuffer: imageBytes))
	}

	private func performLiveSearch(from request: Request, context: C) async throws -> some ResponseGenerator {
		let searchQuery = request.uri.queryParameters.get("search")

		let foundFiles = try search(query: searchQuery)

		let basePathCount = baseDirectory.pathComponents.count
		let resultPaths = foundFiles.map {
			let linkPath = $0
				.deletingLastPathComponent()
				.pathComponents
				.dropFirst(basePathCount)
				.joined(separator: "/")
			return LiveSearchResults.Result(name: $0.deletingPathExtension().lastPathComponent, link: "?directory=\(linkPath)&file=\($0.lastPathComponent)")
		}
		.sorted { $0.name.lowercased() < $1.name.lowercased() }

		let results = LiveSearchResults(results: resultPaths)

		let output = try results.list.render(withContext: .default)
		let buffer = ByteBuffer(string: output)

		return Response(status: .ok, body: .init(byteBuffer: buffer))
	}

	private func search(query: String?) throws -> [URL] {
		guard
			let query = query?.emptyIsNil
		else { return [] }

		let searchEnumerator = try FileManager
			.default
			.enumerator(at: baseDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
			.unwrap(orThrow: HTTPError(.internalServerError))

		let queryTerms = query
			.lowercased()
			.split(separator: " ")
			.map(String.init)

		var accumulator: [URL] = []

		for case let fileURL as URL in searchEnumerator {
			guard
				fileURL.hasDirectoryPath == false,
				validMarkdownExtensions.contains(fileURL.pathExtension.lowercased())
			else { continue }
			do {
				try shouldAllowLocalURL(fileURL)
			} catch {
				continue
			}

			let fileContent = try String(decoding: Data(contentsOf: fileURL), as: UTF8.self)
				.lowercased()

			func match(queryItems: [String], in source: String) -> Bool {
				for queryItem in queryItems {
					guard source.contains(queryItem) else { return false }
				}
				return true
			}

			guard
				match(queryItems: queryTerms, in: fileContent)
			else { continue }

			accumulator.append(fileURL)
		}

		return accumulator
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
			if values.isRegularFile == true, validMarkdownExtensions.contains(url.pathExtension.lowercased()) {
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

	private let validMarkdownExtensions = Set(["md", "markdown"])

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
}
