import Foundation
import Logging

@TaskManager.TaskManagerActor
enum TaskManager {
	@globalActor
	struct TaskManagerActor: GlobalActor {
		actor ActorType {}

		static let shared = ActorType()
	}

	struct RepeatingTask {
		let id = UUID()
		let label: String
		let frequency: TimeInterval
		let action: () async throws -> Void
	}

	static private(set) var tasks: [RepeatingTask] = []

	enum InitialDelay {
		case immediate
		case delayed(TimeInterval)
	}

	static func addTask(
		labelled label: String,
		frequency: TimeInterval,
		initialDelay: InitialDelay = .immediate,
		action: @escaping @Sendable () async throws -> Void
	) {
		let newRepeater = RepeatingTask(label: label, frequency: frequency, action: action)
		switch initialDelay {
		case .immediate:
			break
		case .delayed(let initialDelay):
			tracker[newRepeater.id] = Date(timeIntervalSinceNow: -frequency + initialDelay)
		}
		tasks.append(newRepeater)
	}

	private static var runner: Task<Void, Never>?

	static var isRunning: Bool { runner != nil }

	static private var tracker: [UUID: Date] = [:]

	static var pollFrequency: TimeInterval = 60

	static var logger: Logger!

	static func start(logger: Logger) {
		guard isRunning == false else { return }
		Self.logger = logger
		runner = Task {
			defer { runner = nil }
			while true {
				do {
					try await Task.sleep(for: .seconds(pollFrequency))

					let now = Date.now

					for task in tasks {
						let lastRun = tracker[task.id, default: .distantPast]

						if now.timeIntervalSince(lastRun) > task.frequency {
							tracker[task.id] = now

							Task {
								logger.debug(
									"Starting task",
									metadata: [
										"TaskID": "\(task.id.uuidString)",
										"TaskLabel": "\(task.label)",
									])
								let start = Date()

								do {
									try await task.action()
									let end = Date()
									let duration = end.timeIntervalSince(start)

									logger.trace(
										"Finished task",
										metadata: [
											"TaskID": "\(task.id.uuidString)",
											"TaskLabel": "\(task.label)",
											"TaskDuration": "\(duration)",
										])
								} catch {
									let end = Date()
									let duration = end.timeIntervalSince(start)

									logger.trace(
										"Task Failed",
										metadata: [
											"TaskID": "\(task.id.uuidString)",
											"TaskLabel": "\(task.label)",
											"TaskDuration": "\(duration)",
											"TaskError": "\(error)",
										])
								}
							}
						}
					}
				} catch {
					logger.error("Task running failed: \(error)")
				}
			}
		}
	}

	static func run<T>(_ block: @TaskManagerActor () throws -> T) rethrows -> T {
		try block()
	}
}
