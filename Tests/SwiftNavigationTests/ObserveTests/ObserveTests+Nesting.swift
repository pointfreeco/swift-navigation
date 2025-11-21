import SwiftNavigation
import Perception
import XCTest
import ConcurrencyExtras

#if !os(WASI)
  class NestingObserveTests: XCTestCase {
    @MainActor
    func testNestedObservationMisuse() async {
      // ParentObject and ChildObject models
      // do not use scoped observation in these tests.
      // This results in redundant updates.
      // The issue is related to nested unscoped `observe` calls
      // it is expected behavior for this kind of API misuse

      let object = ParentObject()
      let model = ParentObject.Model()

      MockTracker.shared.entries.withValue { $0.removeAll() }
      object.bind(model)

      XCTAssertEqual(
        MockTracker.shared.entries.withValue { $0.map(\.label) },
        [
          "ParentObject.bind",
          "ParentObject.valueUpdate 0",
          "ParentObject.value.didSet 0",
          "ParentObject.childUpdate",
          "ChildObject.bind",
          "ChildObject.valueUpdate 0",
          "ChildObject.value.didSet 0",
        ]
      )

      MockTracker.shared.entries.withValue { $0.removeAll() }
      model.child.value = 1

      await Task.yield()

      // NOTE: Scoped update won't trigger update of the parent
      // Also MockTracker entries are flaky, tho it triggers parent updates consistently
      XCTAssertEqual(
        MockTracker.shared.entries.withValue { $0.map(\.label) }.contains("ParentObject.childUpdate"),
        true
      )
    }

    @MainActor
    func testNestedObservation() async {
      // ParentObject and ChildObject models
      // use scoped observation in these tests
      // to avoid redundant updates

      let object = ScopedParentObject()
      let model = ScopedParentObject.Model()

      MockTracker.shared.entries.withValue { $0.removeAll() }
      object.bind(model)

      XCTAssertEqual(
        MockTracker.shared.entries.withValue { $0.map(\.label) },
        [
          "ParentObject.bind",
          "ParentObject.valueUpdate 0",
          "ParentObject.value.didSet 0",
          "ParentObject.childUpdate",
          "ChildObject.bind",
          "ChildObject.valueUpdate 0",
          "ChildObject.value.didSet 0",
        ]
      )

      MockTracker.shared.entries.withValue { $0.removeAll() }
      model.child.value = 1

      await Task.yield()

      XCTAssertEqual(
        MockTracker.shared.entries.withValue { $0.map(\.label) },
        [
          "ChildObject.Model.value.didSet 1",
          "ChildObject.valueUpdate 1",
          "ChildObject.value.didSet 1"
        ]
      )
    }
  }

  // MARK: - Mocks

  // MARK: Unscoped

  fileprivate class ParentObject: @unchecked Sendable {
    var tokens: Set<ObserveToken> = []
    var child: ChildObject = .init()

    var value: Int = 0 {
      didSet { MockTracker.shared.track(value, with: "ParentObject.value.didSet \(value)") }
    }

    func bind(_ model: Model) {
      MockTracker.shared.track((), with: "ParentObject.bind")

      // Observe calls are not scoped
      tokens = [
        observe { [weak self] in
          MockTracker.shared.track((), with: "ParentObject.valueUpdate \(model.value)")
          self?.value = model.value
        },
        observe { [weak self] in
          MockTracker.shared.track((), with: "ParentObject.childUpdate")
          self?.child.bind(model.child)
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      var value: Int = 0 {
        didSet { MockTracker.shared.track(value, with: "ParentObject.Model.value.didSet  \(value)") }
      }

      var child: ChildObject.Model = .init() {
        didSet { MockTracker.shared.track(value, with: "ParentObject.Model.child.didSet") }
      }
    }
  }

  fileprivate class ChildObject: @unchecked Sendable {
    var tokens: Set<ObserveToken> = []

    var value: Int = 0 {
      didSet { MockTracker.shared.track(value, with: "ChildObject.value.didSet \(value)") }
    }

    func bind(_ model: Model) {
      MockTracker.shared.track((), with: "ChildObject.bind")

      // Observe calls are not scoped
      tokens = [
        observe { [weak self] in
          MockTracker.shared.track((), with: "ChildObject.valueUpdate \(model.value)")
          self?.value = model.value
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      var value: Int = 0 {
        didSet { MockTracker.shared.track(value, with: "ChildObject.Model.value.didSet \(value)") }
      }
    }
  }

  // MARK: - Scoped

  fileprivate class ScopedParentObject: @unchecked Sendable {
    var tokens: Set<ObserveToken> = []
    var child: ScopedChildObject = .init()

    var value: Int = 0 {
      didSet { MockTracker.shared.track(value, with: "ParentObject.value.didSet \(value)") }
    }

    func bind(_ model: Model) {
      MockTracker.shared.track((), with: "ParentObject.bind")

      // Observe calls are scoped
      tokens = [
        observe { _ = model.value } onChange: { [weak self] in
          MockTracker.shared.track((), with: "ParentObject.valueUpdate \(model.value)")
          self?.value = model.value
        },
        observe { _ = model.child } onChange: { [weak self] in
          MockTracker.shared.track((), with: "ParentObject.childUpdate")
          self?.child.bind(model.child)
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      var value: Int = 0 {
        didSet { MockTracker.shared.track(value, with: "ParentObject.Model.value.didSet  \(value)") }
      }

      var child: ScopedChildObject.Model = .init() {
        didSet { MockTracker.shared.track(value, with: "ParentObject.Model.child.didSet") }
      }
    }
  }

  fileprivate class ScopedChildObject: @unchecked Sendable {
    var tokens: Set<ObserveToken> = []

    var value: Int = 0 {
      didSet { MockTracker.shared.track(value, with: "ChildObject.value.didSet \(value)") }
    }

    func bind(_ model: Model) {
      MockTracker.shared.track((), with: "ChildObject.bind")

      // Observe calls not scoped
      tokens = [
        observe { _ = model.value } onChange: { [weak self] in
          MockTracker.shared.track((), with: "ChildObject.valueUpdate \(model.value)")
          self?.value = model.value
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      var value: Int = 0 {
        didSet { MockTracker.shared.track(value, with: "ChildObject.Model.value.didSet \(value)") }
      }
    }
  }

  // MARK: Tracker

  fileprivate final class MockTracker: @unchecked Sendable {
    static let shared = MockTracker()

    struct Entry {
      var label: String
      var value: Any
    }

    var entries: LockIsolated<[Entry]> = .init([])

    init() {}

    func track(
      _ value: Any,
      with label: String
    ) {
      let uncheckedSendable = UncheckedSendable(value)
      entries.withValue { $0.append(.init(label: label, value: uncheckedSendable.value)) }
    }
  }
#endif
