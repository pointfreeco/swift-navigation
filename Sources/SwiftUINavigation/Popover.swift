#if canImport(SwiftUI)
  import SwiftUI

  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  extension View {
    /// Presents a popover using a binding as a data source for the sheet's content based on the
    /// identity of the underlying item.
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
    public func popover<Item, ID: Hashable, Content: View>(
      item: Binding<Item?>,
      id: KeyPath<Item, ID>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
      self.popover(
        item: item[id: id],
        attachmentAnchor: attachmentAnchor,
        arrowEdge: arrowEdge
      ) { _ in
        item.wrappedValue.map(content)
      }
    }

    /// Presents a popover using a binding as a data source for the popover's content.
    ///
    /// SwiftUI comes with a `popover(item:)` view modifier that is powered by a binding to some
    /// hashable state. When this state becomes non-`nil`, it passes an unwrapped value to the
    /// content closure. This value, however, is completely static, which prevents the popover from
    /// modifying it.
    ///
    /// This overload differs in that it passes a _binding_ to the unwrapped value, instead. This
    /// gives the popover the ability to write changes back to its source of truth.
    ///
    /// Also unlike `popover(item:)`, the binding's value does _not_ need to be hashable.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .popover(unwrapping: self.$draft) { $draft in
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
    ///   - value: A binding to an optional source of truth for the popover. When `value` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `content` closure. You
    ///     use this binding to produce content that the system presents to the user in a popover.
    ///     Changes made to the popover's binding will be reflected back in the source of truth.
    ///     Likewise, changes to `value` are instantly reflected in the popover. If `value` becomes
    ///     `nil`, the popover is dismissed.
    ///   - attachmentAnchor: The positioning anchor that defines the attachment point of the
    ///     popover.
    ///   - arrowEdge: The edge of the `attachmentAnchor` that defines the location of the popover's
    ///     arrow.
    ///   - content: A closure returning the content of the popover.
    public func popover<Value, Content: View>(
      unwrapping value: Binding<Value?>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) -> some View {
      self.popover(
        isPresented: value.isPresent(),
        attachmentAnchor: attachmentAnchor,
        arrowEdge: arrowEdge
      ) {
        Binding(unwrapping: value).map(content)
      }
    }
  }
#endif  // canImport(SwiftUI)
