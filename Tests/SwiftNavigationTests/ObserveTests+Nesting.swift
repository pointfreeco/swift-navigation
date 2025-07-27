import SwiftNavigation
import Perception
import XCTest

class NestingObserveTests: XCTestCase {
  #if swift(>=6)
    func testIsolation() async {
      await MainActor.run {
        var count = 0
        let token = SwiftNavigation.observe {
          count = 1
        }
        XCTAssertEqual(count, 1)
        _ = token
      }
    }
  #endif

  #if !os(WASI)
    @MainActor
    func testNestedObservation() async {
      let object = ParentObject()
      let model = ParentObject.Model()

      MockTracker.shared.entries.removeAll()
      object.bind(model)

      XCTAssertEqual(
        MockTracker.shared.entries.map(\.label),
        [
          "ParentObject.bind",
          "ParentObject.value.didSet",
          "ChildObject.bind",
          "ChildObject.value.didSet",
        ]
      )

      MockTracker.shared.entries.removeAll()
      model.child.value = 1

      await Task.yield()

      XCTAssertEqual(
        MockTracker.shared.entries.map(\.label),
        [
          "ChildObject.Model.value.didSet",
          "ChildObject.value.didSet",
        ]
      )
    }
  #endif
}

#if !os(WASI)
  fileprivate class ParentObject: @unchecked Sendable {
    var tokens: Set<ObserveToken> = []
    let child: ChildObject = .init()

    var value: Int = 0 {
      didSet { MockTracker.shared.track(value, with: "ParentObject.value.didSet") }
    }

    func bind(_ model: Model) {
      MockTracker.shared.track((), with: "ParentObject.bind")

      tokens = [
        observe { _ = model.value } onChange: { [weak self] in
          self?.value = model.value
        },
        observe { _ = model.child } onChange: { [weak self] in
          self?.child.bind(model.child)
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      var value: Int = 0 {
        didSet { MockTracker.shared.track(value, with: "ParentObject.Model.value.didSet") }
      }

      var child: ChildObject.Model = .init() {
        didSet { MockTracker.shared.track(value, with: "ParentObject.Model.value.didSet") }
      }
    }
  }

  fileprivate class ChildObject: @unchecked Sendable {
    var tokens: Set<ObserveToken> = []

    var value: Int = 0 {
      didSet { MockTracker.shared.track(value, with: "ChildObject.value.didSet") }
    }

    func bind(_ model: Model) {
      MockTracker.shared.track((), with: "ChildObject.bind")

      tokens = [
        observe { _ = model.value } onChange: { [weak self] in
          self?.value = model.value
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      var value: Int = 0 {
        didSet { MockTracker.shared.track(value, with: "ChildObject.Model.value.didSet") }
      }
    }
  }

  fileprivate final class MockTracker: @unchecked Sendable {
    static let shared = MockTracker()

    struct Entry {
      var label: String
      var value: Any
    }

    var entries: [Entry] = []

    init() {}

    func track(
      _ value: Any,
      with label: String
    ) {
      entries.append(.init(label: label, value: value))
    }
  }
#endif
