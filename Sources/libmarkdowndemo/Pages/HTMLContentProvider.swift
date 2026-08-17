import yaHDSL

protocol HTMLContentProvider {
	var title: String { get }
	var breadcrumbPath: [String] { get }
	@HTMLContainerNodeBuilder
	func content() throws -> Group

	@HTMLContainerNodeBuilder
	func footerContent() throws -> any HTMLNode
}

extension HTMLContentProvider {
	func footerContent() throws -> any HTMLNode {
		Empty()
	}
}
