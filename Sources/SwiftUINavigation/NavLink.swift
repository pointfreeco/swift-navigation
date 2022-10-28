import CasePaths
import SwiftUI

@available(iOS, introduced: 14, deprecated: 16)
@available(macOS, introduced: 10.15, deprecated: 13)
@available(tvOS, introduced: 13, deprecated: 16)
@available(watchOS, introduced: 6, deprecated: 9)
public struct NavLink<Enum, Case, Destination: View, Label: View>: View {
  let `enum`: Binding<Enum?>
  let casePath: CasePath<Enum, Case>
  let onNavigate: (_ isActive: Bool) -> Void
  let destination: (Binding<Case>) -> Destination
  let label: Label

  @State var isActive = false

  public init(
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    onNavigate: @escaping (Bool) -> Void,
    destination: @escaping (Binding<Case>) -> Destination,
    label: () -> Label
  ) {
    self.enum = `enum`
    self.casePath = casePath
    self.onNavigate = onNavigate
    self.destination = destination
    self.label = label()
  }

  public init(
    unwrapping enum: Binding<Enum?>,
    onNavigate: @escaping (Bool) -> Void,
    destination: @escaping (Binding<Case>) -> Destination,
    label: () -> Label
  ) where Enum == Case {
    self.init(
      unwrapping: `enum`,
      case: /.self,
      onNavigate: onNavigate,
      destination: destination,
      label: label
    )
  }

  public var body: some View {
    NavigationLink(isActive: self.$isActive) {
      Binding(unwrapping: self.enum.case(self.casePath)).map(self.destination)
    } label: {
      self.label
    }
    .onAppear {
      self.isActive = self.enum.isPresent(self.casePath).wrappedValue
    }
    .onChange(of: self.isActive) { isActive in
      if isActive {
        // TODO: anything to do here?
        //self.onNavigate(isActive)
      } else {
        self.enum.wrappedValue = nil
      }
    }
    .onChange(of: self.enum.isPresent(self.casePath).wrappedValue) { isActive in
      self.isActive = isActive
    }
  }
}
