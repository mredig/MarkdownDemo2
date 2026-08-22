//
//  ErrorPageMiddleware.swift
//  MarkdownDemo2
//
//  Created by Michael Redig on 8/22/26.
//


import Hummingbird

struct ErrorPageMiddleware<Context: RequestContext>: RouterMiddleware {
	func handle(
		_ request: Request,
		context: Context,
		next: (Request, Context) async throws -> Response
	) async throws -> Response {
		let httpError: HTTPError
		do {
			return try await next(request, context)
		} catch let error as HTTPError {
			httpError = error
		} catch let error as HTTPResponseError {
			httpError = HTTPError(error.status, message: "\(error)")
		} catch {
			#if DEBUG
			httpError = HTTPError(.internalServerError, message: "\(error)")
			#else
			httpError = HTTPError(.internalServerError)
			#endif
		}

		let errorPage = ErrorPage(error: httpError)
		return try errorPage
			.response(from: request, context: context)
			.with {
				$0.status = httpError.status
			}
	}
}
