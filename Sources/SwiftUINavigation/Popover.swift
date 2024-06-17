#if canImport(SwiftUI)
  import SwiftUI

  // NB: Moving `@available(tvOS, unavailable)` to the extension causes tvOS builds to fail
  extension View {
    /// Presents a popover using a binding as a data source for the popover's content.
    ///
    /// SwiftUI comes with a `popover(item:)` view modifier that is powered by a binding to some
    /// identifiable state. When this state becomes non-`nil`, it passes an unwrapped value to the
    /// content closure. This value, however, is completely static, which prevents the popover from
    /// modifying it.
    ///
    /// This overload differs in that it passes a _binding_ to the unwrapped value, instead. This
    /// gives the popover the ability to write changes back to its source of truth.
    ///
    /// Also unlike `popover(item:)`, the binding's value does _not_ need to be identifiable, and
    /// can instead specify a key path to the provided data's identifier.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .popover(item: $draft) { $draft in
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
    ///   - item: A binding to an optional source of truth for the popover. When `item` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `content` closure. You
    ///     use this binding to produce content that the system presents to the user in a popover.
    ///     Changes made to the popover's binding will be reflected back in the source of truth.
    ///     Likewise, changes to `item` are instantly reflected in the popover. If `item` becomes
    ///     `nil`, the popover is dismissed.
    ///   - id: The key path to the provided item's identifier.
    ///   - attachmentAnchor: The positioning anchor that defines the attachment point of the
    ///     popover.
    ///   - arrowEdge: The edge of the `attachmentAnchor` that defines the location of the popover's
    ///     arrow.
    ///   - content: A closure returning the content of the popover.
    @_disfavoredOverload
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Item, ID: Hashable, Content: View>(
      item: Binding<Item?>,
      id: KeyPath<Item, ID>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Binding<Item>) -> Content
    ) -> some View {
      popover(
        item: item[id: id],
        attachmentAnchor: attachmentAnchor,
        arrowEdge: arrowEdge
      ) {
        content(Binding(unwrapping: item, default: $0.initialValue))
      }
    }

    /// Presents a full-screen cover using a binding as a data source for the sheet's content.
    ///
    /// A version of ``SwiftUI/View/fullScreenCover(item:id:onDismiss:content:)-14to1`` that takes
    /// an identifiable item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. When `item` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `content` closure. You
    ///     use this binding to produce content that the system presents to the user in a popover.
    ///     Changes made to the popover's binding will be reflected back in the source of truth.
    ///     Likewise, changes to `item` are instantly reflected in the popover. If `item` becomes
    ///     `nil`, the popover is dismissed.
    ///   - attachmentAnchor: The positioning anchor that defines the attachment point of the
    ///     popover.
    ///   - arrowEdge: The edge of the `attachmentAnchor` that defines the location of the popover's
    ///     arrow.
    ///   - content: A closure returning the content of the popover.
    @_disfavoredOverload
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Item: Identifiable, Content: View>(
      item: Binding<Item?>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Binding<Item>) -> Content
    ) -> some View {
      popover(
        item: item,
        id: \.id,
        attachmentAnchor: attachmentAnchor,
        arrowEdge: arrowEdge,
        content: content
      )
    }

    /// Presents a popover using a binding as a data source for the sheet's content based on the
    /// identity of the underlying item.
    ///
    /// A version of ``SwiftUI/View/popover(item:id:attachmentAnchor:arrowEdge:content:)-3un96``
    /// that is passed an item and not a binding to an item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the popover. When `item` is
    ///     non-`nil`, the system passes the item's content to the modifier's closure. You display
    ///     this content in a popover that you create that the system displays to the user. If `item`
    ///     changes, the system dismisses the popover and replaces it with a new one using the same
    ///     process.
    ///   - id: The key path to the provided item's identifier.
    ///   - attachmentAnchor: The positioning anchor that defines the attachment point of the
    ///     popover.
    ///   - arrowEdge: The edge of the `attachmentAnchor` that defines the location of the popover's
    ///     arrow.
    ///   - content: A closure returning the content of the popover.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Item, ID: Hashable, Content: View>(
      item: Binding<Item?>,
      id: KeyPath<Item, ID>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
      popover(item: item, id: id, attachmentAnchor: attachmentAnchor, arrowEdge: arrowEdge) {
        content($0.wrappedValue)
      }
    }
  }
#endif  // canImport(SwiftUI)
