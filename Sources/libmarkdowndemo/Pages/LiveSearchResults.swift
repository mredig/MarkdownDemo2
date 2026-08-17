import yaHDSL

struct LiveSearchResults {
	struct Result: Sendable {
		let name: String
		let link: String
	}

	let results: [Result]

	var list: Ul {
		Ul {
			for result in results {
				Li {
					A(result.name, href: result.link)
				}
			}
		}
	}
}
