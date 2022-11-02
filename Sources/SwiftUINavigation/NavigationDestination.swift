import _SwiftUIExports

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension View {
  /// A drop-in replacement for SwiftUI's `navigationDestination(isPresented:destination:)` that
  /// works around longstanding bugs in the framework.
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
  let destination: Destination
  @Binding var externalIsPresented: Bool
  @State var isPresented = false

  init(
    isPresented: Binding<Bool>,
    destination: Destination
  ) {
    self._externalIsPresented = isPresented
    self.destination = destination
  }

  public func body(content: Content) -> some View {
    content
      ._navigationDestination(isPresented: self.$isPresented) { self.destination }
      .onAppear { self.isPresented = self.externalIsPresented }
      .onChange(of: self.isPresented) { self.externalIsPresented = $0 }
      .onChange(of: self.externalIsPresented) { self.isPresented = $0 }
  }
}

//// NB: This view modifier works around a bug in SwiftUI's built-in modifier:
//// https://gist.github.com/mbrandonw/f8b94957031160336cac6898a919cbb7#file-fb11056434-md
//@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
//public struct _NavigationDestination<Destination: View>: ViewModifier {
//  let destination: Destination
//  @Binding var isPresented: Bool
//  @State var shouldDeepLink: Bool
//
//  init(
//    isPresented: Binding<Bool>,
//    destination: Destination
//  ) {
//    self._isPresented = isPresented
//    self.destination = destination
//    self._shouldDeepLink = State(wrappedValue: isPresented.wrappedValue)
//  }
//
//  public func body(content: Content) -> some View {
//    content
//      ._navigationDestination(
//        isPresented: Binding(
//          get: { self.shouldDeepLink ? false : self.isPresented },
//          set: { newValue, transaction in
//            self.$isPresented.transaction(transaction).wrappedValue = newValue
//          }
//        )
//      ) {
//        self.destination
//      }
//      .onAppear {
//        print("onAppear", self.shouldDeepLink, "->", false)
//        if self.shouldDeepLink {
//          self.shouldDeepLink = false
//        }
//      }
//  }
//}
//
