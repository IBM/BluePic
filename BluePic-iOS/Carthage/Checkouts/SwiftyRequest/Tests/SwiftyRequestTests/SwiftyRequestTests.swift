import XCTest
import CircuitBreaker
@testable import SwiftyRequest

/// URL for the weather underground that many of the tests use
let apiKey = "96318a1fc52412b1" // We don't know if API Key for the wunderground API could expire at some point...
let apiURL = "http://api.wunderground.com/api/\(apiKey)/conditions/q/CA/San_Francisco.json"
let geolookupURL = "http://api.wunderground.com/api/\(apiKey)/geolookup/q/CA/San_Francisco.json"
let templetedAPIURL = "http://api.wunderground.com/api/\(apiKey)/conditions/q/{state}/{city}.json"

// MARK: Helper structs

// The following structs are made to work with the weather undeground API,
// to provide a concrete object when using response methods with generic type results
public struct WeatherResponse: JSONDecodable {

    public let json: [String: Any]

    public init(json: JSON) throws {
        self.json = try json.getDictionaryObject()
    }
}

public struct GeoLookupModel: JSONDecodable {
    public let city: String
    public let state: String
    public let country: String
    public let icao: String
    public let lat: String
    public let lon: String

    public init(json: JSON) throws {
        city = try json.getString(at: "city")
        state = try json.getString(at: "state")
        country = try json.getString(at: "country")
        icao = try json.getString(at: "icao")
        lat = try json.getString(at: "lat")
        lon = try json.getString(at: "lon")
    }
}

class SwiftyRequestTests: XCTestCase {

    static var allTests = [
        ("testResponseData", testResponseData),
        ("testResponseObject", testResponseObject),
        ("testResponseArray", testResponseArray),
        ("testResponseString", testResponseString),
        ("testResponseVoid", testResponseVoid),
        ("testFileDownload", testFileDownload),
        ("testRequestUserAgent", testRequestUserAgent),
        ("testCircuitBreakResponseString", testCircuitBreakResponseString),
        ("testCircuitBreakFailure", testCircuitBreakFailure),
        ("testURLTemplateDataCall", testURLTemplateDataCall),
        ("testURLTemplateNoParams", testURLTemplateNoParams),
        ("testURLTemplateNoTemplateValues", testURLTemplateNoTemplateValues),
        ("testQueryParamUpdating", testQueryParamUpdating),
        ("testQueryTemplateParams", testQueryTemplateParams)
    ]

    // MARK: Helper methods

    private func responseToError(response: HTTPURLResponse?, data: Data?) -> Error? {

        // First check http status code in response
        if let response = response {
            if response.statusCode >= 200 && response.statusCode < 300 {
                return nil
            }
        }

        // ensure data is not nil
        guard let data = data else {
            if let code = response?.statusCode {
                print("Data is nil with response code: \(code)")
                return RestError.noData
            }
            return nil  // SwiftyRequest will generate error for this case
        }

        do {
            let json = try JSON(data: data)
            let message = try json.getString(at: "error")
            print("Failed with error: \(message)")
            return RestError.serializationError
        } catch {
            return nil
        }
    }

    let failureFallback = { (error: BreakerError, msg: String) in
        // If this fallback is accessed, we consider it a failure
        XCTFail("Test opened the circuit and we are in the failure fallback.")
    }

    // MARK: SwiftyRequest Tests

    // API Key (96318a1fc52412b1) for the wunderground API may expire at some point.
    // If this happens, use a different endpoint to test SwiftyRequest with.
    func testResponseData() {

        let expectation = self.expectation(description: "responseData SwiftyRequest test")

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey

        request.responseData { response in
            switch response.result {
            case .success(let retval):
                XCTAssertGreaterThan(retval.count, 0)
            case .failure(let error):
                XCTFail("Failed to get weather response data with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    func testResponseObject() {

        let expectation = self.expectation(description: "responseObject SwiftyRequest test")

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey
        request.acceptType = "application/json"

        request.responseObject(responseToError:  responseToError) { (response: RestResponse<WeatherResponse>) in
            switch response.result {
            case .success(let retval):
                XCTAssertGreaterThan(retval.json.count, 0)
            case .failure(let error):
                XCTFail("Failed to get weather response object with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    func testResponseArray() {

        let expectation = self.expectation(description: "responseArray SwiftyRequest test")

        let request = RestRequest(url: geolookupURL)
        request.credentials = .apiKey

        request.responseArray(responseToError: responseToError,
                              path: ["location", "nearby_weather_stations", "airport", "station"]) { (response: RestResponse<[GeoLookupModel]>) in
            switch response.result {
            case .success(let retval):
                XCTAssertGreaterThan(retval.count, 0)
                XCTAssertGreaterThan(retval[0].city.characters.count, 0)
            case .failure(let error):
                XCTFail("Failed to get weather response array with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    func testResponseString() {

        let expectation = self.expectation(description: "responseString SwiftyRequest test")

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey

        request.responseString(responseToError: responseToError) { response in
            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.characters.count, 0)
            case .failure(let error):
                XCTFail("Failed to get weather response String with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    func testResponseVoid() {

        let expectation = self.expectation(description: "responseVoid SwiftyRequest test")

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey

        request.responseVoid(responseToError: responseToError) { response in
            switch response.result {
            case .failure(let error):
                XCTFail("Failed to get weather response Void with error: \(error)")
            default: ()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    func testFileDownload() {

        let expectation = self.expectation(description: "download file SwiftyRequest test")

        let url = "https://raw.githubusercontent.com/watson-developer-cloud/swift-sdk/master/Tests/DiscoveryV1Tests/metadata.json"

        let request = RestRequest(url: url)
        request.credentials = .apiKey

        let bundleURL = URL(fileURLWithPath: "/tmp")
        let destinationURL = bundleURL.appendingPathComponent("tempFile.html")

        request.download(to: destinationURL) { response, error in
            XCTAssertNil(error) // if error not nil, url may point to missing resource
            XCTAssertNotNil(response)
            XCTAssertEqual(response?.statusCode, 200)

            do {
                // Clean up downloaded file
                let fm = FileManager.default
                try fm.removeItem(at: destinationURL)
            } catch {
                XCTFail("Failed to remove downloaded file with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func testRequestUserAgent() {

        let expectation = self.expectation(description: "responseString SwiftyRequest test with userAgent string")

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey
        request.productInfo = "swiftyrequest-sdk/0.2.0"

        request.responseString(responseToError: responseToError) { response in

            XCTAssertNotNil(response.request?.allHTTPHeaderFields)
            if let headers = response.request?.allHTTPHeaderFields {
                XCTAssertNotNil(headers["User-Agent"])
                XCTAssertEqual(headers["User-Agent"], "swiftyrequest-sdk/0.2.0".generateUserAgent())
            }

            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.characters.count, 0)
            case .failure(let error):
                XCTFail("Failed to get weather response String with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    // MARK: Circuit breaker integration tests

    func testCircuitBreakResponseString() {

        let expectation = self.expectation(description: "CircuitBreaker success test")

        let circuitParameters = CircuitParameters(fallback: failureFallback)

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey
        request.circuitParameters = circuitParameters

        request.responseString(responseToError: responseToError) { response in
            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.characters.count, 0)
            case .failure(let error):
                XCTFail("Failed to get weather response String with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    func testCircuitBreakFailure() {

        let expectation = self.expectation(description: "CircuitBreaker max failure test")
        let resetTimeout = 3000
        let maxFailures = 2
        var count = 0
        var fallbackCalled = false

        let breakFallback = { (error: BreakerError, msg: String) in
            XCTAssertEqual(count, maxFailures)
            fallbackCalled = true
        }
        let circuitParameters = CircuitParameters(resetTimeout: resetTimeout, maxFailures: maxFailures, fallback: breakFallback)

        let request = RestRequest(url: "http://notreal/blah")
        request.credentials = .apiKey
        request.circuitParameters = circuitParameters

        let completionHandler = { (response: (RestResponse<String>)) in

            if fallbackCalled {
                expectation.fulfill()
            } else {
                count += 1
                XCTAssertLessThanOrEqual(count, maxFailures)
            }
        }

        // Make multiple requests and ensure the correct callbacks are activated
        request.responseString(responseToError: responseToError) { [unowned self] (response: RestResponse<String>) in
            completionHandler(response)

            request.responseString(responseToError: self.responseToError, completionHandler: { [unowned self] (response: RestResponse<String>) in
                completionHandler(response)

                request.responseString(responseToError: self.responseToError, completionHandler: completionHandler)
                sleep(UInt32(resetTimeout/1000) + 1)
                request.responseString(responseToError: self.responseToError, completionHandler: completionHandler)
            })
        }

        waitForExpectations(timeout: Double(resetTimeout + 10))

    }

    // MARK: Substitution Tests

    func testURLTemplateDataCall() {

        let expectation = self.expectation(description: "URL templating and substitution test")

        let circuitParameters = CircuitParameters(fallback: failureFallback)

        let request = RestRequest(url: templetedAPIURL)
        request.credentials = .apiKey
        request.circuitParameters = circuitParameters

        let completionHandlerThree = { (response: (RestResponse<Data>)) in

            switch response.result {
            case .success(_):
                XCTFail("Request should have failed with only using one parameter for 2 template spots.")
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, RestError.invalidSubstitution.localizedDescription)
            }
            expectation.fulfill()
        }

        let completionHandlerTwo = { (response: (RestResponse<Data>)) in

            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.count, 0)
                let str = String(data: result, encoding: String.Encoding.utf8)
                XCTAssertNotNil(str)
                XCTAssertGreaterThan(str!.characters.count, 0)
                // Excluding state from templateParams should cause error
                request.responseData(templateParams: ["city": "Dallas"], completionHandler: completionHandlerThree)
            case .failure(let error):
                XCTFail("Failed to get weather response String with error: \(error)")
            }
        }

        let completionHandlerOne = { (response: (RestResponse<Data>)) in
            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.count, 0)
                let str = String(data: result, encoding: String.Encoding.utf8)
                XCTAssertNotNil(str)
                XCTAssertGreaterThan(str!.characters.count, 0)

                request.responseData(templateParams: ["state": "TX", "city": "Austin"], completionHandler: completionHandlerTwo)
            case .failure(let error):
                XCTFail("Failed to get weather response String with error: \(error)")
            }
        }

        // Test starts here and goes up (this is to avoid excessive nesting of async code)
        // Test basic substitution and multiple substitutions
        request.responseData(templateParams: ["state": "CA", "city": "San_Francisco"], completionHandler: completionHandlerOne)

        waitForExpectations(timeout: 10)

    }

    func testURLTemplateNoParams() {

        let expectation = self.expectation(description: "URL substitution test with no substitution params")

        let circuitParameters = CircuitParameters(fallback: failureFallback)

        let request = RestRequest(url: templetedAPIURL)
        request.credentials = .apiKey
        request.circuitParameters = circuitParameters

        request.responseData { response in
            switch response.result {
            case .success(_):
                XCTFail("Request should have failed with no parameters passed into a templated URL")
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "unsupported URL")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    func testURLTemplateNoTemplateValues() {

        let expectation = self.expectation(description: "URL substitution test with no template values to replace, API call should still succeed")

        let circuitParameters = CircuitParameters(fallback: failureFallback)

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey
        request.circuitParameters = circuitParameters

        request.responseData(templateParams: ["state": "CA", "city": "San_Francisco"]) { response in
            switch response.result {
            case .success(let retVal):
                XCTAssertGreaterThan(retVal.count, 0)
            case .failure(let error):
                XCTFail("Failed to get weather response data with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

    // MARK: Query parameter tests

    func testQueryParamUpdating() {

        let expectation = self.expectation(description: "Test setting, modifying, and removing URL query parameters")

        let circuitParameters = CircuitParameters(fallback: failureFallback)
        let initialQueryItems = [URLQueryItem(name: "friend", value: "bill")]

        let request = RestRequest(url: apiURL)
        request.credentials = .apiKey
        request.circuitParameters = circuitParameters

        // verify query has many parameters
        let completionHandlerFour = { (response: (RestResponse<Data>)) in
            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.count, 0)
                XCTAssertNotNil(response.request?.url?.query)
                if let queryItems = response.request?.url?.query {
                    XCTAssertEqual(queryItems, "friend=brian&friend=george&friend=melissa%2Btempe&friend=mika")
                }
            case .failure(let error):
                XCTFail("Failed to get weather response data with error: \(error)")
            }
            expectation.fulfill()
        }

        // verify query was set to nil
        let completionHandlerThree = { (response: (RestResponse<Data>)) in
            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.count, 0)
                XCTAssertNil(response.request?.url?.query)
                let queryItems = [URLQueryItem(name: "friend", value: "brian"), URLQueryItem(name: "friend", value: "george"), URLQueryItem(name: "friend", value: "melissa+tempe"), URLQueryItem(name: "friend", value: "mika")]
                request.responseData(queryItems: queryItems, completionHandler: completionHandlerFour)
            case .failure(let error):
                XCTFail("Failed to get weather response data with error: \(error)")
            }
        }

        // verify query value changed and was encoded properly
        let completionHandlerTwo = { (response: (RestResponse<Data>)) in
            switch response.result {
            case .success(let result):
                XCTAssertGreaterThan(result.count, 0)
                XCTAssertNotNil(response.request?.url?.query)
                if let queryItems = response.request?.url?.query {
                    XCTAssertEqual(queryItems, "friend=darren%2Bfink")
                }
                request.responseData(completionHandler: completionHandlerThree)
            case .failure(let error):
                XCTFail("Failed to get weather response data with error: \(error)")
            }
        }

        // verfiy query value could be set
        let completionHandlerOne = { (response: (RestResponse<Data>)) in
            switch response.result {
            case .success(let retVal):
                XCTAssertGreaterThan(retVal.count, 0)
                XCTAssertNotNil(response.request?.url?.query)
                if let queryItems = response.request?.url?.query {
                    XCTAssertEqual(queryItems, "friend=bill")
                }

                request.responseData(queryItems: [URLQueryItem(name: "friend", value: "darren+fink")], completionHandler: completionHandlerTwo)
            case .failure(let error):
                XCTFail("Failed to get weather response data with error: \(error)")
            }
        }

        request.responseData(queryItems: initialQueryItems, completionHandler: completionHandlerOne)

        waitForExpectations(timeout: 10)

    }

    func testQueryTemplateParams() {

        let expectation = self.expectation(description: "Testing URL template and query parameters used together")

        let circuitParameters = CircuitParameters(fallback: failureFallback)

        let request = RestRequest(url: templetedAPIURL)
        request.credentials = .apiKey
        request.circuitParameters = circuitParameters

        request.responseData(templateParams: ["state": "TX", "city": "Austin"], queryItems: [URLQueryItem(name: "friend", value: "bill")]) { response in
            switch response.result {
            case .success(let retVal):
                XCTAssertGreaterThan(retVal.count, 0)
                XCTAssertNotNil(response.request?.url?.query)
                if let queryItems = response.request?.url?.query {
                    XCTAssertEqual(queryItems, "friend=bill")
                }
            case .failure(let error):
                XCTFail("Failed to get weather response data with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)

    }

}
