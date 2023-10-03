#if swift(>=5.7) && canImport(SwiftUI)
  import SwiftUI

  @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
  extension View {
    /// Pushes a view onto a `NavigationStack` using a binding as a data source for the
    /// destination's content.
    ///
    /// This is a version of SwiftUI's `navigationDestination(isPresented:)` modifier, but powered
    /// by a binding to optional state instead of a binding to a boolean. When state becomes
    /// non-`nil`, a _binding_ to the unwrapped value is passed to the destination closure.
    ///
    /// ```swift
    /// struct TimelineView: View {
    ///   @State var draft: Post?
    ///
    ///   var body: Body {
    ///     Button("Compose") {
    ///       self.draft = Post()
    ///     }
    ///     .navigationDestination(unwrapping: self.$draft) { $draft in
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
    ///   - value: A binding to an optional source of truth for the destination. When `value` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `destination` closure.
    ///     You use this binding to produce content that the system pushes to the user in a
    ///     navigation stack. Changes made to the destination's binding will be reflected back in
    ///     the source of truth. Likewise, changes to `value` are instantly reflected in the
    ///     destination. If `value` becomes `nil`, the destination is popped.
    ///   - destination: A closure returning the content of the destination.
    @ViewBuilder
    public func navigationDestination<Value, Destination: View>(
      unwrapping value: Binding<Value?>,
      @ViewBuilder destination: (Binding<Value>) -> Destination
    ) -> some View {
      if requiresBindWorkaround {
        self.modifier(
          _NavigationDestinationBindWorkaround(
            isPresented: value.isPresent(),
            destination: Binding(unwrapping: value).map(destination)
          )
        )
      } else {
        self.navigationDestination(isPresented: value.isPresent()) {
          Binding(unwrapping: value).map(destination)
        }
      }
    }

    /// Pushes a view onto a `NavigationStack` using a binding and case path as a data source for
    /// the destination's content.
    ///
    /// A version of `View.navigationDestination(unwrapping:)` that works with enum state.
    ///
    /// - Parameters:
    ///   - enum: A binding to an optional enum that holds the source of truth for the destination
    ///     at a particular case. When `enum` is non-`nil`, and `casePath` successfully extracts a
    ///     value, a non-optional binding to the value is passed to the `content` closure. You use
    ///     this binding to produce content that the system pushes to the user in a navigation
    ///     stack. Changes made to the destination's binding will be reflected back in the source of
    ///     truth. Likewise, changes to `enum` at the given case are instantly reflected in the
    ///     destination. If `enum` becomes `nil`, or becomes a case other than the one identified by
    ///     `casePath`, the destination is popped.
    ///   - casePath: A case path that identifies a case of `enum` that holds a source of truth for
    ///     the destination.
    ///   - destination: A closure returning the content of the destination.
    public func navigationDestination<Enum, Case, Destination: View>(
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, Case>,
      @ViewBuilder destination: (Binding<Case>) -> Destination
    ) -> some View {
      self.navigationDestination(unwrapping: `enum`.case(casePath), destination: destination)
    }
  }

  // NB: This view modifier works around a bug in SwiftUI's built-in modifier:
  // https://gist.github.com/mbrandonw/f8b94957031160336cac6898a919cbb7#file-fb11056434-md
  @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
  private struct _NavigationDestinationBindWorkaround<Destination: View>: ViewModifier {
    @Binding var isPresented: Bool
    let destination: Destination

    @State private var isPresentedState = false

    public func body(content: Content) -> some View {
      content
        .navigationDestination(isPresented: self.$isPresentedState) { self.destination }
        .bind(self.$isPresented, to: self.$isPresentedState)
    }
  }

  private let requiresBindWorkaround = {
    if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
      return true
    }
    guard #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    else { return true }
    return false
  }()
#endif  // swift(>=5.7) && canImport(SwiftUI)
