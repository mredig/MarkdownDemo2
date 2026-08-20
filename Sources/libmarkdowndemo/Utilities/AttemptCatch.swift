
/// When running `do/catch`, your success is scoped within the `do` block. This is inconvenient, especially when you have simple catch operations (like conversion from one error type to another).
///	```swift
///	let foo: MyObject
///	do {
///		foo = try createFailableThing()
///	} catch {
///		throw OtherError()
///	}
///	// use foo
///	```
///
/// `attempt` instead allows
///
/// ```swift
/// let foo = try attempt({
///		try createFailableThing()
///	}, catch {
///		throw OtherError()
///	})
///
///	// use foo
/// ```
func attempt<Success, Failure: Error, Converted: Error>(
	_ doBlock: () throws(Failure) -> Success,
	catch catchBlock: (Failure) throws(Converted) -> Success
) throws(Converted) -> Success {
	do {
		return try doBlock()
	} catch {
		return try catchBlock(error)
	}
}

/// When running `do/catch`, your success is scoped within the `do` block. This is inconvenient, especially when you have simple catch operations (like conversion from one error type to another).
///	```swift
///	let foo: MyObject
///	do {
///		foo = try await createFailableThing()
///	} catch {
///		throw OtherError()
///	}
///	// use foo
///	```
///
/// `attempt` instead allows
///
/// ```swift
/// let foo = try await attempt({
///		try await createFailableThing()
///	}, catch {
///		throw OtherError()
///	})
///
///	// use foo
/// ```
func attempt<Success, Failure: Error, Converted: Error>(
	_ doBlock: sending () async throws(Failure) -> Success,
	catch catchBlock: sending (Failure) async throws(Converted) -> Success
) async throws(Converted) -> Success {
	do {
		return try await doBlock()
	} catch {
		return try await catchBlock(error)
	}
}
