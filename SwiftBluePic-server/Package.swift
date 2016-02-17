
import PackageDescription

let package = Package(
    name: "SwiftBluePic-server",
          dependencies: [
               .Package(url: "git@github.com:IBM-Swift/Kitura-router.git", majorVersion: 0),
               .Package(url: "git@github.com:IBM-Swift/Kitura-CouchDB.git", majorVersion: 0),
               .Package(url: "git@github.com:IBM-Swift/Kitura-redis.git", majorVersion: 0),
          ]
)

