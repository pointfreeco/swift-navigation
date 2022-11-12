import SwiftUI

extension View {
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
