import SwiftPizzaSnips
//import HTTPTypes
extension HTTPFields: @retroactive Withable {}
extension HTTPRequest: @retroactive Withable {}

//import AsyncHTTPClient
//extension HTTPClientRequest: @retroactive Withable {}
//extension HTTPClientResponse: @retroactive Withable {}

import Hummingbird
extension Application: @retroactive Withable {}
extension Router: @retroactive Withable {}
extension Response: @retroactive Withable {}

import Logging
extension Logger: @retroactive Withable {}
