#if canImport(SwiftUI)
  import SwiftUI

  /// A container view that provides a binding to another view.
  ///
  /// This view is most helpful for creating Xcode previews of views that require bindings.
  ///
  /// For example, if you wanted to create a preview for a text field, you cannot simply introduce
  /// some `@State` to the preview since `previews` is static:
  ///
  /// ```swift
  /// struct TextField_Previews: PreviewProvider {
  ///   @State static var text = ""  // ⚠️ @State static does not work.
  ///
  ///   static var previews: some View {
  ///     TextField("Test", text: self.$text)
  ///   }
  /// }
  /// ```
  ///
  /// So, instead you can use ``WithState``:
  ///
  /// ```swift
  /// struct TextField_Previews: PreviewProvider {
  ///   static var previews: some View {
  ///     WithState(initialValue: "") { $text in
  ///       TextField("Test", text: $text)
  ///     }
  ///   }
  /// }
  /// ```
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
#endif  // canImport(SwiftUI)
