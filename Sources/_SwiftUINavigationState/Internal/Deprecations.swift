extension AlertState {
  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  public init(
    title: TextState,
    message: TextState? = nil,
    buttons: [Button]
  ) {
    self.title = title
    self.message = message
    self.buttons = buttons
  }
}
