#if canImport(SwiftUI)
  import SwiftUI

  @available(
    iOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message:
      "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView")
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message:
      "use NavigationLink(value:label:), or navigationDestination(isPresented:destination:), inside a NavigationStack or NavigationSplitView"
  )
  extension NavigationLink {
    /// Creates a navigation link that presents the view corresponding to a value.
    ///
    /// > Tip: This initializer is provided for applications deploying to older OSes that want to
    /// > drive navigation with an optional.
    ///
    /// - Parameters:
    ///   - value: A value to present.
    ///   - item: A binding to the presented value.
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the destination to present.
    public init<T, D: View>(
      value: @autoclosure @escaping () -> T,
      item: Binding<T?>,
      @ViewBuilder destination: (T) -> D,
      @ViewBuilder label: () -> Label
    ) where Destination == D? {
      self.init(
        destination: item.wrappedValue.map(destination),
        isActive: Binding(
          get: { item.wrappedValue != nil },
          set: { newValue, transaction in
            if newValue {
              item.transaction(transaction).wrappedValue = value()
            } else {
              item.transaction(transaction).wrappedValue = nil
            }
          }
        ),
        label: label
      )
    }
  }
#endif  // canImport(SwiftUI)
