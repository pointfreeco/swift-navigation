#if canImport(SwiftUI)
  import SwiftUI

  extension View {
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
    ///     non-optional binding to the value is passed to the `content` closure. You use this binding
    ///     to produce content that the system presents to the user in a sheet. Changes made to the
    ///     sheet's binding will be reflected back in the source of truth. Likewise, changes to
    ///     `value` are instantly reflected in the sheet. If `value` becomes `nil`, the sheet is
    ///     dismissed.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    @available(iOS 14, tvOS 14, watchOS 7, *)
    @available(macOS, unavailable)
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

    /// Presents a full-screen cover using a binding and case path as a data source for the sheet's
    /// content.
    ///
    /// A version of `fullScreenCover(unwrapping:)` that works with enum state.
    ///
    /// - Parameters:
    ///   - enum: A binding to an optional enum that holds the source of truth for the sheet at a
    ///     particular case. When `enum` is non-`nil`, and `casePath` successfully extracts a value, a
    ///     non-optional binding to the value is passed to the `content` closure. You use this binding
    ///     to produce content that the system presents to the user in a sheet. Changes made to the
    ///     sheet's binding will be reflected back in the source of truth. Likewise, changes to `enum`
    ///     at the given case are instantly reflected in the sheet. If `enum` becomes `nil`, or
    ///     becomes a case other than the one identified by `casePath`, the sheet is dismissed.
    ///   - casePath: A case path that identifies a case of `enum` that holds a source of truth for
    ///     the sheet.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    @available(iOS 14, tvOS 14, watchOS 7, *)
    @available(macOS, unavailable)
    public func fullScreenCover<Enum, Case, Content>(
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, Case>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Case>) -> Content
    ) -> some View
    where Content: View {
      self.fullScreenCover(
        unwrapping: `enum`.case(casePath), onDismiss: onDismiss, content: content)
    }
  }
#endif  // canImport(SwiftUI)
