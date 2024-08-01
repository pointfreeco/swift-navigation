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
      navigationDestination(isPresented: Binding(item)) {
        if let item = item.wrappedValue {
          destination(item)
        }
      }
    }

    /// Pushes a view onto a `NavigationStack` using a binding as a data source for the
    /// destination's content.
    ///
    /// This is a version of SwiftUI's `navigationDestination(item:)` modifier that passes a
    /// _binding_ to the unwrapped item to the destination closure.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .navigationDestination(item: $draft) { $draft in
    ///       ComposeView(post: $draft, onSubmit: { ... })
    ///     }
    ///   }
    /// }
    ///
    /// struct ComposeView: View {
    ///   @Binding var post: Post
    ///   var body: some View { ... }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the destination. When `item` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `destination` closure.
    ///     You use this binding to produce content that the system pushes to the user in a
    ///     navigation stack. Changes made to the destination's binding will be reflected back in
    ///     the source of truth. Likewise, changes to `item` are instantly reflected in the
    ///     destination. If `item` becomes `nil`, the destination is popped.
    ///   - destination: A closure returning the content of the destination.
    @_disfavoredOverload
    public func navigationDestination<D, C: View>(
      item: Binding<D?>,
      @ViewBuilder destination: @escaping (Binding<D>) -> C
    ) -> some View {
      navigationDestination(item: item) { _ in
        Binding(unwrapping: item).map(destination)
      }
    }
  }
#endif  // canImport(SwiftUI)
