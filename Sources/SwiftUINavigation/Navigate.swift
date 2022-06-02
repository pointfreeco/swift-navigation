extension View {
  public func navigate<DestinationContent: View, Enum, Case>(
    when unwrapping: Binding<Enum?>,
    is casePath: CasePath<Enum, Case>,
    onNavigate: ((Bool) -> Void)? = nil,
    to destination: @escaping (Binding<Case>) -> DestinationContent
  ) -> some View {
    modifier(
      NavigateViewModifier(
        unwrapping: unwrapping,
        casePath: casePath,
        onNavigate: onNavigate,
        destinationContent: destination
      )
    )
  }
}

private struct NavigateViewModifier<DestinationContent: View, Enum, Case>: ViewModifier {
  let unwrapping: Binding<Enum?>
  let casePath: CasePath<Enum, Case>
  let onNavigate: ((Bool) -> Void)?
  let destinationContent: (Binding<Case>) -> DestinationContent

  func body(content: Content) -> some View {
    VStack(spacing: .zero) {
      NavigationLink(
        unwrapping: unwrapping,
        case: casePath,
        destination: destinationContent,
        onNavigate: onNavigate ?? { _ in },
        label: { EmptyView() }
      )
      content
    }
  }
}
