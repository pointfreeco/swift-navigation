#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 14, tvOS 14, watchOS 7, *)
  @available(macOS, unavailable)
  extension View {
    /// Presents a full-screen cover using a binding as a data source for the sheet's content.
    ///
    /// SwiftUI comes with a `fullScreenCover(item:)` view modifier that is powered by a binding to
    /// some identifiable state. When this state becomes non-`nil`, it passes an unwrapped value to
    /// the content closure. This value, however, is completely static, which prevents the sheet
    /// from modifying it.
    ///
    /// This overload differs in that it passes a _binding_ to the unwrapped value, instead. This
    /// gives the sheet the ability to write changes back to its source of truth.
    ///
    /// Also unlike `fullScreenCover(item:)`, the binding's value does _not_ need to be
    /// identifiable, and can instead specify a key path to the provided data's identifier.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .fullScreenCover(item: $draft, id: \.id) { $draft in
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
    ///   - item: A binding to an optional source of truth for the sheet. When `item` is non-`nil`,
    ///     the system passes the item's content to the modifier's closure. You display this content
    ///     in a sheet that you create that the system displays to the user. If `item`'s identity
    ///     changes, the system dismisses the sheet and replaces it with a new one using the same
    ///     process.
    ///   - id: The key path to the provided item's identifier.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    @_disfavoredOverload
    public func fullScreenCover<Item, ID: Hashable, Content: View>(
      item: Binding<Item?>,
      id: KeyPath<Item, ID>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Item>) -> Content
    ) -> some View {
      fullScreenCover(item: item[id: id], onDismiss: onDismiss) {
        content(Binding(unwrapping: item, default: $0.initialValue))
      }
    }

    /// Presents a full-screen cover using a binding as a data source for the sheet's content.
    ///
    /// A version of ``SwiftUI/View/fullScreenCover(item:id:onDismiss:content:)-14to1`` that takes
    /// an identifiable item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet. When `item` is non-`nil`,
    ///     the system passes the item's content to the modifier's closure. You display this content
    ///     in a sheet that you create that the system displays to the user. If `item`'s identity
    ///     changes, the system dismisses the sheet and replaces it with a new one using the same
    ///     process.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    @_disfavoredOverload
    public func fullScreenCover<Item: Identifiable, Content: View>(
      item: Binding<Item?>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Item>) -> Content
    ) -> some View {
      fullScreenCover(item: item, id: \.id, onDismiss: onDismiss, content: content)
    }

    /// Presents a full-screen cover using a binding as a data source for the sheet's content.
    ///
    /// A version of ``SwiftUI/View/fullScreenCover(item:id:onDismiss:content:)-14to1`` that is
    /// passed an item and not a binding to an item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the sheet. When `item` is non-`nil`,
    ///     the system passes the item's content to the modifier's closure. You display this content
    ///     in a sheet that you create that the system displays to the user. If `item`'s identity
    ///     changes, the system dismisses the sheet and replaces it with a new one using the same
    ///     process.
    ///   - id: The key path to the provided item's identifier.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    public func fullScreenCover<Item, ID: Hashable, Content: View>(
      item: Binding<Item?>,
      id: KeyPath<Item, ID>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
      fullScreenCover(item: item, id: id, onDismiss: onDismiss) {
        content($0.wrappedValue)
      }
    }
  }
#endif  // canImport(SwiftUI)
