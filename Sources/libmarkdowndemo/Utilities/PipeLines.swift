import Foundation

extension FileHandle {
	/// Cross-platform stand-in for `.bytes.lines` (FileHandle.AsyncBytes is
	/// not in swift-corelibs-foundation).
	var lines: PipeLines { PipeLines(handle: self) }

	struct PipeLines: AsyncSequence, Sendable {
		typealias Element = String
		typealias AsyncIterator = AsyncThrowingStream<String, any Error>.AsyncIterator

		let handle: FileHandle

		func makeAsyncIterator() -> AsyncIterator {
			let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()

			let task = Task.detached {
				var pending = Data()

				while Task.isCancelled == false {
					let chunk = handle.availableData // blocks on this thread

					guard chunk.isEmpty == false else { break }
					pending.append(chunk)

					while let newlineIndex = pending.firstIndex(of: 0xA) {
						let line = pending.subdata(in: pending.startIndex..<newlineIndex)
						pending.removeSubrange(pending.startIndex...newlineIndex)
						continuation.yield(String(decoding: line, as: UTF8.self))
					}
				}
				defer { continuation.finish() }
				guard pending.isEmpty else { return }

				continuation.yield(String(decoding: pending, as: UTF8.self))
			}

			continuation.onTermination = { _ in task.cancel() }

			return stream.makeAsyncIterator()
		}
	}
}
