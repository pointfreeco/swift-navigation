import SwiftNavigation
import XCTest

final class UINavigationPathTests: XCTestCase {
  func testCodable() throws {
    guard #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) else { return }

    var path = UINavigationPath()
    path.append("hello")
    path.append(42)
    path.append(true)
    path.append(User(id: 42))

    let codable = try XCTUnwrap(path.codable)
    let data = try JSONEncoder().encode(codable)
    let decoded = try JSONDecoder().decode(UINavigationPath.CodableRepresentation.self, from: data)
    XCTAssertEqual(path, UINavigationPath(decoded))

    struct NotCodable: Hashable {}

    path.append(NotCodable())
    XCTAssertNil(path.codable)

    path.removeLast()
    XCTAssertNotNil(path.codable)
    XCTAssertEqual(codable, path.codable)
  }

  public struct User: Codable, Hashable {
    let id: Int
  }
}
