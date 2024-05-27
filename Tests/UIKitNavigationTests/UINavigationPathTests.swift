import UIKitNavigation
import SwiftUI
import XCTest

final class UINavigationPathTests: XCTestCase {
  func testCodable() throws {
    guard #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) else { return }

    var path = UINavigationPath()
    path.append("hello")
    path.append(42)
    path.append(true)
    path.append(User(id: 42, name: "Blob"))

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
    var name: String
  }
}

func _typeByName_Env(_ name: String) -> Any.Type? {
  let nameUTF8 = Array(name.utf8)
  return nameUTF8.withUnsafeBufferPointer { (nameUTF8) in
    return  _getTypeByMangledNameInEnvironment(
      nameUTF8.baseAddress!,
      UInt(nameUTF8.endIndex),
      genericEnvironment: nil,
      genericArguments: nil
    )
  }
}

func _typeByName_Ctx(_ name: String) -> Any.Type? {
  let nameUTF8 = Array(name.utf8)
  return nameUTF8.withUnsafeBufferPointer { (nameUTF8) in
    return  _getTypeByMangledNameInContext(
      nameUTF8.baseAddress!,
      UInt(nameUTF8.endIndex),
      genericContext: nil,
      genericArguments: nil
    )
  }
}
//
//@_silgen_name("swift_stdlib_getTypeByMangledNameUntrusted")
//internal func _getTypeByMangledNameUntrusted(
//  _ name: UnsafePointer<UInt8>,
//  _ nameLength: UInt)
//  -> Any.Type?

@_silgen_name("swift_getTypeByMangledNameInEnvironment")
public func _getTypeByMangledNameInEnvironment(
  _ name: UnsafePointer<UInt8>,
  _ nameLength: UInt,
  genericEnvironment: UnsafeRawPointer?,
  genericArguments: UnsafeRawPointer?)
  -> Any.Type?

@_silgen_name("swift_getTypeByMangledNameInContext")
public func _getTypeByMangledNameInContext(
  _ name: UnsafePointer<UInt8>,
  _ nameLength: UInt,
  genericContext: UnsafeRawPointer?,
  genericArguments: UnsafeRawPointer?)
  -> Any.Type?
