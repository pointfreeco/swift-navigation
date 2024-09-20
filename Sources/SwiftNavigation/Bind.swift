#if canImport(SwiftUI)
  import SwiftUI

  extension View {
    /// Synchronizes model state to view state via two-way bindings.
    ///
    /// SwiftUI comes with many property wrappers that can be used in views to drive view state,
    /// like field focus. Unfortunately, these property wrappers _must_ be used in views. It's not
    /// possible to extract this logic to an `@Observable` class and integrate it with the rest of
    /// the model's business logic, and be in a better position to test this state.
    ///
    /// We can work around these limitations by introducing a published field to your observable
    /// object and synchronizing it to view state with this view modifier.
    ///
    /// - Parameters:
    ///   - modelValue: A binding from model state. _E.g._, a binding derived from a field
    ///     on an observable class.
    ///   - viewValue: A binding from view state. _E.g._, a focus binding.
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    public func bind<ModelValue: _Bindable, ViewValue: _Bindable>(
      _ modelValue: ModelValue, to viewValue: ViewValue
    ) -> some View
    where ModelValue.Value == ViewValue.Value, ModelValue.Value: Equatable {
      self.modifier(_Bind(
        modelValue: modelValue.wrappedValue,
        setModelValue: { modelValue.wrappedValue = $0 },
        viewValue: viewValue.wrappedValue,
        setViewValue: { viewValue.wrappedValue = $0 }
      ))
    }
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  private struct _Bind<Value: Equatable>: ViewModifier {
    let modelValue: Value
    let setModelValue: (Value) -> Void
    let viewValue: Value
    let setViewValue: (Value) -> Void

    @State var hasAppeared = false

    func body(content: Content) -> some View {
      content
        .onAppear {
          guard !self.hasAppeared else { return }
          self.hasAppeared = true
          guard self.viewValue != self.modelValue else { return }
          self.setViewValue(self.modelValue)
        }
        .onChange(of: self.modelValue) {
          guard self.viewValue != $0 else { return }
          self.setViewValue($0)
        }
        .onChange(of: self.viewValue) {
          guard self.modelValue != $0 else { return }
          self.setModelValue($0)
        }
    }
  }

  public protocol _Bindable {
    associatedtype Value
    var wrappedValue: Value { get nonmutating set }
  }

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension AccessibilityFocusState: _Bindable {}

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension AccessibilityFocusState.Binding: _Bindable {}

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  extension AppStorage: _Bindable {}

  extension Binding: _Bindable {}

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  extension FocusedBinding: _Bindable {}

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension FocusState: _Bindable {}

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension FocusState.Binding: _Bindable {}

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  extension SceneStorage: _Bindable {}

  extension State: _Bindable {}
#endif  // canImport(SwiftUI)
