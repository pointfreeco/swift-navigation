#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
  extension View {
    /// Pushes a view onto a `NavigationStack` using a binding as a data source for the
    /// destination's content.
    ///
    /// This is a version of SwiftUI's `navigationDestination(isPresented:)` modifier, but powered
    /// by a binding to optional state instead of a binding to a boolean. When state becomes
    /// non-`nil`, a _binding_ to the unwrapped value is passed to the destination closure.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .navigationDestination(unwrapping: self.$draft) { $draft in
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
    ///   - value: A binding to an optional source of truth for the destination. When `value` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `destination` closure.
    ///     You use this binding to produce content that the system pushes to the user in a
    ///     navigation stack. Changes made to the destination's binding will be reflected back in
    ///     the source of truth. Likewise, changes to `value` are instantly reflected in the
    ///     destination. If `value` becomes `nil`, the destination is popped.
    ///   - destination: A closure returning the content of the destination.
    public func navigationDestination<Value, Destination: View>(
      unwrapping value: Binding<Value?>,
      @ViewBuilder destination: (Binding<Value>) -> Destination
    ) -> some View {
      self._navigationDestination(isPresented: value.isPresent()) {
        Binding(unwrapping: value).map(destination)
      }
    }
  }

#endif  // canImport(SwiftUI)
