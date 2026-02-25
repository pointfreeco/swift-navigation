#if SwiftNavigationSharing
@_spi(Internals) import Sharing
import PerceptionCore
import SwiftUI

extension UIBinding {
  /// Creates a binding from a shared reference.
  ///
  /// Useful for binding shared state to a UIKit control.
  ///
  /// ```swift
  /// @Shared var count: Double
  /// // ...
  /// UIStepper(value: UIBinding($count))
  /// ```
  ///
  /// - Parameter base: A shared reference to a value.
  @MainActor
  public init(_ base: Shared<Value>) {
    guard
      #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *),
      // NB: We can't do 'any MutableReference<Value> & Observable' and must force-cast, instead.
      //     https://github.com/swiftlang/swift/pull/76705
      let reference = base.reference as? any MutableReference & Observable
    else {
      #if os(visionOS)
        fatalError("This should be unreachable: visionOS should always support Observation")
      #else
        func open(_ reference: some MutableReference<Value>) -> UIBinding<Value> {
          @UIBindable var reference = reference
          return $reference._wrappedValue
        }
        self = open(base.reference)
        return
      #endif
    }
    func open<V>(_ reference: some MutableReference<V> & Observable) -> UIBinding<Value> {
      @SwiftUI.Bindable var reference = reference
      return $reference._wrappedValue as! UIBinding<Value>
    }
    self = open(reference)
  }
}
#endif
