import SwiftUI

@available(iOS 16.0, *)
extension View {
  public func navigationDestination<Value, Destination: View>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder destination: (Binding<Value>) -> Destination
  ) -> some View {
    self.navigationDestination(
      isPresented: value.isPresent(),
      destination: {
        Binding(unwrapping: value).map(destination)
      }
    )
  }

  public func navigationDestination<Enum, Case, Destination: View>(
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    @ViewBuilder destination: (Binding<Case>) -> Destination
  ) -> some View {
    self.navigationDestination(unwrapping: `enum`.case(casePath), destination: destination)
  }
}
