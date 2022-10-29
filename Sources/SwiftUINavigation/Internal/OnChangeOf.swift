import SwiftUI
import Combine

extension View {
  @_disfavoredOverload
  func _onChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
    if #available(iOS 14, *) {
      return self.onChange(of: value, perform: action)
    } else {
      return self.modifier(ChangeObserver(value: value, action: action))
    }
  }
}

private struct ChangeObserver<Value: Equatable>: ViewModifier {
  @State private var value: Value
  private let action: (Value) -> Void

  init(value: Value, action: @escaping (Value) -> Void) {
    self._value = State(wrappedValue: value)
    self.action = action
  }

  func body(content: Content) -> some View {
    content.onReceive(Just(self.value)) { newValue in
      guard self.value != newValue else { return }
      self.value = newValue
    }
  }
}
