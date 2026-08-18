struct EnvKey: RawRepresentable {
	static let remoteRepo = EnvKey(rawValue: "REMOTE_REPO")

	let rawValue: String
	
	init(rawValue: String) {
		self.rawValue = rawValue
	}
}
