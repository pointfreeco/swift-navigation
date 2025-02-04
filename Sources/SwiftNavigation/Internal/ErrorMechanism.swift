@rethrows
package protocol _ErrorMechanism {
  associatedtype Output
  func get() throws -> Output
}

extension _ErrorMechanism {
  package func _rethrowError() rethrows -> Never {
    _ = try _rethrowGet()
    fatalError()
  }

  package func _rethrowGet() rethrows -> Output {
    return try get()
  }
}

extension Result: _ErrorMechanism {}
