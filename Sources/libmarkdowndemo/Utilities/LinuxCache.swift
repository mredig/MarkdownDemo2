import Synchronization

final class LinuxCache<Key: Sendable & Hashable, Value: Sendable>: Sendable {
	private let storage = Mutex<[Key: Value]>([:])

	subscript(key: Key) -> Value? {
		get {
			value(for: key)
		}
		set {
			setValue(newValue, for: key)
		}
	}

	func setValue(_ value: Value?, for key: Key) {
		storage.withLock {
			$0[key] = value
		}
	}

	func value(for key: Key) -> Value? {
		storage.withLock {
			$0[key]
		}
	}

	func transaction<Out, Failure: Error>(_ block: (inout [Key: Value]) throws(Failure) -> Out) throws(Failure) -> Out {
		try storage.withLock { dict throws(Failure) in
			try block(&dict)
		}
	}
}
