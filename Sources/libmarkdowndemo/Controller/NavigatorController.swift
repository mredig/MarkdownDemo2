import Foundation
import Hummingbird

struct NavigatorController<C: RequestContext> {
	func addRoutes(_ group: RouterGroup<C>) {
		group
			.get("", use: rootPath)
	}

	private func rootPath(from request: Request, context: C) async throws -> some ResponseGenerator {
		IndexPage()
	}
}
