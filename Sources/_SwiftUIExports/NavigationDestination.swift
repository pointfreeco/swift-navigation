import SwiftUI

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension View {
  // TODO: hide behind @_spi?
  public func _navigationDestination<V: View>(
    isPresented: Binding<Bool>,
    @ViewBuilder destination: () -> V
  ) -> some View {
    self.navigationDestination(isPresented: isPresented, destination: destination)
  }
}
