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
import KituraNet
import XCTest
import Dispatch
import HeliumLogger
import SwiftyJSON

@testable import BluePicApp

class RouteTests: XCTestCase {

  private let queue = DispatchQueue(label: "Kitura runloop", qos: .userInitiated, attributes: .concurrent)

  private let serverController = try? ServerController()

  private var accessToken: String = ""
    
  private let timeout: TimeInterval = 25.0

  static var allTests : [(String, (RouteTests) -> () throws -> Void)] {
      return [
          ("testPing", testPing),
          ("testGetTags", testGetTags),
          ("testGettingImages", testGettingImages),
          ("testGettingSingleImage", testGettingSingleImage),
          ("testGettingImagesByTag", testGettingImagesByTag),
          ("testPostingImage", testPostingImage),
          ("testGettingImagesForUser", testGettingImagesForUser),
          ("testGettingUsers", testGettingUsers),
          ("testGettingSingleUser", testGettingSingleUser),
          ("testCreatingUser", testCreatingUser),
          ("testPushNotification", testPushNotification)
      ]
  }

  func fileURL(directoriesUp: Int, path: String) -> URL {
    let initialPath = #file
    let components = initialPath.characters.split(separator: "/").map(String.init)
    let notLastFour = components[0..<components.count - directoriesUp]
    let directoryPath = "/" + notLastFour.joined(separator: "/") + "/" + path
    return URL(fileURLWithPath: directoryPath)
  }

  func resetDatabase() {
    
    let task = Process()
    let directoryPath = fileURL(directoriesUp: 4, path: "Cloud-Scripts").relativePath
    
    task.currentDirectoryPath = directoryPath
    task.launchPath = "/bin/bash"
    task.arguments = [directoryPath + "/populator.sh"]
    task.launch()
    task.waitUntilExit()
  }

  override func setUp() {
    super.setUp()

    resetDatabase()

    if self.accessToken == "" {
      let tokenFileName = "authToken"
      let tokenFileURL = fileURL(directoriesUp: 1, path: tokenFileName)

      do {
        let fileContents = try String(contentsOf: tokenFileURL, encoding: .utf8)
        self.accessToken = String(describing: fileContents)
      } catch {
        XCTFail("Could not get authToken from file.")
      }
    }

    HeliumLogger.use()

    XCTAssertNotNil(serverController, "ServerController object is nil and is not getting created properly.")
    Kitura.addHTTPServer(onPort: 8080, with: serverController!.router)

    queue.async {
      Kitura.start()
    }

    print("------------------------------")
    print("------------New Test----------")
    print("------------------------------")
  }

  override func tearDown() {
    Kitura.stop()
  }

  func testPing() {
    
    let pingExpectation = expectation(description: "Hit ping endpoint and get simple text response.")
    
    URLRequest(forTestWithMethod: "GET", route: "ping", authToken: self.accessToken)
      .sendForTestingWithKitura { data in

        let pingResult = String(data: data, encoding: String.Encoding.utf8)
        XCTAssertNotNil(pingResult, "pingResult string is nil, data couldn't be decoded.")
        XCTAssertTrue(pingResult!.contains("Hello World"))
        pingExpectation.fulfill()
    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGetTags() {
    
    let tagExpectation = expectation(description: "Get the top 10 image tags.")
    let expectedResult = ["mountain", "flower", "nature", "bridge", "building", "city", "cloudy sky", "garden", "lake", "person"]

    URLRequest(forTestWithMethod: "GET", route: "tags")
      .sendForTestingWithKitura { data in
        let tags = JSON(data: data)
        for (index, pair) in tags["records"].arrayValue.enumerated() {
          XCTAssertEqual(pair["key"].stringValue, expectedResult[index])
        }
        tagExpectation.fulfill()
    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  // MARK: Image related tests

  func testGettingImages() {

    let imageExpectation = expectation(description: "Get all images.")

    URLRequest(forTestWithMethod: "GET", route: "images")
      .sendForTestingWithKitura { data in

        let images = JSON(data: data)
        let records = images["records"].arrayValue
        XCTAssertEqual(records.count, 9)
        let firstImage = records.first
        XCTAssertNotNil(firstImage, "firstImage is nil within collection of all images.")
        self.assertImage2010(image: firstImage!)
        let lastImage = records.last
        XCTAssertNotNil(lastImage, "lastImage is nil within collection of all images.")
        self.assertImage2001(image: lastImage!)
        imageExpectation.fulfill()

    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingSingleImage() {

    let imageExpectation = expectation(description: "Get an image with a specific image.")

    URLRequest(forTestWithMethod: "GET", route: "images/2010")
      .sendForTestingWithKitura { data in

        let image = JSON(data: data)
        self.assertImage2010(image: image)
        imageExpectation.fulfill()
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingImagesByTag() {

    let imageExpectation = expectation(description: "Get all images with a specific tag.")

    URLRequest(forTestWithMethod: "GET", route: "images?tag=mountain")
      .sendForTestingWithKitura { data in

        let images = JSON(data: data)
        let records = images["records"].arrayValue
        XCTAssertEqual(records.count, 3)
        let image = records.first
        XCTAssertNotNil(image, "First image with tag, mountain, is nil.")
        self.assertImage2010(image: image!)

        // No need to test contents of every image, mainly want to know we got the correct images.
        let imageIds = [2010, 2008, 2003]
        for (index, img) in records.enumerated() {
          XCTAssertEqual(img["_id"].intValue, imageIds[index])
        }
        imageExpectation.fulfill()

    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testPostingImage() {

    let imageExpectation = expectation(description: "Post an image with server.")

    // find image
    let imageFileName = "city.png"
    let imageURL = fileURL(directoriesUp: 4, path: "Cloud-Scripts/Object-Storage/images/city.png")

    let imageDictionary = ["fileName": imageFileName, "caption" : "my caption", "width" : 250, "height" : 300, "location" : ["name" : "Austin, TX", "latitude" : 30.2, "longitude" : -97.7]] as [String : Any]
    let boundary = "Boundary-\(UUID().uuidString)"
    let mimeType = "image/png"

    do {
      let imageData = try Data(contentsOf: imageURL)
      let jsonData = try JSONSerialization.data(withJSONObject: imageDictionary, options: JSONSerialization.WritingOptions(rawValue: 0))
      let url = URL(string: "http://127.0.0.1:8080/images")
      XCTAssertNotNil(url, "Post image URL is nil.")
      var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10.0)
      request.httpMethod = "POST"
      request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
      request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")

      var body = Data()
      guard let boundaryStart = "--\(boundary)\r\n".data(using: String.Encoding.utf8),
        let dispositionEncoding = "Content-Disposition:form-data; name=\"imageJson\"\r\n\r\n".data(using: String.Encoding.utf8),
        let imageDispositionEncoding = "Content-Disposition:form-data; name=\"imageBinary\"; filename=\"\(imageFileName)\"\r\n".data(using: String.Encoding.utf8),
        let imageTypeEncoding = "Content-Type: \(mimeType)\r\n\r\n".data(using: String.Encoding.utf8),
        let imageEndEncoding = "\r\n".data(using: String.Encoding.utf8),
        let boundaryEnd = "--\(boundary)--\r\n".data(using: String.Encoding.utf8) else {
          XCTFail("Post New Image Error: Could not encode all values for multipart data")
          return
      }
      body.append(boundaryStart)
      body.append(dispositionEncoding)
      body.append(jsonData)
      body.append(boundaryStart)
      body.append(imageDispositionEncoding)
      body.append(imageTypeEncoding)
      body.append(imageData)
      body.append(imageEndEncoding)
      body.append(boundaryEnd)
      request.httpBody = body
      
      guard let headers = request.allHTTPHeaderFields else {
        XCTFail("Invalid request params")
        return
      }
      let requestOptions: [ClientRequest.Options] = [.method("POST"), .hostname("localhost"), .port(8080), .path("/images"), .headers(headers)]
      
      let req = HTTP.request(requestOptions) { resp in
        XCTAssertNotNil(resp, "Response came back nil.")
        if let resp = resp {
          XCTAssertNotEqual(resp.statusCode.rawValue, 404)
          XCTAssertEqual(resp.statusCode.rawValue, 200)
        }
        imageExpectation.fulfill()
      }
      req.end(body)

      // Use when URLSession is more reliable on Linux
      /*URLSession(configuration: .default).dataTask(with: request) { data, response, error in
        if let error = error {
          XCTFail("Image Post failed with error: \(error)")
        } else {

          if let httpResponse = response as? HTTPURLResponse {
            XCTAssertNotEqual(httpResponse.statusCode, 404)
            XCTAssertEqual(httpResponse.statusCode, 200)
          } else {
            XCTFail("Bad response from ther server.")
          }

          imageExpectation.fulfill()
        }
      }.resume()*/

    } catch {
      XCTFail("Failed to convert image dictionary to binary data.")
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingImagesForUser() {

    let imageExpectation = expectation(description: "Gets all images posted by a specific user.")

    URLRequest(forTestWithMethod: "GET", route: "users/1001/images", authToken: self.accessToken)
      .sendForTestingWithKitura { data in
        let images = JSON(data: data)
        let records = images["records"].arrayValue
        XCTAssertEqual(records.count, 4)

        let imageIds = [2010, 2007, 2004, 2001]
        for (index, img) in records.enumerated() {
          XCTAssertEqual(img["_id"].intValue, imageIds[index])
        }
        imageExpectation.fulfill()
    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  // MARK: User related tests

  func testGettingUsers() {

    let userExpectation = expectation(description: "Gets all Users.")

    URLRequest(forTestWithMethod: "GET", route: "users", authToken: self.accessToken)
      .sendForTestingWithKitura { data in

        let users = JSON(data: data)
        let records = users["records"].arrayValue
        XCTAssertEqual(records.count, 5)
        let userValues: [(String, String)] = [("anonymous", "Anonymous"), ("1003", "Kevin White"), ("1002", "Sharon den Adel"), ("1001", "Peter Adams"), ("1000", "John Smith")]
        for (index, user) in records.enumerated() {
          XCTAssertEqual(userValues[index].0, user["_id"].stringValue)
          XCTAssertEqual(userValues[index].1, user["name"].stringValue)
          XCTAssertEqual("user", user["type"].stringValue)
        }
        userExpectation.fulfill()
    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingSingleUser() {

    let userExpectation = expectation(description: "Gets a specific User.")

    URLRequest(forTestWithMethod: "GET", route: "users/1003", authToken: self.accessToken)
      .sendForTestingWithKitura { data in

        let user = JSON(data: data)
        XCTAssertEqual(user["_id"].stringValue, "1003")
        XCTAssertEqual(user["name"].stringValue, "Kevin White")
        XCTAssertEqual("user", user["type"].stringValue)
        XCTAssertNotNil(user["_rev"].string)
        userExpectation.fulfill()
    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testCreatingUser() {

    let userExpectation = expectation(description: "Creates a new User.")

    let json = ["_id": "3434", "name": "Tim Billings"]
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
      URLRequest(forTestWithMethod: "POST", route: "users", authToken: self.accessToken, body: jsonData)
        .sendForTestingWithKitura { data in

          let user = JSON(data: data)
          XCTAssertEqual(user["_id"].stringValue, json["_id"])
          XCTAssertEqual(user["name"].stringValue, json["name"])
          XCTAssertEqual(user["type"].stringValue, "user")
          XCTAssertNotNil(user["_rev"].string)
          userExpectation.fulfill()
      }
    } catch {
      XCTFail("Faild to convert dictionary to JSON")
    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testPushNotification() {

    let pushExpectation = expectation(description: "Sends a push notification to a User.")

    // Use when URLSession is more reliable on Linux
    /*let url = URL(string: "http://127.0.0.1:8080/push/images/2010")
    XCTAssertNotNil(url, "Push notification URL for image 2010 is nil.")
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
    request.cachePolicy = .reloadIgnoringLocalCacheData
    URLSession(configuration: .default).dataTask(with: request) { data, response, error in

      XCTAssertNil(error)
      // Only works with physical device, so we expect a bad status
      if let httpResponse = response as? HTTPURLResponse {
        XCTAssertNotEqual(httpResponse.statusCode, 200)
      }
      pushExpectation.fulfill()
    }.resume()*/
    
    var requestOptions: [ClientRequest.Options] = [.method("POST"), .hostname("localhost"), .port(8080), .path("/push/images/2010")]
    var headers = [String:String]()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer \(self.accessToken)"
    requestOptions.append(.headers(headers))
    
    let req = HTTP.request(requestOptions) { resp in
      if let resp = resp {
        XCTAssertEqual(resp.statusCode.rawValue, 200)
      }
      pushExpectation.fulfill()
    }
    req.end(close: true)
    
    waitForExpectations(timeout: timeout, handler: nil)
  }

}

// Used for helper testing methods
extension RouteTests {

  func assertImage2010(image: JSON) {
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
    XCTAssertNotNil(tags.first, "First tag for image 2010 is nil.")
    XCTAssertEqual(tags.first?["confidence"].intValue, 89)
    XCTAssertEqual(tags.first?["label"].stringValue, "road")
    XCTAssertNotNil(tags.last, "Last tag for image 2010 is nil.")
    XCTAssertEqual(tags.last?["confidence"].intValue, 50)
    XCTAssertEqual(tags.last?["label"].stringValue, "mountain")

    let location = image["location"]
    XCTAssertEqual(location["latitude"].stringValue, "34.53")
    XCTAssertEqual(location["longitude"].stringValue, "84.5")
    XCTAssertEqual(location["name"].stringValue, "Austin, Texas")
    XCTAssertEqual(location["weather"]["description"].stringValue, "Mostly Sunny")
    XCTAssertEqual(location["weather"]["iconId"].intValue, 27)
    XCTAssertEqual(location["weather"]["temperature"].intValue, 85)
  }

  func assertImage2001(image: JSON) {
    XCTAssertEqual(image["contentType"].stringValue, "image/png")
    XCTAssertEqual(image["fileName"].stringValue, "bridge.png")
    XCTAssertEqual(image["width"].intValue, 600)
    XCTAssertEqual(image["height"].intValue, 900)
    XCTAssertEqual(image["deviceId"].intValue, 3001)
    XCTAssertEqual(image["_id"].intValue, 2001)
    XCTAssertEqual(image["type"].stringValue, "image")
    XCTAssertEqual(image["uploadedTs"].stringValue, "2016-04-07T16:25:43")
    XCTAssertTrue(image["url"].stringValue.contains("1001/bridge.png"))
    XCTAssertEqual(image["caption"].stringValue, "Bridge")

    let user = image["user"]
    XCTAssertEqual(user["_id"].intValue, 1001)
    XCTAssertEqual(user["name"].stringValue, "Peter Adams")
    XCTAssertEqual(user["type"].stringValue, "user")

    let tags = image["tags"].arrayValue
    XCTAssertNotNil(tags.first, "First tag for image 2001 is nil.")
    XCTAssertEqual(tags.first?["confidence"].intValue, 75)
    XCTAssertEqual(tags.first?["label"].stringValue, "bridge")
    XCTAssertNotNil(tags[1], "Second tag for image 2001 is nil.")
    XCTAssertEqual(tags[1]["confidence"].intValue, 60)
    XCTAssertEqual(tags[1]["label"].stringValue, "city")
    XCTAssertNotNil(tags.last, "Last tag for image 2001 is nil.")
    XCTAssertEqual(tags.last?["confidence"].intValue, 50)
    XCTAssertEqual(tags.last?["label"].stringValue, "building")

    let location = image["location"]
    XCTAssertEqual(location["latitude"].stringValue, "34.53")
    XCTAssertEqual(location["longitude"].stringValue, "84.5")
    XCTAssertEqual(location["name"].stringValue, "Boston, Massachusetts")
    XCTAssertEqual(location["weather"]["description"].stringValue, "Mostly Cloudy")
    XCTAssertEqual(location["weather"]["iconId"].intValue, 27)
    XCTAssertEqual(location["weather"]["temperature"].intValue, 70)
  }

}

private extension URLRequest {

  init(forTestWithMethod method: String, route: String = "", message: String? = nil, authToken: String? = nil, body: Data? = nil) {
    let url = URL(string: "http://127.0.0.1:8080/" + route)
    XCTAssertNotNil(url, "URL is nil, the following route may be invalid: \(route)")
    self.init(url: url!)
    addValue("application/json", forHTTPHeaderField: "Content-Type")
    if let authToken = authToken {
        addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    }
    httpMethod = method
    cachePolicy = .reloadIgnoringCacheData
    if let body = body {
      httpBody = body
    }
  }

  func sendForTesting(fn: @escaping (Data) -> Void ) {
    let dataTask = URLSession(configuration: .default).dataTask(with: self) { data, response, error in
      XCTAssertNil(error)
      XCTAssertNotNil(data)
      switch (response as? HTTPURLResponse)?.statusCode {
        case nil: XCTFail("bad response")
        case 200?:
          XCTAssertNotNil(data, "Data from endpoint is nil.")
          fn(data!)
        case let sc?: XCTFail("bad status \(sc)")
      }
    }
    dataTask.resume()
  }
  
  func sendForTestingWithKitura(fn: @escaping (Data) -> Void) {
    
    guard let method = httpMethod, var path = url?.path, let headers = allHTTPHeaderFields else {
      XCTFail("Invalid request params")
      return
    }
    
    if let query = url?.query {
      path += "?" + query
    }
    
    let requestOptions: [ClientRequest.Options] = [.method(method), .hostname("localhost"), .port(8080), .path(path), .headers(headers)]
    
    let req = HTTP.request(requestOptions) { resp in
        if let resp = resp, resp.statusCode == HTTPStatusCode.OK || resp.statusCode == HTTPStatusCode.accepted {
        do {
          var body = Data()
          try resp.readAllData(into: &body)
          fn(body)
        } catch {
          print("Bad JSON document received from BluePic-Server.")
        }
      } else {
        if let resp = resp {
          print("Status code: \(resp.statusCode)")
          var rawUserData = Data()
          do {
            let _ = try resp.read(into: &rawUserData)
            let str = String(data: rawUserData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            print("Error response from BluePic-Server: \(String(describing: str))")
          } catch {
            print("Failed to read response data.")
          }
        }
      }
    }
    if let dataBody = httpBody {
      req.end(dataBody)
    } else {
      req.end()
    }
    
  }
}
