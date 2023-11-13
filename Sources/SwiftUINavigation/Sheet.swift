#if canImport(SwiftUI)
  import SwiftUI

  #if canImport(UIKit)
    import UIKit
  #elseif canImport(AppKit)
    import AppKit
  #endif

  extension View {
    /// Presents a sheet using a binding as a data source for the sheet's content.
    ///
    /// SwiftUI comes with a `sheet(item:)` view modifier that is powered by a binding to some
    /// hashable state. When this state becomes non-`nil`, it passes an unwrapped value to the
    /// content closure. This value, however, is completely static, which prevents the sheet from
    /// modifying it.
    ///
    /// This overload differs in that it passes a _binding_ to the content closure, instead. This
    /// gives the sheet the ability to write changes back to its source of truth.
    ///
    /// Also unlike `sheet(item:)`, the binding's value does _not_ need to be hashable.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .sheet(unwrapping: self.$draft) { $draft in
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
    ///   - value: A binding to an optional source of truth for the sheet. When `value` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `content` closure. You
    ///     use this binding to produce content that the system presents to the user in a sheet.
    ///     Changes made to the sheet's binding will be reflected back in the source of truth.
    ///     Likewise, changes to `value` are instantly reflected in the sheet. If `value` becomes
    ///     `nil`, the sheet is dismissed.
    ///   - onDismiss: The closure to execute when dismissing the sheet.
    ///   - content: A closure returning the content of the sheet.
    @MainActor
    public func sheet<Value, Content>(
      unwrapping value: Binding<Value?>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) -> some View
    where Content: View {
      self.sheet(isPresented: value.isPresent(), onDismiss: onDismiss) {
        Binding(unwrapping: value).map(content)
      }
    }
  }
#endif  // canImport(SwiftUI)
