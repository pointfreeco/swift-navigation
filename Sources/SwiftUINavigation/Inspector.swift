#if canImport(SwiftUI)
  import Foundation
  import SwiftUI

  @available(iOS 17, macOS 14, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  extension View {
    /// Shows an inspector using a binding as a data source for the inspector's content.
    ///
    /// SwiftUI comes with a `inspector(isPresented:)` view modifier that is powered by a binding to
    /// a Boolean.
    ///
    /// This overload differs in that it passes a _binding_ to the unwrapped value, instead. This
    /// gives the inspector the ability to write changes back to its source of truth.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .inspector(item: $draft) { $draft in
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
    ///   - item: A binding to an optional source of truth for the inspector. When `item` is
    ///     non-`nil`, the system passes the item's content to the modifier's closure. You display
    ///     this content in an inspector that you create that the system displays to the user.
    ///   - content: A closure returning the content of the inspector.
    @_disfavoredOverload
    public func inspector<Item, Content: View>(
      item: Binding<Item?>,
      @ViewBuilder content: @escaping (Binding<Item>) -> Content
    ) -> some View {
      inspector(isPresented: Binding(item)) {
        if let defaultValue = item.wrappedValue {
          content(Binding(unwrapping: item, default: defaultValue))
        }
      }
    }

    /// Presents a sheet using a binding as a data source for the sheet's content.
    ///
    /// A version of ``SwiftUI/View/inspector(item:content:)`` that is passed an item
    /// and not a binding to an item.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the inspector. When `item` is
    ///     non-`nil`, the system passes the item's content to the modifier's closure. You display
    ///     this content in an inspector  that you create that the system displays to the user.
    ///   - content: A closure returning the content of the inspector.
    @_disfavoredOverload
    public func inspector<Item, Content: View>(
      item: Binding<Item?>,
      @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
      inspector(item: item) {
        content($0.wrappedValue)
      }
    }
  }
#endif
