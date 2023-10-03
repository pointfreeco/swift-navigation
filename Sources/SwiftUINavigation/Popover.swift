#if canImport(SwiftUI)
  import SwiftUI

  extension View {
    /// Presents a popover using a binding as a data source for the popover's content.
    ///
    /// SwiftUI comes with a `popover(item:)` view modifier that is powered by a binding to some
    /// hashable state. When this state becomes non-`nil`, it passes an unwrapped value to the content
    /// closure. This value, however, is completely static, which prevents the popover from modifying
    /// it.
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
    ///     non-`nil`, a non-optional binding to the value is passed to the `content` closure. You use
    ///     this binding to produce content that the system presents to the user in a popover. Changes
    ///     made to the popover's binding will be reflected back in the source of truth. Likewise,
    ///     changes to `value` are instantly reflected in the popover. If `value` becomes `nil`, the
    ///     popover is dismissed.
    ///   - attachmentAnchor: The positioning anchor that defines the attachment point of the popover.
    ///   - arrowEdge: The edge of the `attachmentAnchor` that defines the location of the popover's
    ///     arrow.
    ///   - content: A closure returning the content of the popover.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Value, Content>(
      unwrapping value: Binding<Value?>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) -> some View where Content: View {
      self.popover(
        isPresented: value.isPresent(),
        attachmentAnchor: attachmentAnchor,
        arrowEdge: arrowEdge
      ) {
        Binding(unwrapping: value).map(content)
      }
    }

    /// Presents a popover using a binding and case path as the data source for the popover's content.
    ///
    /// A version of `popover(unwrapping:)` that works with enum state.
    ///
    /// - Parameters:
    ///   - enum: A binding to an optional enum that holds the source of truth for the popover at a
    ///     particular case. When `enum` is non-`nil`, and `casePath` successfully extracts a value, a
    ///     non-optional binding to the value is passed to the `content` closure. You use this binding
    ///     to produce content that the system presents to the user in a popover. Changes made to the
    ///     popover's binding will be reflected back in the source of truth. Likewise, changes to
    ///     `enum` at the given case are instantly reflected in the popover. If `enum` becomes `nil`,
    ///     or becomes a case other than the one identified by `casePath`, the popover is dismissed.
    ///   - casePath: A case path that identifies a case of `enum` that holds a source of truth for
    ///     the popover.
    ///   - attachmentAnchor: The positioning anchor that defines the attachment point of the popover.
    ///   - arrowEdge: The edge of the `attachmentAnchor` that defines the location of the popover's
    ///     arrow.
    ///   - content: A closure returning the content of the popover.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Enum, Case, Content>(
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, Case>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Binding<Case>) -> Content
    ) -> some View where Content: View {
      self.popover(
        unwrapping: `enum`.case(casePath),
        attachmentAnchor: attachmentAnchor,
        arrowEdge: arrowEdge,
        content: content
      )
    }
  }
#endif  // canImport(SwiftUI)
