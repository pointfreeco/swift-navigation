#if canImport(SwiftUI)
  import SwiftUI

  extension NavigationLink {
    /// Creates a navigation link that presents the destination view when a bound value is non-`nil`.
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
    ///       NavigationLink(unwrapping: self.$postToEdit) { isActive in
    ///         self.postToEdit = isActive ? post : nil
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
    ///   - value: A binding to an optional source of truth for the destination. When `value` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `destination` closure. The
    ///     destination can use this binding to produce its content and write changes back to the
    ///     source of truth. Upstream changes to `value` will also be instantly reflected in the
    ///     destination. If `value` becomes `nil`, the destination is dismissed.
    ///   - onNavigate: A closure that executes when the link becomes active or inactive with a
    ///     boolean that describes if the link was activated or not. Use this closure to populate the
    ///     source of truth when it is passed a value of `true`. When passed `false`, the system will
    ///     automatically write `nil` to `value`.
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the `destination` to present.
    @available(iOS, introduced: 13, deprecated: 16)
    @available(macOS, introduced: 10.15, deprecated: 13)
    @available(tvOS, introduced: 13, deprecated: 16)
    @available(watchOS, introduced: 6, deprecated: 9)
    public init<Value, WrappedDestination>(
      unwrapping value: Binding<Value?>,
      onNavigate: @escaping (_ isActive: Bool) -> Void,
      @ViewBuilder destination: @escaping (Binding<Value>) -> WrappedDestination,
      @ViewBuilder label: () -> Label
    ) where Destination == WrappedDestination? {
      self.init(
        destination: Binding(unwrapping: value).map(destination),
        isActive: value.isPresent().didSet(onNavigate),
        label: label
      )
    }

    /// Creates a navigation link that presents the destination view when a bound enum is non-`nil`
    /// and matches a particular case.
    ///
    /// This allows you to drive navigation to a destination from an enum of values. When the
    /// optional value becomes non-`nil` _and_ matches a particular case of the enum, a binding to an
    /// honest value is derived and passed to the destination. Any edits made to the binding in the
    /// destination are automatically reflected in the parent.
    ///
    /// ```swift
    /// struct ContentView: View {
    ///   @State var destination: Destination?
    ///   @State var posts: [Post]
    ///
    ///   enum Destination {
    ///     case edit(Post)
    ///     /* other destinations */
    ///   }
    ///
    ///   var body: some View {
    ///     ForEach(self.posts) { post in
    ///       NavigationLink(unwrapping: self.$destination, case: /Destination.edit) { isActive in
    ///         self.destination = isActive ? .edit(post) : nil
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
    /// See `NavigationLink.init(unwrapping:destination:onNavigate:label)` for a version of this
    /// initializer that works with optional state instead of enum state.
    ///
    /// - Parameters:
    ///   - enum: A binding to an optional source of truth for the destination. When `enum` is
    ///     non-`nil`, and `casePath` successfully extracts a value, a non-optional binding to the
    ///     value is passed to the `destination` closure. The destination can use this binding to
    ///     produce its content and write changes back to the source of truth. Upstream changes to
    ///     `enum` will also be instantly reflected in the destination. If `enum` becomes `nil`, the
    ///     destination is dismissed.
    ///   - onNavigate: A closure that executes when the link becomes active or inactive with a
    ///     boolean that describes if the link was activated or not. Use this closure to populate the
    ///     source of truth when it is passed a value of `true`. When passed `false`, the system will
    ///     automatically write `nil` to `enum`.
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the `destination` to present.
    @available(iOS, introduced: 13, deprecated: 16)
    @available(macOS, introduced: 10.15, deprecated: 13)
    @available(tvOS, introduced: 13, deprecated: 16)
    @available(watchOS, introduced: 6, deprecated: 9)
    public init<Enum, Case, WrappedDestination>(
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, Case>,
      onNavigate: @escaping (Bool) -> Void,
      @ViewBuilder destination: @escaping (Binding<Case>) -> WrappedDestination,
      @ViewBuilder label: () -> Label
    ) where Destination == WrappedDestination? {
      self.init(
        unwrapping: `enum`.case(casePath),
        onNavigate: onNavigate,
        destination: destination,
        label: label
      )
    }
  }
#endif  // canImport(SwiftUI)
