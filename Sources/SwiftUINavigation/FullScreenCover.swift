#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 14, tvOS 14, watchOS 7, *)
  @available(macOS, unavailable)
  extension View {
    /// Presents a full-screen cover using a binding as a data source for the sheet's content based
    /// on the identity of the underlying item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet. When `item` is non-`nil`,
    ///     the system passes the item's content to the modifier's closure. You display this content
    ///     in a sheet that you create that the system displays to the user. If `item` changes, the
    ///     system dismisses the sheet and replaces it with a new one using the same process.
    ///   - id: The key path to the provided item's identifier.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    public func fullScreenCover<Item, ID: Hashable, Content: View>(
      item: Binding<Item?>,
      id: KeyPath<Item, ID>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
      self.fullScreenCover(item: item[id: id], onDismiss: onDismiss) { _ in
        item.wrappedValue.map(content)
      }
    }

    /// Presents a full-screen cover using a binding as a data source for the sheet's content.
    ///
    /// SwiftUI comes with a `fullScreenCover(item:)` view modifier that is powered by a binding to
    /// some hashable state. When this state becomes non-`nil`, it passes an unwrapped value to the
    /// content closure. This value, however, is completely static, which prevents the sheet from
    /// modifying it.
    ///
    /// This overload differs in that it passes a _binding_ to the unwrapped value, instead. This
    /// gives the sheet the ability to write changes back to its source of truth.
    ///
    /// Also unlike `fullScreenCover(item:)`, the binding's value does _not_ need to be hashable.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .fullScreenCover(unwrapping: self.$draft) { $draft in
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
    ///   - value: A binding to a source of truth for the sheet. When `value` is non-`nil`, a
    ///     non-optional binding to the value is passed to the `content` closure. You use this
    ///     binding to produce content that the system presents to the user in a sheet. Changes made
    ///     to the sheet's binding will be reflected back in the source of truth. Likewise, changes
    ///     to `value` are instantly reflected in the sheet. If `value` becomes `nil`, the sheet is
    ///     dismissed.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    public func fullScreenCover<Value, Content>(
      unwrapping value: Binding<Value?>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) -> some View
    where Content: View {
      self.fullScreenCover(
        isPresented: value.isPresent(),
        onDismiss: onDismiss
      ) {
        Binding(unwrapping: value).map(content)
      }
    }
  }
#endif  // canImport(SwiftUI)
