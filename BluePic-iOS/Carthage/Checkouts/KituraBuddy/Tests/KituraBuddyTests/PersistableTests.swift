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

extension Employee: Persistable {
    // Users of this library should only have to make their 
    // models conform to Persistable protocol by adding this extension
    // and specify the concrete type for the Identifier
    // Note that the Employee structure definition in a real
    // world case would be shared between the server and the client.
    public typealias Id = Int
    
    
}

class PersistableTests: XCTestCase {
    
        static var allTests: [(String, (PersistableTests) -> () throws -> Void)] {
            return [
                ("testCreate", testCreate),
                ("testCreateInvalid", testCreateInvalid),
                ("testRead", testRead),
                ("testReadInvalid", testReadInvalid),
                ("testReadAll", testReadAll),
                ("testUpdate", testUpdate),
                ("testDelete", testDelete),
                ("testDeleteInvalid", testDeleteInvalid),
                ("testDeleteAll", testDeleteAll)
            ]
        }
    
    private let controller = Controller(userStore: initialStore, employeeStore: initialStoreEmployee)
    
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
    
    func testCreate() {
        let expectation1 = expectation(description: "An employee is created successfully.")
        let newEmployee = Employee(id: "5", name: "Kye Maloy")
        
        Employee.create(model: newEmployee) { (emp: Employee?, error: Error?) -> Void in

            guard let emp = emp else {
                XCTFail("Failed to create employee! \(String(describing: error!))")
                return
            }
            
            XCTAssertEqual(newEmployee, emp)
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testCreateInvalid() {
        let expecation1 = expectation(description: "Create fails and returns error because the object already exists.")
        let duplicateEmployee = Employee(id: "1", name: "Mike")
        
        Employee.create(model: duplicateEmployee) { (emp: Employee?, error: Error?) in
            
            guard let error = error else {
                if emp != nil {
                    XCTFail("An employee object was returned erronously")
                    expecation1.fulfill()
                }
                return
            }
            
            //Error is a conflict as the resource already exists.
            XCTAssertEqual(error as? RouteHandlerError, SafetyContracts.RouteHandlerError.conflict)
            expecation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)

    }
    
    func testRead() {
        let expectation1 = expectation(description: "An employee is read successfully.")
        let expectedEmployee = initialStoreEmployee["3".value]
        
        Employee.read(id: 3) { (emp: Employee?, error: Error?) -> Void in

            guard let emp = emp else {
                if error != nil {
                    XCTFail("Failed to read employee! \(error!)")
                    return
                } else {
                    XCTFail("Emp didnt exist, and there was no error returned!")
                    return
                }
            }
            
            XCTAssertEqual(emp, expectedEmployee)
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testReadInvalid() {
        let expectation1 = expectation(description: "Error should be returned as the read is for a non-existent resource.")
        
        Employee.read(id: 102) { (emp: Employee?, error: Error?) in
            
            guard let error = error else {
                if emp != nil {
                    XCTFail("An emp object was returned when it should not have been.")
                }
                return
            }
            
            //Should get bad request error, as the requested item doesn't exist
            XCTAssertEqual(error as? RouteHandlerError, SafetyContracts.RouteHandlerError.badRequest)
            expectation1.fulfill()

        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testReadAll() {

        let expectation1 = expectation(description: "All employees are read successfully.")
        let expectedEmployees = initialStoreEmployee.map({ $0.value })
        
        Employee.read() { (emp: [Employee]?, error: Error?) -> Void in
            
            guard let emp = emp else {
                XCTFail("Failed to read employees! \(error!)")
                return
            }
            XCTAssertEqual(emp, expectedEmployees)
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testUpdate() {
        let expectation1 = expectation(description: "An employee is updated successfully.")
        let newEmployee = Employee(id: "5", name: "Kye Maloy")
        
        Employee.update(id: 5, model: newEmployee) { (emp: Employee?, error: Error?) -> Void in

            guard let emp = emp else {
                XCTFail("Failed to update employees! \(error!)")
                return
            }

            XCTAssertEqual(newEmployee, emp)
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testDelete() {
        let expectation1 = expectation(description: "An employee is deleted successfully.")
        
        Employee.delete(id: 4) { (error: Error?) -> Void in
            
            if let error = error {
                XCTFail("Failed to delete employee! \(error)")
                expectation1.fulfill()
            }
            
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testDeleteInvalid() {
        let expectation1 = expectation(description: "Should return error because the item to delete doesn't exist.")

        Employee.delete(id: 999) { (error: Error?) in

            guard let error = error else {
                XCTFail("No error was returned, when it should have been")
                return
            }
            
            XCTAssertEqual(error as? RouteHandlerError, SafetyContracts.RouteHandlerError.notFound)
            expectation1.fulfill()

        }

        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testDeleteAll() {
        let expectation1 = expectation(description: "All employees are deleted successfully.")
        
        Employee.delete() { (error: Error?) -> Void in
            
             if let error = error {
                XCTFail("Failed to delete all employees! \(error)")
                expectation1.fulfill()
            }

            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
}
