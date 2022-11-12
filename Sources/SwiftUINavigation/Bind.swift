import SwiftUI

extension View {
  /// Synchronizes model state to view state via two-way bindings.
  ///
  /// SwiftUI comes with many property wrappers that can be used in views to drive view state, like
  /// field focus. Unfortunately, these property wrappers _must_ be used in views. It's not possible
  /// to extract this logic to an observable object and integrate it with the rest of the model's
  /// business logic, and be in a better position to test this state.
  ///
  /// We can work around these limitations by introducing a published field to your observable
  /// object and synchronizing it to view state with this view modifier.
  ///
  /// - Parameters:
  ///   - modelValue: A binding from model state. _E.g._, a binding derived from a published field
  ///     on an observable object.
  ///   - viewValue: A binding from view state. _E.g._, a focus binding.
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  public func bind<ModelValue: _Bindable, ViewValue: _Bindable>(
    _ modelValue: ModelValue, to viewValue: ViewValue
  ) -> some View
  where ModelValue.Value == ViewValue.Value, ModelValue.Value: Equatable {
    self
      .onAppear { viewValue.wrappedValue = modelValue.wrappedValue }
      .onChange(of: modelValue.wrappedValue) { viewValue.wrappedValue = $0 }
      .onChange(of: viewValue.wrappedValue) { modelValue.wrappedValue = $0 }
  }
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

public protocol _Bindable: DynamicProperty {
  associatedtype Value
  var wrappedValue: Value { get nonmutating set }
}
