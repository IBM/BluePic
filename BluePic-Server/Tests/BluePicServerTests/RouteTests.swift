/**
 * Copyright IBM Corporation 2016
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
import Kitura
import XCTest
import Dispatch
import HeliumLogger
import SwiftyJSON

//@testable import Server

class RouteTests: XCTestCase {
    
    private let queue = DispatchQueue(label: "Kitura runloop", qos: .userInitiated, attributes: .concurrent)
    
    // test get tags, images, images by ID,
    
    static var allTests : [(String, (RouteTests) -> () throws -> Void)] {
        return [
            ("testGetTags", testGetTags)
        ]
    }
    
    override func setUp() {
        super.setUp()
        
        HeliumLogger.use()
        
        Kitura.addHTTPServer(onPort: 8090, with: Router())
        
        queue.async {
            Kitura.run()
        }
        
    }
    
    func testGetTags() {
        
        let tagExpectation = expectation(description: "Get the top 10 image tags.")
        
        URLRequest(forTestWithMethod: "GET", route: "tags")
        .sendForTesting(expectation: tagExpectation) { data, expectation in
            print("The data: \(data)")
            print(String(data: data, encoding: String.Encoding.utf8)!)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0) { error in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }

}

private extension URLRequest {
    
    init(forTestWithMethod method: String, route: String = "", message: String? = nil) {
        self.init(url: URL(string: "http://127.0.0.1:8090/" + route)!)
        addValue("application/json", forHTTPHeaderField: "Content-Type")
        httpMethod = method
        cachePolicy = .reloadIgnoringCacheData
    }
    
    func sendForTesting(expectation: XCTestExpectation,  fn: @escaping (Data, XCTestExpectation) -> Void ) {
        let dataTask = URLSession(configuration: .default).dataTask(with: self) {
            data, response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data)
            switch (response as? HTTPURLResponse)?.statusCode {
                case nil: XCTFail("bad response")
                case 200?: fn(data!, expectation)
                case let sc?: XCTFail("bad status \(sc)")
            }
        }
        dataTask.resume()
    }
}
