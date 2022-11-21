import SwiftUI

// NB: Deprecated after 0.3.0

@available(*, deprecated, renamed: "init(_:pattern:then:else:)")
extension IfCaseLet {
  public init(
    _ `enum`: Binding<Enum>,
    pattern casePath: CasePath<Enum, Case>,
    @ViewBuilder ifContent: @escaping (Binding<Case>) -> IfContent,
    @ViewBuilder elseContent: () -> ElseContent
  ) {
    self.init(`enum`, pattern: casePath, then: ifContent, else: elseContent)
  }
}

// NB: Deprecated after 0.2.0

extension NavigationLink {
  @available(*, deprecated, renamed: "init(unwrapping:onNavigate:destination:label:)")
  public init<Value, WrappedDestination>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder destination: @escaping (Binding<Value>) -> WrappedDestination,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder label: () -> Label
  ) where Destination == WrappedDestination? {
    self.init(
      destination: Binding(unwrapping: value).map(destination),
      isActive: value.isPresent().didSet(onNavigate),
      label: label
    )
  }

  @available(*, deprecated, renamed: "init(unwrapping:case:onNavigate:destination:label:)")
  public init<Enum, Case, WrappedDestination>(
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    @ViewBuilder destination: @escaping (Binding<Case>) -> WrappedDestination,
    onNavigate: @escaping (Bool) -> Void,
    @ViewBuilder label: () -> Label
  ) where Destination == WrappedDestination? {
    self.init(
      unwrapping: `enum`.case(casePath),
      onNavigate: onNavigate,
      destination: destination,
      label: label
    )
  }
}
