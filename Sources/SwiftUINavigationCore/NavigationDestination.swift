#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
  extension View {
    /// Associates a destination view with a bound value for use within a navigation stack or
    /// navigation split view.
    ///
    /// See `SwiftUI.View.navigationDestination(item:destination:)` for more information.
    ///
    /// - Parameters:
    ///   - item: A binding to the data presented, or `nil` if nothing is currently presented.
    ///   - destination: A view builder that defines a view to display when `item` is not `nil`.
    public func navigationDestination<D, C: View>(
      item: Binding<D?>,
      @ViewBuilder destination: @escaping (D) -> C
    ) -> some View {
      navigationDestination(isPresented: item.isPresent()) {
        if let item = item.wrappedValue {
          destination(item)
        }
      }
    }
  }
#endif  // canImport(SwiftUI)
