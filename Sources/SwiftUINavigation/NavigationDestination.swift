import SwiftUI

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension View {
  public func navigationDestination<Value, Destination: View>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder destination: (Binding<Value>) -> Destination
  ) -> some View {
    self.modifier(_NavigationDestination(unwrapping: value, destination: destination))
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
private struct _NavigationDestination<Value, Destination: View>: ViewModifier {
  @Binding var value: Value?
  @Binding var valueIsPresented: Bool
  @State var isPresented = false
  let destination: Destination?

  init(
    unwrapping value: Binding<Value?>,
    @ViewBuilder destination: (Binding<Value>) -> Destination
  ) {
    self._value = value
    self._valueIsPresented = value.isPresent()
    self.destination = Binding(unwrapping: value).map(destination)
  }

  func body(content: Content) -> some View {
    content
      .navigationDestination(isPresented: self.$isPresented) { destination }
      .onAppear { self.isPresented = self.valueIsPresented }
      .onChange(of: self.valueIsPresented) { self.isPresented = $0 }
      .onChange(of: self.isPresented) { self.valueIsPresented = $0 }
  }
}
