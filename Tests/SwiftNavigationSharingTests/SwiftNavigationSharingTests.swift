import Sharing
import SwiftNavigation
import SwiftNavigationSharing

#if canImport(Testing)
  import Testing

  @MainActor
  @Suite
  struct SwiftNavigationSharingTests {
    @Test
    func sharedObservationBaseline() async throws {
      var tokens: Set<ObserveToken> = []
      @Shared(value: 0) var count
      var observedValues = [Int]()

      SwiftNavigation.observe {
        observedValues.append(count)
      }
      .store(in: &tokens)

      $count.withLock { $0 = 1 }
      try await Task.sleep(for: .milliseconds(300))
      #expect(observedValues == [0, 1])
    }

    @Test
    func sharedBindingRoundTrips() {
      @Shared(value: 0) var count
      let binding = UIBinding($count)

      #expect(binding.wrappedValue == 0)
      #expect(count == 0)

      binding.wrappedValue = 1
      #expect(binding.wrappedValue == 1)
      #expect(count == 1)

      $count.withLock { $0 = 2 }
      #expect(binding.wrappedValue == 2)
      #expect(count == 2)
    }

    @Test
    func sharedBindingObservation() async throws {
      var tokens: Set<ObserveToken> = []
      @Shared(value: 0) var count
      let binding = UIBinding($count)
      var observedValues = [Int]()

      SwiftNavigation.observe {
        observedValues.append(binding.wrappedValue)
      }
      .store(in: &tokens)

      $count.withLock { $0 = 1 }
      try await Task.sleep(for: .milliseconds(300))
      #expect(observedValues == [0, 1])
    }

    @Test
    func sharedBindingTransactionPropagation() async throws {
      var tokens: Set<ObserveToken> = []
      @Shared(value: 0) var count
      var transaction = UITransaction()
      transaction.isSet = true
      var observedTransactions = [Bool]()

      SwiftNavigation.observe { transaction in
        observedTransactions.append(transaction.isSet)
        _ = count
      }
      .store(in: &tokens)

      UIBinding($count).transaction(transaction).wrappedValue = 1
      try await Task.sleep(for: .milliseconds(300))
      #expect(observedTransactions == [false, true])
    }

    @Test
    func sharedBindingIdentifierIsStable() {
      @Shared(value: 0) var count

      let binding = UIBinding($count)
      let rebound = UIBinding($count)

      #expect(UIBindingIdentifier(binding) == UIBindingIdentifier(rebound))
      #expect(
        UIBindingIdentifier(binding).hashValue
          == UIBindingIdentifier(rebound).hashValue
      )
    }

    @Test
    func sharedBindingTracksSharedReassignment() {
      @Shared(value: 0) var count
      let binding = UIBinding($count)
      let next = Shared(value: 10)

      $count = next
      #expect(binding.wrappedValue == 10)

      binding.wrappedValue = 11
      #expect(binding.wrappedValue == 11)
      #expect(next.wrappedValue == 11)
    }
  }
#endif

private extension UITransaction {
  var isSet: Bool {
    get { self[IsSetKey.self] }
    set { self[IsSetKey.self] = newValue }
  }
}

private enum IsSetKey: UITransactionKey {
  static let defaultValue = false
}
