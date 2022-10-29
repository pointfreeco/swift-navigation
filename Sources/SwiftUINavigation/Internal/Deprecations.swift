// NB: Deprecated after 0.2.0

extension NavigationLink {
  @available(*, deprecated, renamed: "init(unwrapping:onNavigate:destination:label:)")
  public init<Value, WrappedDestination>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder destination: (Binding<Value>) -> WrappedDestination,
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
    @ViewBuilder destination: (Binding<Case>) -> WrappedDestination,
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
