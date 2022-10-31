import _SwiftUIExports

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension View {
  /// A drop-in replacement for SwiftUI's `navigationDestination(isPresented:destination:)` that
  /// works around longstanding bugs in the framework.
  ///
  /// > Important: Avoid importing both `SwiftUI` and `SwiftUINavigation` from the same file, as it
  /// > introduces ambiguity between SwiftUI's `navigationDestination` modifier and this layover.
  /// >
  /// > ```swift
  /// > import SwiftUI
  /// > import SwiftUINavigation
  /// >
  /// > // ...
  /// >
  /// > .navigationDestination(/* ... */) 🛑
  /// > ```
  /// >
  /// > Instead, simply import `SwiftUINavigation`, which re-exports SwiftUI automatically and will
  /// > favor its overlay over the original implementation:
  /// >
  /// > ```swift
  /// > import SwiftUINavigation
  /// >
  /// > // ...
  /// >
  /// > .navigationDestination(/* ... */) ✅
  /// > ```
  ///
  /// See
  /// [the framework documentation](https://developer.apple.com/documentation/swiftui/view/navigationdestination(ispresented:destination:))
  /// for more information.
  public func navigationDestination<V: View>(
    isPresented: Binding<Bool>,
    @ViewBuilder destination: () -> V
  ) -> ModifiedContent<Self, _NavigationDestination<V>> {
    self.modifier(_NavigationDestination(isPresented: isPresented, destination: destination()))
  }

  public func navigationDestination<Value, Destination: View>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder destination: (Binding<Value>) -> Destination
  ) -> some View {
    let destination = Binding(unwrapping: value).map(destination)
    return self
      .modifier(_NavigationDestination(isPresented: value.isPresent(), destination: destination))
  }

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
public struct _NavigationDestination<Destination: View>: ViewModifier {
  @Binding var isPresented: Bool
  @State var isPresentedState = false
  let destination: Destination

  public func body(content: Content) -> some View {
    content
      ._navigationDestination(isPresented: self.$isPresentedState) { destination }
      .onAppear { self.isPresented = self.isPresentedState }
      .onChange(of: self.isPresentedState) { self.isPresented = $0 }
      .onChange(of: self.isPresented) { self.isPresentedState = $0 }
  }
}
