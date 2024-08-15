#if canImport(SwiftUI)
  import SwiftUI

  extension NavigationLink {
    /// Creates a navigation link that presents the destination view when a bound value is
    /// non-`nil`.
    ///
    /// > Note: This interface is deprecated to match the availability of the corresponding SwiftUI
    /// > API. If you are targeting iOS 16 or later, use
    /// > ``SwiftUI/View/navigationDestination(item:destination:)``, instead.
    ///
    /// This allows you to drive navigation to a destination from an optional value. When the
    /// optional value becomes non-`nil` a binding to an honest value is derived and passed to the
    /// destination. Any edits made to the binding in the destination are automatically reflected
    /// in the parent.
    ///
    /// ```swift
    /// struct ContentView: View {
    ///   @State var postToEdit: Post?
    ///   @State var posts: [Post]
    ///
    ///   var body: some View {
    ///     ForEach(self.posts) { post in
    ///       NavigationLink(item: $postToEdit) { isActive in
    ///         postToEdit = isActive ? post : nil
    ///       } destination: { $draft in
    ///         EditPostView(post: $draft)
    ///       } label: {
    ///         Text(post.title)
    ///       }
    ///     }
    ///   }
    /// }
    ///
    /// struct EditPostView: View {
    ///   @Binding var post: Post
    ///   var body: some View { ... }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the destination. When `item` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `destination` closure.
    ///     The destination can use this binding to produce its content and write changes back to
    ///     the source of truth. Upstream changes to `item` will also be instantly reflected in the
    ///     destination. If `item` becomes `nil`, the destination is dismissed.
    ///   - onNavigate: A closure that executes when the link becomes active or inactive with a
    ///     boolean that describes if the link was activated or not. Use this closure to populate
    ///     the source of truth when it is passed a value of `true`. When passed `false`, the system
    ///     will automatically write `nil` to `item`.
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the `destination` to present.
    @available(iOS, introduced: 13, deprecated: 16)
    @available(macOS, introduced: 10.15, deprecated: 13)
    @available(tvOS, introduced: 13, deprecated: 16)
    @available(watchOS, introduced: 6, deprecated: 9)
    public init<Item: Sendable, WrappedDestination>(
      item: Binding<Item?>,
      onNavigate: @escaping @Sendable (_ isActive: Bool) -> Void,
      @ViewBuilder destination: @escaping (Binding<Item>) -> WrappedDestination,
      @ViewBuilder label: () -> Label
    ) where Destination == WrappedDestination? {
      self.init(
        destination: Binding(unwrapping: item).map(destination),
        isActive: Binding(item).didSet(onNavigate),
        label: label
      )
    }
  }
#endif  // canImport(SwiftUI)
