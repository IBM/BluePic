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

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

import Foundation
import Kitura
import XCTest
import Dispatch
import HeliumLogger
import SwiftyJSON

@testable import BluePicApp

class RouteTests: XCTestCase {
  
  private let queue = DispatchQueue(label: "Kitura runloop", qos: .userInitiated, attributes: .concurrent)

  private let serverController = try? ServerController()

  static var allTests : [(String, (RouteTests) -> () throws -> Void)] {
      return [
          ("testPing", testPing),
          ("testGetTags", testGetTags),
          ("testGettingImages", testGettingImages),
          ("testGettingSingleImage", testGettingSingleImage),
          ("testGettingImagesByTag", testGettingImagesByTag)
      ]
  }
  
  func resetDatabase() {
    #if os(Linux)
    let task = Task()
    #else
    let task = Process()
    #endif
    
    let initialPath = #file
    let components = initialPath.characters.split(separator: "/").map(String.init)
    let notLastThree = components[0..<components.count - 4]
    let directoryPath = "/" + notLastThree.joined(separator: "/") + "/Cloud-Scripts"

    task.currentDirectoryPath = directoryPath
    task.launchPath = "/bin/sh"
    task.arguments = [directoryPath + "/populator.sh"]
    task.launch()
    task.waitUntilExit()
  }
  
  override func setUp() {
    super.setUp()
    
//    resetDatabase()
    
    HeliumLogger.use()
    
    Kitura.addHTTPServer(onPort: 8090, with: serverController!.router)
    
    queue.async {
      Kitura.start()
    }
    
  }
  
  override func tearDown() {
    Kitura.stop()
  }

  func testPing() {
    
    let pingExpectation = expectation(description: "Hit ping endpoint and get simple text response.")
    
    URLRequest(forTestWithMethod: "GET", route: "token")
      .sendForTesting { data in

        let tokenData = JSON(data: data)
        let accessToken = tokenData["access_token"].stringValue
        URLRequest(forTestWithMethod: "GET", route: "ping", authToken: accessToken)
          .sendForTesting { data in
                
            let pingResult = String(data: data, encoding: String.Encoding.utf8)!
            XCTAssertTrue(pingResult.contains("Hello World"))
            pingExpectation.fulfill()
        }
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testGetTags() {
    
    let tagExpectation = expectation(description: "Get the top 10 image tags.")
    let expectedResult = ["mountain", "flower", "nature", "bridge", "building", "city", "cloudy sky", "garden", "lake", "person"]
    
    URLRequest(forTestWithMethod: "GET", route: "tags")
      .sendForTesting { data in
        let tags = JSON(data: data)
        for (index, pair) in tags["records"].arrayValue.enumerated() {
          XCTAssertEqual(pair["key"].stringValue, expectedResult[index])
        }
        tagExpectation.fulfill()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }
  
  func assertUserProperties(image: JSON) {
    XCTAssertEqual(image["contentType"].stringValue, "image/png")
    XCTAssertEqual(image["fileName"].stringValue, "road.png")
    XCTAssertEqual(image["width"].intValue, 600)
    XCTAssertEqual(image["height"].intValue, 402)
    XCTAssertEqual(image["deviceId"].intValue, 3001)
    XCTAssertEqual(image["_id"].intValue, 2010)
    XCTAssertEqual(image["type"].stringValue, "image")
    XCTAssertEqual(image["uploadedTs"].stringValue, "2016-05-05T13:25:43")
    XCTAssertTrue(image["url"].stringValue.contains("1001/road.png"))
    XCTAssertEqual(image["caption"].stringValue, "Road")
    
    let user = image["user"]
    XCTAssertEqual(user["_id"].intValue, 1001)
    XCTAssertEqual(user["name"].stringValue, "Peter Adams")
    XCTAssertEqual(user["type"].stringValue, "user")
    
    let tags = image["tags"].arrayValue
    XCTAssertEqual(tags.first!["confidence"].intValue, 89)
    XCTAssertEqual(tags.first!["label"].stringValue, "road")
    XCTAssertEqual(tags.last!["confidence"].intValue, 50)
    XCTAssertEqual(tags.last!["label"].stringValue, "mountain")
    
    let location = image["location"]
    XCTAssertEqual(location["latitude"].stringValue, "34.53")
    XCTAssertEqual(location["longitude"].stringValue, "84.5")
    XCTAssertEqual(location["name"].stringValue, "Austin, Texas")
    XCTAssertEqual(location["weather"]["description"].stringValue, "Mostly Sunny")
    XCTAssertEqual(location["weather"]["iconId"].intValue, 27)
    XCTAssertEqual(location["weather"]["temperature"].intValue, 85)
  }

  func testGettingImages() {
    
    let imageExpectation = expectation(description: "Get all images.")
    
    URLRequest(forTestWithMethod: "GET", route: "images")
      .sendForTesting { data in
        
        let images = JSON(data: data)
        let records = images["records"].arrayValue
        XCTAssertEqual(records.count, 9)
        let image = records.first!
        self.assertUserProperties(image: image)
        imageExpectation.fulfill()

    }
    waitForExpectations(timeout: 8.0, handler: nil)
  }
  
  func testGettingSingleImage() {
    
    let imageExpectation = expectation(description: "Get an image with a specific image.")
    
    URLRequest(forTestWithMethod: "GET", route: "images/2010")
      .sendForTesting { data in
        
        let image = JSON(data: data)
        self.assertUserProperties(image: image)
        imageExpectation.fulfill()
    }
    
    waitForExpectations(timeout: 8.0, handler: nil)
  }
  
  func testGettingImagesByTag() {
    
    let imageExpectation = expectation(description: "Get all images with a specific tag.")
    
    URLRequest(forTestWithMethod: "GET", route: "images?tag=mountain")
      .sendForTesting { data in
        
        let images = JSON(data: data)
        let records = images["records"].arrayValue
        print("img: \(images)")
        XCTAssertEqual(records.count, 3)
        let image = records.first!
        self.assertUserProperties(image: image)
        imageExpectation.fulfill()
        
    }
    waitForExpectations(timeout: 8.0, handler: nil)
  }
  
  /*func testPostingImage() {
    
    let imageExpectation = expectation(description: "Post an image with server.")
    let fileName = "bluepic-eye.png"
    let initialPath = #file
    let components = initialPath.characters.split(separator: "/").map(String.init)
    let notLastThree = components[0..<components.count - 3]
    let directoryPath = "/" + notLastThree.joined(separator: "/") + "/public/" + fileName
    let image = try? Data(contentsOf: URL(string: directoryPath)!)
    print("IMg: \(image)")
    
    var request = URLRequest(url: URL(string: "http://127.0.0.1:8090/images")!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10.0)
    request.httpMethod = "POST"
    
//    let imageDictionary = ["fileName": image.fileName, "caption" : image.caption, "width" : image.width, "height" : image.height, "location" : ["name" : image.location.name, "latitude" : image.location.latitude, "longitude" : image.location.longitude]] as [String : Any]
    

    waitForExpectations(timeout: 8.0, handler: nil)
  }*/

}

private extension URLRequest {
  
  init(forTestWithMethod method: String, route: String = "", message: String? = nil, authToken: String? = nil) {
    self.init(url: URL(string: "http://127.0.0.1:8090/" + route)!)
    addValue("application/json", forHTTPHeaderField: "Content-Type")
    if let authToken = authToken {
        addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    }
    httpMethod = method
    cachePolicy = .reloadIgnoringCacheData
  }
  
  func sendForTesting(fn: @escaping (Data) -> Void ) {
    let dataTask = URLSession(configuration: .default).dataTask(with: self) {
      data, response, error in
      XCTAssertNil(error)
      XCTAssertNotNil(data)
      switch (response as? HTTPURLResponse)?.statusCode {
        case nil: XCTFail("bad response")
        case 200?: fn(data!)
        case let sc?: XCTFail("bad status \(sc)")
      }
    }
    dataTask.resume()
  }
}
