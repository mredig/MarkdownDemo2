import yaHDSL

struct IndexPage: HTMLPage {
	let content: DirectoryContent

	var head: any HeadProtocol {
		Head {
			Title("MarkdownDemo")
		}
	}

	var body: any BodyProtocol {
		Body {
			if content.directories.isOccupied {
				H3("Directories")
				Ul {
					for dir in content.directories {
						Li {
							dir
						}
					}
				}
			}

			if content.files.isOccupied {
				H3("Files")
				Ul {
					for file in content.files {
						Li {
							file
						}
					}
				}
			}
		}
	}

	struct DirectoryContent: Sendable {
		let path: [String]
		let directories: [String]
		let files: [String]
	}
}
