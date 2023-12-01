#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS, introduced: 16, obsoleted: 17)
  @available(macOS, introduced: 13, obsoleted: 14)
  @available(tvOS, introduced: 16, obsoleted: 17)
  @available(watchOS, introduced: 9, obsoleted: 10)
  extension View {
    /// A backport of SwiftUI's `navigationDestination(item:)`.
    ///
    /// > Important: This modifier is a wrapper around `navigationDestination(isPresented:)`, which
    /// > is known to be buggy (especially pre-iOS 16.4, etc.). It is not guaranteed, nor is it
    /// > expected, to behave exactly like SwiftUI's built-in `navigationDestination(item:)`
    /// > modifier. Be sure to test both this backport and the native modifier in your application
    /// > to ensure acceptable behavior.
    public func navigationDestination<Item: Hashable, Destination: View>(
      item: Binding<Item?>,
      @ViewBuilder destination: (Item) -> Destination
    ) -> some View {
      self._navigationDestination(isPresented: item.isPresent()) {
        item.wrappedValue.map(destination)
      }
    }

    @ViewBuilder
    public func _navigationDestination<Destination: View>(
      isPresented: Binding<Bool>,
      @ViewBuilder destination: () -> Destination
    ) -> some View {
      if requiresBindWorkaround {
        self.modifier(
          _NavigationDestinationBindWorkaround(isPresented: isPresented, destination: destination())
        )
      } else {
        self.navigationDestination(isPresented: isPresented, destination: destination)
      }
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

  extension Binding {
    // NB: This should remain in sync with the public interface in the `SwiftUINavigation` module.
    fileprivate func isPresent<Wrapped>() -> Binding<Bool>
    where Value == Wrapped? {
      .init(
        get: { self.wrappedValue != nil },
        set: { isPresent, transaction in
          if !isPresent {
            self.transaction(transaction).wrappedValue = nil
          }
        }
      )
    }
  }
#endif  // canImport(SwiftUI)
