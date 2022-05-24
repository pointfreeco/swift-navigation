
extension View {
    /// Presents an overlay using a bind as a data source for the overlay's content.
    ///
    /// - Parameters:
    ///   - value: A binding to a source of truth for the overlay. When `value` is non-`nil`, a
    ///     non-optional binding to the value is passed to the `content` closure. You use this binding
    ///     to produce content that the system presents to the user in an overlay. Changes made to the
    ///     overlay's binding will be reflected back in the source or truth. Likewise, changes to
    ///     `value` are instantly reflected in the modal. If `value` becomes `nil`, the overlay is
    ///     dismissed.
    ///   - onDismiss: The closure to execute when dismissing the overlay.
    ///   - content: A closure returning the content of the modal.
    public func overlay<Value, Content>(
      unwrapping value: Binding<Value?>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) -> some View
    where Content: View {
        self.overlay(
            Group {
                if value.isPresent().wrappedValue {
                    Binding(unwrapping: value).map(content)
                }
            }
        )
    }
    
    /// Presents an overlay using a binding and case path as a data source for the overlay's
    /// content.
    ///
    /// A version of `overlay(unwrapping:)` that works with enum state.
    ///
    /// - Parameters:
    ///   - enum: A binding to an optional enum that holds the source of truth for the overlay at a
    ///     particular case. When `enum` is non-`nil`, and `casePath` successfully extracts a value, a
    ///     non-optional binding to the value is passed to the `content` closure. You use this binding
    ///     to produce content that the system presents to the user in an overlay. Changes made to the
    ///     overlay's binding will be reflected back in the source of truth. Likewise, change to `enum`
    ///     at the given case are instantly reflected in the overlay. If `enum` becomes `nil`, or
    ///     becomes a case other than the one identified by `casePath`, the overlay is dismissed.
    ///   - casePath: A case path that identifies a case of `enum` that holds a source of truth for
    ///     the overlay.
    ///   - onDismiss: The closure to execute when dismissing the overlay.
    ///   - content: A closure returning the content of the overlay.
    public func overlay<Enum, Case, Content>(
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, Case>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Case>) -> Content
    ) -> some View
    where Content: View {
        self.overlay(unwrapping: `enum`.case(casePath), onDismiss: onDismiss, content: content)
    }
}
