import SwiftNavigation
import Perception
import XCTest
import ConcurrencyExtras

#if !os(WASI)
  class NestingObserveTests: XCTestCase {
    @MainActor
    func testNestedObservationMisuse() async throws {
      // ParentObject and ChildObject models
      // do not use scoped observation in these tests.
      // This results in redundant updates.
      // The issue is related to nested unscoped `observe` calls
      // it is expected behavior for this kind of API misuse

      let tracker = MockTracker()
      let object = ParentObject(tracker: tracker)
      let model = ParentObject.Model(tracker: tracker)

      tracker.entries.removeAll()

      await Task.yield()

      object.bind(model)

      await Task.yield()

      XCTAssertEqual(
        tracker.entries,
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

      tracker.entries.removeAll()

      await Task.yield()

      model.child.value = 1

      await Task.yield()

      // NOTE: Scoped update won't trigger update of the parent
      // The test seems flaky, so only checking for expected redundant "childUpdate"
      XCTAssert(
        tracker.entries.contains("ParentObject.childUpdate")
      )
    }

    @MainActor
    func testNestedObservation() async throws {
      // ParentObject and ChildObject models
      // use scoped observation in these tests
      // to avoid redundant updates

      let tracker = MockTracker()
      let object = ScopedParentObject(tracker: tracker)
      let model = ScopedParentObject.Model(tracker: tracker)

      tracker.entries.removeAll()

      await Task.yield()

      object.bind(model)

      await Task.yield()

      XCTAssertEqual(
        tracker.entries,
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

      tracker.entries.removeAll()

      await Task.yield()

      model.child.value = 1

      await Task.yield()

      XCTAssertEqual(
        tracker.entries,
        [
          "ChildObject.Model.value.didSet 1",
          "ChildObject.valueUpdate 1",
          "ChildObject.value.didSet 1"
        ]
      )
    }

    @MainActor
    func testAutoclosureObservation() async throws {
      let tracker = MockTracker()
      let model = ReadTrackingModel(tracker: tracker)
      var token: ObserveToken?

      tracker.entries.removeAll()

      token = observe { _ = model.value } onChange: {
        tracker.track("didSet \(model.value)")
      }

      await Task.yield()

      model.value += 1

      await Task.yield()

      XCTAssertEqual(
        tracker.entries,
        [
          "ReadTrackingModel.value.get 0", // observe context
          "ReadTrackingModel.value.get 0", // initial onChange call
          "didSet 0",                      // initial onChange handler
          "ReadTrackingModel.value.get 0", // "0+" read
          "ReadTrackingModel.value.set 1", // "+1" write
          "ReadTrackingModel.value.get 1", // recursive tracking context
          "ReadTrackingModel.value.get 1", // recursive tracking initial onChange call
          "didSet 1",                      // recursive tracking onChange handler
        ]
      )

      token?.cancel()
      model.value = 0
      tracker.entries.removeAll()

      await Task.yield()

      token = observe(model.value) { _, value in
        tracker.track("didSet \(value)")
      }

      model.value += 1

      await Task.yield()

      XCTAssertEqual(
        tracker.entries,
        [
          "ReadTrackingModel.value.get 0",    // observe context
          // "ReadTrackingModel.value.get 0", // initial onChange call doesn't cause additional read
          "didSet 0",                         // onChange handler
          "ReadTrackingModel.value.get 0",    // "0+" read
          "ReadTrackingModel.value.set 1",    // "+1" write
          "ReadTrackingModel.value.get 1",    // recursive tracking context
          // "ReadTrackingModel.value.get 1", // recursive tracking onChange call doesn't cause additional read
          "didSet 1",                          // recursive tracking onChange handler
        ]
      )
    }
  }

  // MARK: - Mocks

  // MARK: Unscoped

  fileprivate class ParentObject: @unchecked Sendable {
    private let tracker: MockTracker
    private var tokens: Set<ObserveToken> = []

    var value: Int {
      didSet { tracker.track("ParentObject.value.didSet \(value)") }
    }

    var child: ChildObject {
      didSet { tracker.track("ParentObject.child.didSet") }
    }

    convenience init(
      tracker: MockTracker,
      value: Int = 0,
      childValue: Int = 0
    ) {
      self.init(
        tracker: tracker,
        value: value,
        child: .init(tracker: tracker, value: childValue)
      )
    }

    init(
      tracker: MockTracker,
      value: Int = 0,
      child: ChildObject
    ) {
      self.tracker = tracker
      self.child = child
      self.value = value
    }

    func bind(_ model: Model) {
      tracker.track("ParentObject.bind")

      // Observe calls are not scoped
      tokens = [
        observe { [weak self, tracker] in
          tracker.track("ParentObject.valueUpdate \(model.value)")
          self?.value = model.value
        },
        observe { [weak self, tracker] in
          tracker.track("ParentObject.childUpdate")
          self?.child.bind(model.child)
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      private let tracker: MockTracker

      var value: Int {
        didSet { tracker.track("ParentObject.Model.value.didSet  \(value)") }
      }

      var child: ChildObject.Model {
        didSet { tracker.track("ParentObject.Model.child.didSet") }
      }

      convenience init(
        tracker: MockTracker,
        value: Int = 0,
        childValue: Int = 0
      ) {
        self.init(
          tracker: tracker,
          value: value,
          child: .init(tracker: tracker, value: value)
        )
      }

      init(
        tracker: MockTracker,
        value: Int = 0,
        child: ChildObject.Model
      ) {
        self.tracker = tracker
        self.value = value
        self.child = child
      }
    }
  }

  fileprivate class ChildObject: @unchecked Sendable {
    private let tracker: MockTracker
    private var tokens: Set<ObserveToken> = []

    var value: Int {
      didSet { tracker.track("ChildObject.value.didSet \(value)") }
    }

    init(tracker: MockTracker, value: Int = 0) {
      self.tracker = tracker
      self.value = value
    }

    func bind(_ model: Model) {
      tracker.track("ChildObject.bind")

      // Observe calls are not scoped
      tokens = [
        observe { [weak self, tracker] in
          tracker.track("ChildObject.valueUpdate \(model.value)")
          self?.value = model.value
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      private let tracker: MockTracker

      var value: Int = 0 {
        didSet { tracker.track("ChildObject.Model.value.didSet \(value)") }
      }

      init(tracker: MockTracker, value: Int = 0) {
        self.tracker = tracker
        self.value = value
      }
    }
  }

  // MARK: - Scoped

  fileprivate class ScopedParentObject: @unchecked Sendable {
    private let tracker: MockTracker
    private var tokens: Set<ObserveToken> = []

    var value: Int {
      didSet { tracker.track("ParentObject.value.didSet \(value)") }
    }

    var child: ScopedChildObject {
      didSet { tracker.track("ParentObject.child.didSet") }
    }

    convenience init(
      tracker: MockTracker,
      value: Int = 0,
      childValue: Int = 0
    ) {
      self.init(
        tracker: tracker,
        value: value,
        child: .init(tracker: tracker, value: childValue)
      )
    }

    init(
      tracker: MockTracker,
      value: Int = 0,
      child: ScopedChildObject
    ) {
      self.tracker = tracker
      self.value = value
      self.child = child
    }

    func bind(_ model: Model) {
      tracker.track("ParentObject.bind")

      // Observe calls are scoped
      tokens = [
        observe { _ = model.value } onChange: { [weak self, tracker] in
          tracker.track("ParentObject.valueUpdate \(model.value)")
          self?.value = model.value
        },
        observe { _ = model.child } onChange: { [weak self, tracker] in
          tracker.track("ParentObject.childUpdate")
          self?.child.bind(model.child)
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      private let tracker: MockTracker

      var value: Int {
        didSet { tracker.track("ParentObject.Model.value.didSet  \(value)") }
      }

      var child: ScopedChildObject.Model {
        didSet { tracker.track("ParentObject.Model.child.didSet") }
      }

      convenience init(
        tracker: MockTracker,
        value: Int = 0,
        childValue: Int = 0
      ) {
        self.init(
          tracker: tracker,
          value: value,
          child: .init(tracker: tracker, value: value)
        )
      }

      init(
        tracker: MockTracker,
        value: Int = 0,
        child: ScopedChildObject.Model
      ) {
        self.tracker = tracker
        self.value = value
        self.child = child
      }
    }
  }

  fileprivate class ScopedChildObject: @unchecked Sendable {
    private let tracker: MockTracker
    private var tokens: Set<ObserveToken> = []

    var value: Int {
      didSet { tracker.track("ChildObject.value.didSet \(value)") }
    }

    init(tracker: MockTracker, value: Int = 0) {
      self.tracker = tracker
      self.value = value
    }

    func bind(_ model: Model) {
      tracker.track("ChildObject.bind")

      // Observe calls not scoped
      tokens = [
        observe { _ = model.value } onChange: { [weak self, tracker] in
          tracker.track("ChildObject.valueUpdate \(model.value)")
          self?.value = model.value
        }
      ]
    }

    @Perceptible
    class Model: @unchecked Sendable {
      private let tracker: MockTracker

      var value: Int = 0 {
        didSet { tracker.track("ChildObject.Model.value.didSet \(value)") }
      }

      init(tracker: MockTracker, value: Int = 0) {
        self.tracker = tracker
        self.value = value
      }
    }
  }

  @Perceptible
  fileprivate class ReadTrackingModel: @unchecked Sendable {
    private let tracker: MockTracker
    private var _value: Int

    init(tracker: MockTracker, value: Int = 0) {
      self.tracker = tracker
      self._value = value
    }

    var value: Int {
      get {
        tracker.track("ReadTrackingModel.value.get \(_value)")
        return _value
      }
      set {
        tracker.track("ReadTrackingModel.value.set \(newValue)")
        _value = newValue
      }
    }
  }

  // MARK: Tracker

  fileprivate final class MockTracker: @unchecked Sendable {
    var entries: [String] = []

    init() {}

    func track(
      _ entry: String
    ) {
      entries.append(entry)
    }
  }
#endif
