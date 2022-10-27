import CasePaths
import SwiftUI

@available(iOS 14.0, *)
public struct LabelWrapper<Enum, Case, Label: View>: View {
  let label: Label
  @Binding var `enum`: Enum?
  let casePath: CasePath<Enum, Case>

  @State var isActive = false

  public var body: some View {
    self.label
      .onAppear {
        self.isActive = self.$enum.isPresent(self.casePath).wrappedValue
      }
      .onChange(of: self.isActive) { isActive in
        guard isActive != self.$enum.isPresent(self.casePath).wrappedValue
        else { return }

        if isActive {
          // TODO: anything to do here?
          //self.onNavigate(isActive)
        } else {
          self.enum = nil
        }
      }
      .onChange(of: self.$enum.isPresent(self.casePath).wrappedValue) { isActive in
        guard isActive != self.isActive
        else { return }

        self.isActive = isActive
      }
  }
}

@available(iOS 14.0, *)
extension NavigationLink {
  public init<Enum, Case, L: View, WD: View>(
    _unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    onNavigate: @escaping (Bool) -> Void,
    destination: @escaping (Binding<Case>) -> WD,
    label: @escaping () -> L
  ) where Label == LabelWrapper<Enum, Case, L>, Destination == WD? {
    self.init(
      unwrapping: `enum`,
      case: casePath,
      onNavigate: onNavigate,
      destination: destination,
      label: {
        LabelWrapper(label: label(), enum: `enum`, casePath: casePath)
      }
    )
//    self.enum = `enum`
//    self.casePath = casePath
//    self.onNavigate = onNavigate
//    self.destination = destination
//    self.label = LabelWrapper(label: label(), enum: `enum`, casePath: casePath)
  }
}

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

//  @State var isActive = false

  public init<L>(
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    onNavigate: @escaping (Bool) -> Void,
    destination: @escaping (Binding<Case>) -> Destination,
    label: @escaping () -> L
  ) where Label == LabelWrapper<Enum, Case, L> {
    self.enum = `enum`
    self.casePath = casePath
    self.onNavigate = onNavigate
    self.destination = destination
    self.label = LabelWrapper(label: label(), enum: `enum`, casePath: casePath)
  }

  public init<L>(
    unwrapping enum: Binding<Enum?>,
    onNavigate: @escaping (Bool) -> Void,
    destination: @escaping (Binding<Case>) -> Destination,
    label: @escaping () -> L
  ) where Enum == Case, Label == LabelWrapper<Enum, Case, L> {
    self.init(
      unwrapping: `enum`,
      case: /.self,
      onNavigate: onNavigate,
      destination: destination,
      label: label
    )
  }

  public var body: some View {
    NavigationLink(isActive: self.enum.isPresent(self.casePath)) {
      Binding(unwrapping: self.enum.case(self.casePath)).map(self.destination)
    } label: {
      self.label
    }
//    .onAppear {
//      self.isActive = self.enum.isPresent(self.casePath).wrappedValue
//    }
//    .onChange(of: self.isActive) { isActive in
//      if isActive {
//        // TODO: anything to do here?
//        //self.onNavigate(isActive)
//      } else {
//        self.enum.wrappedValue = nil
//      }
//    }
//    .onChange(of: self.enum.isPresent(self.casePath).wrappedValue) { isActive in
//      self.isActive = isActive
//    }
  }
}
