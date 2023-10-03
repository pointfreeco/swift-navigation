#if canImport(SwiftUI)
  import SwiftUI

  // NB: Deprecated after 0.5.0

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    #if swift(>=5.7)
      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func alert<Value>(
        unwrapping value: Binding<AlertState<Value>?>,
        action handler: @escaping (Value) async -> Void = { (_: Void) async in }
      ) -> some View {
        self.alert(unwrapping: value) { (value: Value?) in
          if let value = value {
            await handler(value)
          }
        }
      }

      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func alert<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, AlertState<Value>>,
        action handler: @escaping (Value) async -> Void = { (_: Void) async in }
      ) -> some View {
        self.alert(unwrapping: `enum`, case: casePath) { (value: Value?) async in
          if let value = value {
            await handler(value)
          }
        }
      }

      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func confirmationDialog<Value>(
        unwrapping value: Binding<ConfirmationDialogState<Value>?>,
        action handler: @escaping (Value) async -> Void = { (_: Void) async in }
      ) -> some View {
        self.confirmationDialog(unwrapping: value) { (value: Value?) in
          if let value = value {
            await handler(value)
          }
        }
      }

      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func confirmationDialog<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, ConfirmationDialogState<Value>>,
        action handler: @escaping (Value) async -> Void = { (_: Void) async in }
      ) -> some View {
        self.confirmationDialog(unwrapping: `enum`, case: casePath) { (value: Value?) async in
          if let value = value {
            await handler(value)
          }
        }
      }
    #else
      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func alert<Value>(
        unwrapping value: Binding<AlertState<Value>?>,
        action handler: @escaping (Value) async -> Void
      ) -> some View {
        self.alert(unwrapping: value) { (value: Value?) in
          if let value = value {
            await handler(value)
          }
        }
      }

      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func alert<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, AlertState<Value>>,
        action handler: @escaping (Value) async -> Void
      ) -> some View {
        self.alert(unwrapping: `enum`, case: casePath) { (value: Value?) async in
          if let value = value {
            await handler(value)
          }
        }
      }

      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func confirmationDialog<Value>(
        unwrapping value: Binding<ConfirmationDialogState<Value>?>,
        action handler: @escaping (Value) async -> Void
      ) -> some View {
        self.confirmationDialog(unwrapping: value) { (value: Value?) in
          if let value = value {
            await handler(value)
          }
        }
      }

      @_disfavoredOverload
      @available(
        *,
        deprecated,
        message:
          """
        'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals.
        """
      )
      public func confirmationDialog<Enum, Value>(
        unwrapping `enum`: Binding<Enum?>,
        case casePath: CasePath<Enum, ConfirmationDialogState<Value>>,
        action handler: @escaping (Value) async -> Void
      ) -> some View {
        self.confirmationDialog(unwrapping: `enum`, case: casePath) { (value: Value?) async in
          if let value = value {
            await handler(value)
          }
        }
      }
    #endif
  }

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
#endif  // canImport(SwiftUI)
