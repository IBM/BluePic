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

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import XCTest
import Foundation
import Kitura
import SafetyContracts

@testable import KituraBuddy

class MainTests: XCTestCase {

    static var allTests: [(String, (MainTests) -> () throws -> Void)] {
        return [
            ("testClientGet", testClientGet),
            ("testClientGetErrorPath", testClientGetErrorPath),
            ("testClientGetSingle", testClientGetSingle),
            ("testClientGetSingleErrorPath", testClientGetSingleErrorPath),
            ("testClientPost", testClientPost),
            ("testClientPostErrorPath", testClientPostErrorPath),
            ("testClientPut", testClientPut),
            ("testClientPutErrorPath", testClientPutErrorPath),
            ("testClientPatch", testClientPatch),
            ("testClientPatchErrorPath", testClientPatchErrorPath),
            ("testClientDelete", testClientDelete),
            ("testClientDeleteSingle", testClientDeleteSingle)
        ]
    }

    private let controller = Controller(userStore: initialStore)

    private let client = KituraBuddy(baseURL: "http://localhost:8080")

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        Kitura.addHTTPServer(onPort: 8080, with: controller.router)
        Kitura.start()

    }

    override func tearDown() {
        Kitura.stop()
        super.tearDown()
    }

    // TODO: See test cases we implemented for Kitura-Starter (we may need something similar)
    // https://github.com/IBM-Bluemix/Kitura-Starter/blob/master/Tests/ControllerTests/RouteTests.swift
    // I don't see a way to specify test-only dependencies... they removed this capability
    // Hence, we may need to add Kitura as a dependency just for testing...
    // :-/ Not good to have to add a dependency to Package.swift when it is only neede for testing... but
    // that may be the option unless we want to mockup our own server, which may create unnecessary work for us.

    // Note that as of now, given how the tests are written, they will fail, UNLESS you have a kitura server running
    // locally that can process the requests.
    // Let's fully automated the test cases.

    func testClientGet() {
        let expectation1 = expectation(description: "A response is received from the server -> array of users")

        // Invoke GET operation on library
        client.get("/users") { (users: [User]?, error: Error?) -> Void in
            guard let users = users else {
                XCTFail("Failed to get users! Error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(users.count, 4)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testClientGetErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")
        
        // Invoke GET operation on library
        client.get("/notAValidRoute") { (users: [User]?, error: Error?) -> Void in
            if let err = error as? RouteHandlerError, case .notFound = err {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error from server: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientGetSingle() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        // Invoke GET operation on library
        let id = "1"
        client.get("/users", identifier: id) { (user: User?, error: Error?) -> Void in
            guard let user = user else {
                XCTFail("Failed to get user! Error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(user, initialStore[id]!)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testClientGetSingleErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")
        
        // Invoke GET operation on library
        let id = "1"
        client.get("/notAValidRoute", identifier: id) { (users: User?, error: Error?) -> Void in
            if let err = error as? RouteHandlerError, case .notFound = err {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error from server: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPost() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        // Invoke POST operation on library
        let newUser = User(id: 5, name: "John Doe")

        client.post("/users", data: newUser) { (user: User?, error: Error?) -> Void in
            guard let user = user else {
                XCTFail("Failed to post user! Error: \(String(describing: error))")
                return
            }

            XCTAssertEqual(user, newUser)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testClientPostErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")
        
        // Invoke POST operation on library
        let newUser = User(id: 5, name: "John Doe")
        
        client.post("/notAValidRoute", data: newUser) { (users: User?, error: Error?) -> Void in
            if let err = error as? RouteHandlerError, case .notFound = err {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get user! Error: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPut() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        // Invoke PUT operation on library
        let expectedUser = User(id: 5, name: "John Doe")

        client.put("/users", identifier: String(expectedUser.id), data: expectedUser) { (user: User?, error: Error?) -> Void in

            guard let user = user else {
                XCTFail("Failed to put user! Error: \(String(describing: error))")
                return
            }

            XCTAssertEqual(user, expectedUser)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testClientPutErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")
        
        // Invoke PUT operation on library
        let expectedUser = User(id: 5, name: "John Doe")
        
        client.put("/notAValidRoute", identifier: String(expectedUser.id), data: expectedUser) { (users: User?, error: Error?) -> Void in
            if let err = error as? RouteHandlerError, case .notFound = err {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get user! Error: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testClientPatch() {
        let expectation1 = expectation(description: "A response is received from the server -> user")

        let expectedUser = User(id: 5, name: "John Doe")

        client.patch("/users", identifier: String(expectedUser.id), data: expectedUser) { (user: User?, error: Error?) -> Void in
            guard let user = user else {
                XCTFail("Failed to patch user! Error: \(String(describing: error))")
                return
            }

            XCTAssertEqual(user, expectedUser)

            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testClientPatchErrorPath() {
        let expectation1 = expectation(description: "An error is received from the server")        
        let expectedUser = User(id: 5, name: "John Doe")
        
        client.patch("/notAValidRoute", identifier: String(expectedUser.id), data: expectedUser) { (users: User?, error: Error?) -> Void in
            if let err = error as? RouteHandlerError, case .notFound = err {
                expectation1.fulfill()
            } else {
                XCTFail("Failed to get expected error from server: \(String(describing: error))")
                return
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

     func testClientDeleteSingle() {
        // Updated our library API since noticed that in the delete use cases,
        // the user had no idea if his/her request failed or succeeded.
        // See the changes below... with this chance, now the user gets an error
        // in the closure if there was an error.
        // Given this, we may need to adopt passing an Error object back to the user
        // whenerver an error occurs in the other API methods as well just to be consistent.
        let expectation1 = expectation(description: "No error is received from the server")

        // Invoke GET operation on library
        client.delete("/users", identifier: "0") { error in
            guard error == nil else {
                XCTFail("Failed to delete user! Error: \(String(describing: error))")
                return
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    // delete tests get executed first and cause get individual user tests to fail as the users have been deleted

    func testClientDelete() {
        let expectation1 = expectation(description: "No error is received from the server")

        client.delete("/users") { error in
            guard error == nil else {
                XCTFail("Failed to delete user! Error: \(String(describing: error))")
                return
            }
            
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
//     Commenting out this test case for now...
//     There seems to be a defect in the SwiftyRequest repo
//     Aaron is looking into this. Stay tuned!
//     func testClientDeleteInvalid() {
//         let expectation1 = expectation(description: "An error is received from the server")
//
//         client.delete("/notAValidRoute") { error in
//             guard error == nil else {
//                 expectation1.fulfill()
//                 return
//             }
//             XCTFail("Deleted user, but it doesn't exist! Error: \(String(describing: error))")
//             expectation1.fulfill()
//         }
//         waitForExpectations(timeout: 3.0, handler: nil)
//     }


}
