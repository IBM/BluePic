/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

 public enum RouteHandlerError: Int, Error {
    case accepted = 202, badGateway = 502, badRequest = 400, conflict = 409, `continue` = 100, created = 201
    case expectationFailed = 417, failedDependency = 424, forbidden = 403, gatewayTimeout = 504, gone = 410
    case httpVersionNotSupported = 505, insufficientSpaceOnResource = 419, insufficientStorage = 507
    case internalServerError = 500, lengthRequired = 411, methodFailure = 420, methodNotAllowed = 405
    case movedPermanently = 301, movedTemporarily = 302, multiStatus = 207, multipleChoices = 300
    case networkAuthenticationRequired = 511, noContent = 204, nonAuthoritativeInformation = 203
    case notAcceptable = 406, notFound = 404, notImplemented = 501, notModified = 304, OK = 200
    case partialContent = 206, paymentRequired = 402, preconditionFailed = 412, preconditionRequired = 428
    case proxyAuthenticationRequired = 407, processing = 102, requestHeaderFieldsTooLarge = 431
    case requestTimeout = 408, requestTooLong = 413, requestURITooLong = 414, requestedRangeNotSatisfiable = 416
    case resetContent = 205, seeOther = 303, serviceUnavailable = 503, switchingProtocols = 101
    case temporaryRedirect = 307, tooManyRequests = 429, unauthorized = 401, unprocessableEntity = 422
    case unsupportedMediaType = 415, useProxy = 305, misdirectedRequest = 421, unknown = -1
}

 public struct GenericError: Error {
     let code: Int?
     let message: String?
 }

 public enum TypeError: Error {
    case invalidIdentifier
    case unknown
}

public protocol Identifier {
    init(value: String) throws
    var value: String { get }
}

extension String: Identifier {
    public init(value: String) {
        self.init(value)
    }

    public var value: String {
        get {
            return self
        }
    }
}

extension Int: Identifier {
    public init(value: String) throws {
        if let id = Int(value) {
            self = id
        } else {
            throw TypeError.invalidIdentifier
        }
    }

    public var value: String {
        return String(describing: self)
    }
}

public protocol Persistable: Codable {
    // Related types
    associatedtype Id: Identifier

    // Create
    static func create(model: Self, respondWith: @escaping (Self?, Error?) -> Void)
    // Read
    static func read(id: Id, respondWith: @escaping (Self?, Error?) -> Void)
    // Read all
    static func read(respondWith: @escaping ([Self]?, Error?) -> Void)
    // Update
    static func update(id: Id, model: Self, respondWith: @escaping (Self?, Error?) -> Void)
    // How about returning Identifer instaces for the delere operations?
    // Delete
    static func delete(id: Id, respondWith: @escaping (Error?) -> Void)
    // Delete all
    static func delete(respondWith: @escaping (Error?) -> Void)
}

// Provides utility methods for getting the type  and routes for the class
// conforming to Persistable
public extension Persistable {
    // Set up name space based on name of model (e.g. User -> user(s))
    static var type: String {
        let kind = String(describing: Swift.type(of: self))
        return String(kind.characters.dropLast(5))
    }
    static var typeLowerCased: String { return "\(type.lowercased())" }
    static var route: String { return "/\(typeLowerCased)s" }
}
