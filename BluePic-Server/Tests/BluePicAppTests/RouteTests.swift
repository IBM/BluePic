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
import SwiftyRequest

@testable import BluePicApp

class RouteTests: XCTestCase {

  private let serverController = try? ServerController()

  private var accessToken: String = ""

  private let timeout: TimeInterval = 25.0

  static var allTests: [(String, (RouteTests) -> () throws -> Void)] {
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
          ("testNewUser", testNewUser),
          ("testPushNotification", testPushNotification)
      ]
  }

  func fileURL(directoriesUp: Int, path: String) -> URL {
    let initialPath = #file
    let components = initialPath.split(separator: "/").map(String.init)
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

    Kitura.start()

    print("------------------------------")
    print("------------New Test----------")
    print("------------------------------")
  }

  override func tearDown() {
    Kitura.stop()
  }

  private func handleError(_ err: Error) {
    print("Error response from BluePic-Server: \(String(describing: err))")
    XCTFail()
  }

  func testPing() {

    let pingExpectation = expectation(description: "Hit ping endpoint and get simple text response.")

    let req = RestRequest(route: "/ping", authToken: accessToken)

    req.responseString { response in
      switch response.result {
      case .success(let str):
        XCTAssertTrue(str.contains("Hello World"))
        pingExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGetTags() {

    let tagExpectation = expectation(description: "Get the top 10 image tags.")
    let expectedResult = ["mountain", "flower", "nature", "bridge", "building",
                          "city", "cloudy sky", "garden", "lake", "person"]
    let req = RestRequest(method: .get, route: "/tags")

    req.responseData { res in
      switch res.result {
      case .success(let data):
        let tags = SwiftyJSON.JSON(data: data)
        for (index, pair) in tags["records"].arrayValue.enumerated() {
          XCTAssertEqual(pair["key"].stringValue, expectedResult[index])
        }
        tagExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  // MARK: Image related tests

  func testGettingImages() {

    let imageExpectation = expectation(description: "Get all images.")
    let req = RestRequest(method: .get, route: "/images")

    req.responseData { res in
      switch res.result {
      case .success(let data):
        let images = SwiftyJSON.JSON(data: data)
        let records = images.arrayValue
        XCTAssertEqual(records.count, 9)
        let firstImage = records.first
        XCTAssertNotNil(firstImage, "firstImage is nil within collection of all images.")
        self.assertImage2010(image: firstImage!)
        let lastImage = records.last
        XCTAssertNotNil(lastImage, "lastImage is nil within collection of all images.")
        self.assertImage2001(image: lastImage!)
        imageExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingSingleImage() {

    let imageExpectation = expectation(description: "Get an image with a specific image.")

    let req = RestRequest(method: .get, route: "/images/2010")

    req.responseData { res in
      switch res.result {
      case .success(let data):
        let image = SwiftyJSON.JSON(data: data)
        self.assertImage2010(image: image)
        imageExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingImagesByTag() {

    let imageExpectation = expectation(description: "Get all images with a specific tag.")

    let req = RestRequest(method: .get, route: "/images/tag/mountain")

    req.responseData { res in
      switch res.result {
      case .success(let data):
        let images = SwiftyJSON.JSON(data: data)
        let records = images.arrayValue
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
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testPostingImage() {

    let imageExpectation = expectation(description: "Post an image with server.")

    let image = Img(fileName: "unique.png",
                      caption: "my caption",
                      width: 250,
                      height: 300,
                      userId: "anonymous",
                      image: Data())

    let req = RestRequest(method: .post, route: "/images", authToken: self.accessToken)

    req.messageBody = try? JSONEncoder().encode(image)

    req.responseData { resp in
      switch resp.result {
      case .success(_): imageExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingImagesForUser() {

    let imageExpectation = expectation(description: "Gets all images posted by a specific user.")

    let req = RestRequest(route: "/users/1001/images", authToken: self.accessToken)

    req.responseData { resp in

      switch resp.result {
      case .success(let data):
        let images = SwiftyJSON.JSON(data: data)
        let records = images.arrayValue
        XCTAssertEqual(records.count, 4)

        let imageIds = [2010, 2007, 2004, 2001]
        for (index, img) in records.enumerated() {
          XCTAssertEqual(img["_id"].intValue, imageIds[index])
        }
        imageExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  // MARK: User related tests

  func testGettingUsers() {

    let userExpectation = expectation(description: "Gets all Users.")

    let req = RestRequest(route: "/users", authToken: self.accessToken)

    req.responseData { resp in
      switch resp.result {
      case .success(let data):
        let users = SwiftyJSON.JSON(data: data)
        let records = users.arrayValue
        XCTAssertEqual(records.count, 5)
        let userValues: [(String, String)] = [
          ("anonymous", "Anonymous"),
          ("1003", "Kevin White"),
          ("1002", "Sharon den Adel"),
          ("1001", "Peter Adams"),
          ("1000", "John Smith")
        ]
        for (index, user) in records.enumerated() {
          XCTAssertEqual(userValues[index].0, user["_id"].stringValue)
          XCTAssertEqual(userValues[index].1, user["name"].stringValue)
          XCTAssertEqual("user", user["type"].stringValue)
        }
        userExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testGettingSingleUser() {

    let userExpectation = expectation(description: "Gets a specific User.")

    let req = RestRequest(route: "/users/1003", authToken: self.accessToken)

    req.responseData { resp in
      switch resp.result {
      case .success(let data):
        let user = SwiftyJSON.JSON(data: data)
        XCTAssertEqual(user["_id"].stringValue, "1003")
        XCTAssertEqual(user["name"].stringValue, "Kevin White")
        XCTAssertEqual("user", user["type"].stringValue)
        XCTAssertNotNil(user["_rev"].string)
        userExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testNewUser() {

    let userExpectation = expectation(description: "Creates a new User.")

    let usr = User(id: "3434", name: "Time Billings")

    guard let jsonData = try? JSONEncoder().encode(usr) else {
      XCTFail()
      return
    }

    let req = RestRequest(method: .post, route: "/users", authToken: self.accessToken)
    req.messageBody = jsonData

    req.responseData { resp in
      switch resp.result {
      case .success(let data):
        let user = SwiftyJSON.JSON(data: data)
        XCTAssertEqual(user["_id"].stringValue, usr.id)
        XCTAssertEqual(user["name"].stringValue, usr.name)
        XCTAssertEqual(user["type"].stringValue, "user")
        XCTAssertNotNil(user["_rev"].string)
        userExpectation.fulfill()
      case .failure(let err): self.handleError(err)
      }
    }

    waitForExpectations(timeout: timeout, handler: nil)
  }

  func testPushNotification() {

    let pushExpectation = expectation(description: "Sends a push notification to a User.")

    let req = RestRequest(method: .post, route: "/push/images/2010", authToken: self.accessToken)

    req.responseData { response in
      switch response.result {
      case .success(let data):
        guard let status = try? JSONDecoder().decode(NotificationStatus.self, from: data) else {
          XCTFail()
          return
        }

        status.status ? pushExpectation.fulfill() : XCTFail()

      case .failure(let err): self.handleError(err)
      }
    }
    waitForExpectations(timeout: timeout, handler: nil)
  }

}

// Used for helper testing methods
extension RouteTests {

  func assertImage2010(image: SwiftyJSON.JSON) {
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

  func assertImage2001(image: SwiftyJSON.JSON) {
    print("============")
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

struct Img: Codable {
  let fileName: String
  let caption: String
  let width: Double
  let height: Double
  let userId: String
  let image: Data
}

private extension RestRequest {
  convenience init(method: HTTPMethod = .get, route: String = "", authToken: String? = nil) {
    self.init(method: method, url: "http://127.0.0.1:8080" + route)
    var headers = [String: String]()
    if let authToken = authToken {
      headers["Authorization"] = "Bearer \(authToken)"
    }
    headerParameters = headers
  }
}
