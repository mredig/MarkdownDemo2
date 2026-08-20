import Hummingbird
import NIOCore

struct MyBasicContext: RemoteAddressRequestContext {
	let remoteAddress: NIOCore.SocketAddress?
	
	var coreContext: CoreRequestContextStorage
	
	init(source: ApplicationRequestContextSource) {
		remoteAddress = source.channel.remoteAddress
		self.coreContext = CoreRequestContextStorage(source: source)
	}
}
