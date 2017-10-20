/**
 * Copyright IBM Corporation 2016,2017
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

import Foundation
import CircuitBreaker

/// Object containing everything needed to build HTTP requests and execute them
public class RestRequest {

    /// A default `URLSession` instance
    private let session = URLSession(configuration: URLSessionConfiguration.default)

    /// `CircuitBreaker` instance for this `RestRequest`
    public var circuitBreaker: CircuitBreaker<(Data?, HTTPURLResponse?, Error?) -> Void, Void, String>?

    /// Parameters for a `CircuitBreaker` instance.
    /// When set, a new circuitBreaker instance is created
    public var circuitParameters: CircuitParameters<String>? = nil {
        didSet {
            if let params = circuitParameters {
                circuitBreaker = CircuitBreaker(timeout: params.timeout,
                                                resetTimeout: params.resetTimeout,
                                                maxFailures: params.maxFailures,
                                                rollingWindow: params.rollingWindow,
                                                bulkhead: params.bulkhead,
                                                contextCommand: handleInvocation,
                                                fallback: params.fallback)
            }
        }
    }

    // MARK: HTTP Request Paramters

    /// URL `String` used to store a url containing replacable template values
    private var urlTemplate: String?

    /// The string representation of HTTP request url
    private var url: String

    /// The HTTP request method: defaults to Get
    public var method: HTTPMethod = .get

    /// HTTP Credentials
    public var credentials: Credentials?

    /// HTTP Header Parameters
    public var headerParameters: [String: String] = [:]

    /// HTTP Accept Type Header
    public var acceptType: String? = "application/json"

    /// HTTP Content Type Header: defaults to application/json
    public var contentType: String? = "application/json"

    /// HTTP Message Body
    public var messageBody: Data?

    /// HTTP User-Agent Header
    public var productInfo: String?

    /// Initialize a `RestRequest` instance
    ///
    /// - Parameters:
    ///   - url: URL string to use for network request
    public init(method: HTTPMethod = .get, url: String) {
        self.url = url
        self.method = method

        // We accept URLs with templated values which `URLComponents` does not treat as valid
        if URLComponents(string: url) == nil {
            self.urlTemplate = url
        }
    }

    // MARK: Response methods

    /// Request response method that either invokes `CircuitBreaker` or executes the HTTP request
    ///
    /// - Parameter completionHandler: Callback used on completion of operation
    public func response(completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        if let breaker = circuitBreaker {
            breaker.run(commandArgs: completionHandler, fallbackArgs: "Circuit is open")
        } else {
            let task = session.dataTask(with: build().0) { (data, response, error) in
                let response = response as? HTTPURLResponse
                if let code = response?.statusCode,
                    code >= 200 && code < 300 {
                    completionHandler(data, response, error)
                } else {
                    completionHandler(data,
                                      response,
                                      RestError.erroredResponseStatus("\(String(describing: response?.statusCode))"))
                }
            }
            task.resume()
        }
    }

    /// Request response method with the expected result of a `Data` object
    ///
    /// - Parameters:
    ///   - templateParams: URL templating parameters used for substituion if possible
    ///   - queryItems: array containing `URLQueryItem` objects that will be appended to the request's URL
    ///   - completionHandler: Callback used on completion of operation
    public func responseData(templateParams: [String: String]? = nil,
                             queryItems: [URLQueryItem]? = nil,
                             completionHandler: @escaping (RestResponse<Data>) -> Void) {

        let (request, error) = build(templateParams: templateParams, queryItems: queryItems)

        // determine if params should be considered and substituted into url
        if  let error = error {
            let result = Result<Data>.failure(error)
            let dataResponse = RestResponse(request: request, response: nil, data: nil, result: result)
            completionHandler(dataResponse)
            return
        }

        response { data, response, error in

            if let error = error {
                let result = Result<Data>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }

            guard let data = data else {
                let result = Result<Data>.failure(RestError.noData)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }
            let result = Result.success(data)
            let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
            completionHandler(dataResponse)
        }
    }

    /// Request response method with the expected result of the object, `T` specified
    ///
    /// - Parameters:
    ///   - responseToError: Error callback closure in case of request failure
    ///   - path: Array of Json keys leading to desired Json
    ///   - templateParams: URL templating parameters used for substituion if possible
    ///   - queryItems: array containing `URLQueryItem` objects that will be appended to the request's URL
    ///   - completionHandler: Callback used on completion of operation
    public func responseObject<T: JSONDecodable>(
        responseToError: ((HTTPURLResponse?, Data?) -> Error?)? = nil,
        path: [JSONPathType]? = nil,
        templateParams: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil,
        completionHandler: @escaping (RestResponse<T>) -> Void) {
        let (request, error) = build(templateParams: templateParams, queryItems: queryItems)

        if  let error = error {
            let result = Result<T>.failure(error)
            let dataResponse = RestResponse(request: request, response: nil, data: nil, result: result)
            completionHandler(dataResponse)
            return
        }

        response { data, response, error in

            if let error = error {
                let result = Result<T>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }

            if let responseToError = responseToError,
                let error = responseToError(response, data) {
                let result = Result<T>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
                completionHandler(dataResponse)
                return
            }

            // ensure data is not nil
            guard let data = data else {
                let result = Result<T>.failure(RestError.noData)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }

            // parse json object
            let result: Result<T>
            do {
                let json = try JSON(data: data)
                let object: T
                if let path = path {
                    switch path.count {
                    case 0: object = try json.decode()
                    case 1: object = try json.decode(at: path[0])
                    case 2: object = try json.decode(at: path[0], path[1])
                    case 3: object = try json.decode(at: path[0], path[1], path[2])
                    case 4: object = try json.decode(at: path[0], path[1], path[2], path[3])
                    case 5: object = try json.decode(at: path[0], path[1], path[2], path[3], path[4])
                    default: throw JSON.Error.keyNotFound(key: "ExhaustedVariadicParameterEncoding")
                    }
                } else {
                    object = try json.decode()
                }
                result = .success(object)
            } catch {
                result = .failure(error)
            }

            // execute callback
            let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
            completionHandler(dataResponse)
        }
    }

    /// Request response method with the expected result of an array of type `T` specified
    ///
    /// - Parameters:
    ///   - responseToError: Error callback closure in case of request failure
    ///   - path: Array of Json keys leading to desired Json
    ///   - templateParams: URL templating parameters used for substituion if possible
    ///   - queryItems: array containing `URLQueryItem` objects that will be appended to the request's URL
    ///   - completionHandler: Callback used on completion of operation
    public func responseArray<T: JSONDecodable>(
        responseToError: ((HTTPURLResponse?, Data?) -> Error?)? = nil,
        path: [JSONPathType]? = nil,
        templateParams: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil,
        completionHandler: @escaping (RestResponse<[T]>) -> Void) {

        let (request, error) = build(templateParams: templateParams, queryItems: queryItems)

        if  let error = error {
            let result = Result<[T]>.failure(error)
            let dataResponse = RestResponse(request: request, response: nil, data: nil, result: result)
            completionHandler(dataResponse)
            return
        }

        response { data, response, error in

            if let error = error {
                let result = Result<[T]>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }
            
            if let responseToError = responseToError,
                let error = responseToError(response, data) {
                let result = Result<[T]>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
                completionHandler(dataResponse)
                return
            }

            // ensure data is not nil
            guard let data = data else {
                let result = Result<[T]>.failure(RestError.noData)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }

            // parse json object
            let result: Result<[T]>
            do {
                let json = try JSON(data: data)
                var array: [JSON]
                if let path = path {
                    switch path.count {
                    case 0: array = try json.getArray()
                    case 1: array = try json.getArray(at: path[0])
                    case 2: array = try json.getArray(at: path[0], path[1])
                    case 3: array = try json.getArray(at: path[0], path[1], path[2])
                    case 4: array = try json.getArray(at: path[0], path[1], path[2], path[3])
                    case 5: array = try json.getArray(at: path[0], path[1], path[2], path[3], path[4])
                    default: throw JSON.Error.keyNotFound(key: "ExhaustedVariadicParameterEncoding")
                    }
                } else {
                    array = try json.getArray()
                }
                let objects: [T] = try array.map { json in try json.decode() }
                result = .success(objects)
            } catch {
                result = .failure(error)
            }

            // execute callback
            let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
            completionHandler(dataResponse)
        }
    }

    /// Request response method with the expected result of a `String`
    ///
    /// - Parameters:
    ///   - responseToError: Error callback closure in case of request failure
    ///   - templateParams: URL templating parameters used for substituion if possible
    ///   - queryItems: array containing `URLQueryItem` objects that will be appended to the request's URL
    ///   - completionHandler: Callback used on completion of operation
    public func responseString(
        responseToError: ((HTTPURLResponse?, Data?) -> Error?)? = nil,
        templateParams: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil,
        completionHandler: @escaping (RestResponse<String>) -> Void) {
        let (request, error) = build(templateParams: templateParams, queryItems: queryItems)

        if  let error = error {
            let result = Result<String>.failure(error)
            let dataResponse = RestResponse(request: request, response: nil, data: nil, result: result)
            completionHandler(dataResponse)
            return
        }

        response { data, response, error in

            if let error = error {
                let result = Result<String>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }
            
            if let responseToError = responseToError,
                let error = responseToError(response, data) {
                let result = Result<String>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
                completionHandler(dataResponse)
                return
            }

            // ensure data is not nil
            guard let data = data else {
                let result = Result<String>.failure(RestError.noData)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }

            // parse data as a string
            guard let string = String(data: data, encoding: .utf8) else {
                let result = Result<String>.failure(RestError.serializationError)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }

            // execute callback
            let result = Result.success(string)
            let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
            completionHandler(dataResponse)
        }
    }

    /// Request response method to use when there is no expected result
    ///
    /// - Parameters:
    ///   - responseToError: Error callback closure in case of request failure
    ///   - templateParams: URL templating parameters used for substituion if possible
    ///   - queryItems: array containing `URLQueryItem` objects that will be appended to the request's URL
    ///   - completionHandler: Callback used on completion of operation
    public func responseVoid(
        responseToError: ((HTTPURLResponse?, Data?) -> Error?)? = nil,
        templateParams: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil,
        completionHandler: @escaping (RestResponse<Void>) -> Void) {
        let (request, error) = build(templateParams: templateParams, queryItems: queryItems)

        if  let error = error {
            let result = Result<Void>.failure(error)
            let dataResponse = RestResponse(request: request, response: nil, data: nil, result: result)
            completionHandler(dataResponse)
            return
        }

        response { data, response, error in

            if let error = error {
                let result = Result<Void>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: nil, result: result)
                completionHandler(dataResponse)
                return
            }
            
            if let responseToError = responseToError, let error = responseToError(response, data) {
                let result = Result<Void>.failure(error)
                let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
                completionHandler(dataResponse)
                return
            }

            // execute callback
            let result = Result<Void>.success(())
            let dataResponse = RestResponse(request: request, response: response, data: data, result: result)
            completionHandler(dataResponse)
        }
    }

    /// Utility method to download a file from a remote origin
    ///
    /// - Parameters:
    ///   - destination: URL destination to save the file to
    ///   - completionHandler: Callback used on completion of operation
    public func download(to destination: URL, completionHandler: @escaping (HTTPURLResponse?, Error?) -> Void) {
        let task = session.downloadTask(with: build().0) { (source, response, error) in
            guard let source = source else {
                completionHandler(nil, RestError.invalidFile)
                return
            }
            let fileManager = FileManager.default
            do {
                try fileManager.moveItem(at: source, to: destination)
            } catch {
                completionHandler(nil, RestError.fileManagerError)
            }
            completionHandler(response as? HTTPURLResponse, error)
        }
        task.resume()
    }

    /// Method used by `CircuitBreaker` as the contextCommand
    ///
    /// - Parameter invocation: `Invocation` contains a command argument, Void return type, and a String fallback arguement
    private func handleInvocation(invocation: Invocation<(Data?, HTTPURLResponse?, Error?) -> Void, Void, String>) {
        let (request, _ ) = build()
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                invocation.notifyFailure()
            } else {
                invocation.notifySuccess()
            }
            let callback = invocation.commandArgs
            callback(data, response as? HTTPURLResponse, error)
        }
        task.resume()

    }

    /// Method to perform substitution on `String` URL if it contains templated placeholders
    ///
    /// - Parameter params: dictionary of parameters to substitute in
    /// - Returns: returns either a `RestError` or nil if there were no problems setting new URL on our `URLRequest` object
    private func performSubstitutions(params: [String: String]?) -> RestError? {

        guard let params = params else {
            return nil
        }

        // Get urlTemplate if available, otherwise just use the request's url
        let urlString = urlTemplate ?? url

        guard let urlComponents = urlString.expand(params: params) else {
            return RestError.invalidSubstitution
        }

        url = urlComponents.url?.absoluteString ?? url

        return nil
    }

    /// Builder method to construct a URLRequest
    ///
    /// - Parameters: none
    /// - Returns   : returns the given URLRequest Object
    private func build(templateParams: [String: String]? = nil, queryItems: [URLQueryItem]? = nil) -> (URLRequest, RestError?) {

        let restError: RestError? = performSubstitutions(params: templateParams)

        // construct basic mutable request
        let urlComponents = URLComponents(string: url) ?? URLComponents(string: "")!

        let urlObject = urlComponents.url ?? URL(string: "n/a")!
        var request = URLRequest(url: urlObject)
        request.httpMethod = method.rawValue
        request.httpBody = messageBody

        // set the request's user agent
        if let productInfo = productInfo {
            request.setValue(productInfo.generateUserAgent(), forHTTPHeaderField: "User-Agent")
        }

        // set the request's authentication credentials
        if let credentials = credentials {
            switch credentials {
            case .apiKey: break
            case .basicAuthentication(let username, let password):
                let authData = (username + ":" + password).data(using: .utf8)!
                let authString = authData.base64EncodedString()
                request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
            }
        }

        // modify the url to use the query items
        if  let currentURL = request.url,
            let queryItems = queryItems,
            var urlComponents = URLComponents(url: currentURL, resolvingAgainstBaseURL: false) {

            urlComponents.queryItems = queryItems
            // Must encode "+" to %2B (URLComponents does not do this)
            urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            request.url = urlComponents.url
        }

        // set the request's header parameters
        for (key, value) in headerParameters {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // set the request's accept type
        if let acceptType = acceptType {
            request.setValue(acceptType, forHTTPHeaderField: "Accept")
        }

        // set the request's content type
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        return (request, restError)
    }
}

/// Encapsulates properties needed to initialize a `CircuitBreaker` object within the `RestRequest` init.
/// `A` is the type of the fallback's parameter
public struct CircuitParameters<A> {
    let timeout: Int
    let resetTimeout: Int
    let maxFailures: Int
    let rollingWindow: Int
    let bulkhead: Int
    let fallback: (BreakerError, A) -> Void

    init(timeout: Int = 1000, resetTimeout: Int = 60000, maxFailures: Int = 5, rollingWindow: Int = 10000, bulkhead: Int = 0, fallback: @escaping (BreakerError, A) -> Void) {
        self.timeout = timeout
        self.resetTimeout = resetTimeout
        self.maxFailures = maxFailures
        self.rollingWindow = rollingWindow
        self.bulkhead = bulkhead
        self.fallback = fallback
    }
}

/// Contains data associated with a finished network request.
/// With `T` being the type of the response expected to be received
public struct RestResponse<T> {
    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public let data: Data?
    public let result: Result<T>
}

/// Enum to differentiate a success or failure
///
/// - success: means a success of generic type `T`
/// - failure: means a failure with an `Error` object
public enum Result<T> {
    case success(T)
    case failure(Error)
}

/// Used to specify the type of authentication being used
///
/// - apiKey: means an API key is being used, no additional data needed
/// - basicAuthentication: means a basic username/password authentication is being used with said value, passed in
public enum Credentials {
    case apiKey
    case basicAuthentication(username: String, password: String)
}

/// Error types that can occur during a rest request and response
///
/// - noData: means no data was returned from the network
/// - serializationError: means data couldn't be parsed correctly
/// - encodingError: failure to encode data into a certain format
/// - fileManagerError: failure in file manipulation
/// - invalidFile: the file trying to be accessed is invalid
/// - invalidSubstitution: means a url substitution was attempted that cannot be made
public enum RestError: Error, CustomStringConvertible {
    case noData
    case serializationError
    case encodingError
    case fileManagerError
    case invalidFile
    case invalidSubstitution
    case erroredResponseStatus(String)
    
    public var description: String {
        switch self {
        case .noData                        : return "No Data"
        case .serializationError            : return "Serialization Error"
        case .encodingError                 : return "Encoding Error"
        case .fileManagerError              : return "File Manager Error"
        case .invalidFile                   : return "Invalid File"
        case .invalidSubstitution           : return "Invalid Data"
        case .erroredResponseStatus(let s)  : return "Error HTTP Response: `\(s)`"
        }
    }
}
