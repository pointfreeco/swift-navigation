import SwiftUI

public struct WithState<Value, Content: View>: View {
  @State var value: Value
  @ViewBuilder let content: (Binding<Value>) -> Content

  public init(
    initialValue value: Value,
    @ViewBuilder content: @escaping (Binding<Value>) -> Content
  ) {
    self._value = State(wrappedValue: value)
    self.content = content
  }

  public var body: some View {
    self.content(self.$value)
  }
}
