import PackageDescription

let package = Package(
  name: "CircuitBreaker",
  dependencies: [
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", majorVersion: 1)
  ]
)
