import yaHDSL

protocol HTMLContentProvider {
	var title: String { get }
	var breadcrumbPath: [String] { get }
	@HTMLContainerNodeBuilder
	func content() throws -> Group
}
