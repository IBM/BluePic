struct BluePic {
  static let Domain = "BluePic-Server"
  enum Error: Int {
    case Internal = 1
    case Other
  }
}

enum ProcessingError: ErrorProtocol {
  case Image(String)
  case User(String)
}
