#if canImport(SwiftUI)
  import SwiftUI
  @_spi(RuntimeWarn) import SwiftUINavigationCore

  // NB: Deprecated after 1.2.1

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    @available(*, deprecated, renamed: "alert(item:title:actions:message:)")
    public func alert<Value, A: View, M: View>(
      title: (Value) -> Text,
      unwrapping value: Binding<Value?>,
      @ViewBuilder actions: (Value) -> A,
      @ViewBuilder message: (Value) -> M
    ) -> some View {
      alert(item: value, title: title, actions: actions, message: message)
    }

    @available(
      *, deprecated, renamed: "confirmationDialog(item:titleVisibility:title:actions:message:)"
    )
    public func confirmationDialog<Value, A: View, M: View>(
      title: (Value) -> Text,
      titleVisibility: Visibility = .automatic,
      unwrapping value: Binding<Value?>,
      @ViewBuilder actions: (Value) -> A,
      @ViewBuilder message: (Value) -> M
    ) -> some View {
      self.confirmationDialog(
        value.wrappedValue.map(title) ?? Text(verbatim: ""),
        isPresented: value.isPresent(),
        titleVisibility: titleVisibility,
        presenting: value.wrappedValue,
        actions: actions,
        message: message
      )
    }
  }

  // NB: Deprecated after 1.0.2

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    @available(*, deprecated, renamed: "alert(_:action:)")
    public func alert<Value>(
      unwrapping value: Binding<AlertState<Value>?>,
      action handler: @escaping (Value?) -> Void = { (_: Never?) in }
    ) -> some View {
      alert(
        (value.wrappedValue?.title).map(Text.init) ?? Text(verbatim: ""),
        isPresented: value.isPresent(),
        presenting: value.wrappedValue,
        actions: {
          ForEach($0.buttons) {
            Button($0, action: handler)
          }
        },
        message: { $0.message.map { Text($0) } }
      )
    }

    @available(*, deprecated, renamed: "alert(_:action:)")
    public func alert<Value>(
      unwrapping value: Binding<AlertState<Value>?>,
      action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
    ) -> some View {
      alert(
        (value.wrappedValue?.title).map(Text.init) ?? Text(verbatim: ""),
        isPresented: value.isPresent(),
        presenting: value.wrappedValue,
        actions: {
          ForEach($0.buttons) {
            Button($0, action: handler)
          }
        },
        message: { $0.message.map { Text($0) } }
      )
    }

    @available(*, deprecated, renamed: "confirmationDialog(_:action:)")
    public func confirmationDialog<Value>(
      unwrapping value: Binding<ConfirmationDialogState<Value>?>,
      action handler: @escaping (Value?) -> Void = { (_: Never?) in }
    ) -> some View {
      confirmationDialog(
        value.wrappedValue.flatMap { Text($0.title) } ?? Text(verbatim: ""),
        isPresented: value.isPresent(),
        titleVisibility: value.wrappedValue.map { .init($0.titleVisibility) } ?? .automatic,
        presenting: value.wrappedValue,
        actions: {
          ForEach($0.buttons) {
            Button($0, action: handler)
          }
        },
        message: { $0.message.map { Text($0) } }
      )
    }

    @available(*, deprecated, renamed: "confirmationDialog(_:action:)")
    public func confirmationDialog<Value>(
      unwrapping value: Binding<ConfirmationDialogState<Value>?>,
      action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
    ) -> some View {
      confirmationDialog(
        value.wrappedValue.flatMap { Text($0.title) } ?? Text(verbatim: ""),
        isPresented: value.isPresent(),
        titleVisibility: value.wrappedValue.map { .init($0.titleVisibility) } ?? .automatic,
        presenting: value.wrappedValue,
        actions: {
          ForEach($0.buttons) {
            Button($0, action: handler)
          }
        },
        message: { $0.message.map { Text($0) } }
      )
    }
  }

  extension View {
    @available(
      iOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 12, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 8, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func alert<Enum, Case, A: View, M: View>(
      title: (Case) -> Text,
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, Case>,
      @ViewBuilder actions: (Case) -> A,
      @ViewBuilder message: (Case) -> M
    ) -> some View {
      alert(
        item: `enum`.case(casePath),
        title: title,
        actions: actions,
        message: message
      )
    }

    @available(
      iOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 12, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 8, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func alert<Enum, Value>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, AlertState<Value>>,
      action handler: @escaping (Value?) -> Void = { (_: Never?) in }
    ) -> some View {
      alert(`enum`.case(casePath), action: handler)
    }

    @available(
      iOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 12, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 8, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func alert<Enum, Value>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, AlertState<Value>>,
      action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
    ) -> some View {
      alert(`enum`.case(casePath), action: handler)
    }

    @available(
      iOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 12, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 8, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func confirmationDialog<Enum, Case, A: View, M: View>(
      title: (Case) -> Text,
      titleVisibility: Visibility = .automatic,
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, Case>,
      @ViewBuilder actions: (Case) -> A,
      @ViewBuilder message: (Case) -> M
    ) -> some View {
      confirmationDialog(
        item: `enum`.case(casePath),
        titleVisibility: titleVisibility,
        title: title,
        actions: actions,
        message: message
      )
    }

    @available(
      iOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 12, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 8, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func confirmationDialog<Enum, Value>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, ConfirmationDialogState<Value>>,
      action handler: @escaping (Value?) -> Void = { (_: Never?) in }
    ) -> some View {
      confirmationDialog(
        `enum`.case(casePath),
        action: handler
      )
    }

    @available(
      iOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 12, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 8, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func confirmationDialog<Enum, Value>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, ConfirmationDialogState<Value>>,
      action handler: @escaping (Value?) async -> Void = { (_: Never?) async in }
    ) -> some View {
      confirmationDialog(
        `enum`.case(casePath),
        action: handler
      )
    }

    @available(
      iOS, introduced: 14, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(macOS, unavailable)
    @available(
      tvOS, introduced: 14, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 7, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func fullScreenCover<Enum, Case, Content>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, Case>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Case>) -> Content
    ) -> some View
    where Content: View {
      fullScreenCover(
        unwrapping: `enum`.case(casePath), onDismiss: onDismiss, content: content)
    }

    @available(
      iOS, introduced: 16, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 13, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 16, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 9, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func navigationDestination<Enum, Case, Destination: View>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, Case>,
      @ViewBuilder destination: (Binding<Case>) -> Destination
    ) -> some View {
      navigationDestination(unwrapping: `enum`.case(casePath), destination: destination)
    }

    @available(
      iOS, introduced: 13, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 10.15, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func popover<Enum, Case, Content>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, Case>,
      attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
      arrowEdge: Edge = .top,
      @ViewBuilder content: @escaping (Binding<Case>) -> Content
    ) -> some View where Content: View {
      popover(
        unwrapping: `enum`.case(casePath),
        attachmentAnchor: attachmentAnchor,
        arrowEdge: arrowEdge,
        content: content
      )
    }

    @available(
      iOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @MainActor
    public func sheet<Enum, Case, Content>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, Case>,
      onDismiss: (() -> Void)? = nil,
      @ViewBuilder content: @escaping (Binding<Case>) -> Content
    ) -> some View
    where Content: View {
      sheet(unwrapping: `enum`.case(casePath), onDismiss: onDismiss, content: content)
    }
  }

  extension Binding {
    @available(
      iOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public init?<Enum>(unwrapping enum: Binding<Enum>, case casePath: AnyCasePath<Enum, Value>) {
      guard var `case` = casePath.extract(from: `enum`.wrappedValue)
      else { return nil }

      self.init(
        get: {
          `case` = casePath.extract(from: `enum`.wrappedValue) ?? `case`
          return `case`
        },
        set: {
          guard casePath.extract(from: `enum`.wrappedValue) != nil else { return }
          `case` = $0
          `enum`.transaction($1).wrappedValue = casePath.embed($0)
        }
      )
    }

    @available(
      iOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func `case`<Enum, Case>(_ casePath: AnyCasePath<Enum, Case>) -> Binding<Case?>
    where Value == Enum? {
      .init(
        get: { self.wrappedValue.flatMap(casePath.extract(from:)) },
        set: { newValue, transaction in
          self.transaction(transaction).wrappedValue = newValue.map(casePath.embed)
        }
      )
    }

    @available(
      iOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, deprecated: 9999,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public func isPresent<Enum, Case>(_ casePath: AnyCasePath<Enum, Case>) -> Binding<Bool>
    where Value == Enum? {
      self.case(casePath).isPresent()
    }
  }

  public struct IfCaseLet<Enum, Case, IfContent, ElseContent>: View
  where IfContent: View, ElseContent: View {
    public let `enum`: Binding<Enum>
    public let casePath: AnyCasePath<Enum, Case>
    public let ifContent: (Binding<Case>) -> IfContent
    public let elseContent: ElseContent

    @available(
      iOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    @available(
      macOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    @available(
      tvOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    @available(
      watchOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    public init(
      _ enum: Binding<Enum>,
      pattern casePath: AnyCasePath<Enum, Case>,
      @ViewBuilder then ifContent: @escaping (Binding<Case>) -> IfContent,
      @ViewBuilder else elseContent: () -> ElseContent
    ) {
      self.casePath = casePath
      self.elseContent = elseContent()
      self.enum = `enum`
      self.ifContent = ifContent
    }

    public var body: some View {
      if let $case = Binding(unwrapping: self.enum, case: self.casePath) {
        self.ifContent($case)
      } else {
        self.elseContent
      }
    }
  }

  @available(
    iOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  @available(
    macOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  @available(
    tvOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  @available(
    watchOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  extension IfCaseLet where ElseContent == EmptyView {
    public init(
      _ enum: Binding<Enum>,
      pattern casePath: AnyCasePath<Enum, Case>,
      @ViewBuilder ifContent: @escaping (Binding<Case>) -> IfContent
    ) {
      self.casePath = casePath
      elseContent = EmptyView()
      self.enum = `enum`
      self.ifContent = ifContent
    }
  }

  public struct IfLet<Value, IfContent, ElseContent>: View
  where IfContent: View, ElseContent: View {
    public let value: Binding<Value?>
    public let ifContent: (Binding<Value>) -> IfContent
    public let elseContent: ElseContent

    @available(
      iOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    @available(
      macOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    @available(
      tvOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    @available(
      watchOS, deprecated: 9999,
      message:
        "Use '$enum.case.map { $case in … }' (and 'if !enum.is(\\.case) { … }' if you have an 'else' branch) with a '@CasePathable' enum, instead."
    )
    public init(
      _ value: Binding<Value?>,
      @ViewBuilder then ifContent: @escaping (Binding<Value>) -> IfContent,
      @ViewBuilder else elseContent: () -> ElseContent
    ) {
      self.value = value
      self.ifContent = ifContent
      self.elseContent = elseContent()
    }

    public var body: some View {
      if let $value = Binding(unwrapping: self.value) {
        self.ifContent($value)
      } else {
        self.elseContent
      }
    }
  }

  @available(
    iOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  @available(
    macOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  @available(
    tvOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  @available(
    watchOS, deprecated: 9999,
    message: "Use '$enum.case.map { $case in … }' with a '@CasePathable' enum, instead."
  )
  extension IfLet where ElseContent == EmptyView {
    public init(
      _ value: Binding<Value?>,
      @ViewBuilder then ifContent: @escaping (Binding<Value>) -> IfContent
    ) {
      self.init(value, then: ifContent, else: { EmptyView() })
    }
  }

  extension NavigationLink {
    @available(
      iOS, introduced: 13, deprecated: 16,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      macOS, introduced: 10.15, deprecated: 13,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      tvOS, introduced: 13, deprecated: 16,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    @available(
      watchOS, introduced: 6, deprecated: 9,
      message:
        "Chain a '@CasePathable' enum binding into a case directly instead of specifying a case path."
    )
    public init<Enum, Case, WrappedDestination>(
      unwrapping enum: Binding<Enum?>,
      case casePath: AnyCasePath<Enum, Case>,
      onNavigate: @escaping (Bool) -> Void,
      @ViewBuilder destination: @escaping (Binding<Case>) -> WrappedDestination,
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

  @available(
    iOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    macOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    tvOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    watchOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  public struct Switch<Enum, Content: View>: View {
    public let `enum`: Binding<Enum>
    public let content: Content

    private init(
      enum: Binding<Enum>,
      @ViewBuilder content: () -> Content
    ) {
      self.enum = `enum`
      self.content = content()
    }

    public var body: some View {
      self.content
        .environmentObject(BindingObject(binding: self.enum))
    }
  }

  @available(
    iOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    macOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    tvOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    watchOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  public struct CaseLet<Enum, Case, Content>: View
  where Content: View {
    @EnvironmentObject private var `enum`: BindingObject<Enum>
    public let casePath: AnyCasePath<Enum, Case>
    public let content: (Binding<Case>) -> Content

    public init(
      _ casePath: AnyCasePath<Enum, Case>,
      @ViewBuilder then content: @escaping (Binding<Case>) -> Content
    ) {
      self.casePath = casePath
      self.content = content
    }

    public var body: some View {
      Binding(unwrapping: self.enum.wrappedValue, case: self.casePath).map(self.content)
    }
  }

  @available(
    iOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    macOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    tvOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    watchOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  public struct Default<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    public var body: some View {
      self.content
    }
  }

  @available(
    iOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    macOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    tvOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  @available(
    watchOS, deprecated: 9999,
    message:
      "Switch over a '@CasePathable' enum and derive bindings from each case using '$enum.case.map { $case in … }', instead."
  )
  extension Switch {
    public init<Case1, Content1, DefaultContent>(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        CaseLet<Enum, Case1, Content1>,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else {
          content.1
        }
      }
    }

    public init<Case1, Content1>(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> CaseLet<Enum, Case1, Content1>
    )
    where
      Content == _ConditionalContent<
        CaseLet<Enum, Case1, Content1>,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      self.init(`enum`) {
        content()
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<Case1, Content1, Case2, Content2, DefaultContent>(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else {
          content.2
        }
      }
    }

    public init<Case1, Content1, Case2, Content2>(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        _ConditionalContent<
          CaseLet<Enum, Case3, Content3>,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else if content.2.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.2
        } else {
          content.3
        }
      }
    }

    public init<Case1, Content1, Case2, Content2, Case3, Content3>(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        _ConditionalContent<
          CaseLet<Enum, Case3, Content3>,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else if content.2.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.2
        } else if content.3.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.3
        } else {
          content.4
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case5, Content5>,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else if content.2.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.2
        } else if content.3.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.3
        } else if content.4.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.4
        } else {
          content.5
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case5, Content5>,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else if content.2.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.2
        } else if content.3.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.3
        } else if content.4.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.4
        } else if content.5.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.5
        } else {
          content.6
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case7, Content7>,
            Default<DefaultContent>
          >
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else if content.2.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.2
        } else if content.3.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.3
        } else if content.4.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.4
        } else if content.5.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.5
        } else if content.6.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.6
        } else {
          content.7
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case7, Content7>,
            Default<_ExhaustivityCheckView<Enum>>
          >
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        content.value.6
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else if content.2.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.2
        } else if content.3.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.3
        } else if content.4.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.4
        } else if content.5.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.5
        } else if content.6.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.6
        } else if content.7.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.7
        } else {
          content.8
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        content.value.6
        content.value.7
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8,
      Case9, Content9,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>,
          CaseLet<Enum, Case9, Content9>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case9, Content9>,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.0
        } else if content.1.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.1
        } else if content.2.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.2
        } else if content.3.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.3
        } else if content.4.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.4
        } else if content.5.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.5
        } else if content.6.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.6
        } else if content.7.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.7
        } else if content.8.casePath.extract(from: `enum`.wrappedValue) != nil {
          content.8
        } else {
          content.9
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8,
      Case9, Content9
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>,
          CaseLet<Enum, Case9, Content9>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case9, Content9>,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        content.value.6
        content.value.7
        content.value.8
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }
  }

  public struct _ExhaustivityCheckView<Enum>: View {
    @EnvironmentObject private var `enum`: BindingObject<Enum>
    let file: StaticString
    let line: UInt

    public var body: some View {
      #if DEBUG
        let message = """
          Warning: Switch.body@\(self.file):\(self.line)

          "Switch" did not handle "\(describeCase(self.enum.wrappedValue.wrappedValue))"

          Make sure that you exhaustively provide a "CaseLet" view for each case in "\(Enum.self)", \
          provide a "Default" view at the end of the "Switch", or use an "IfCaseLet" view instead.
          """
        VStack(spacing: 17) {
          self.exclamation()
            .font(.largeTitle)

          Text(message)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(.white)
        .padding()
        .background(Color.red.edgesIgnoringSafeArea(.all))
        .onAppear { runtimeWarn(message, file: self.file, line: self.line) }
      #else
        EmptyView()
      #endif
    }

    func exclamation() -> some View {
      #if os(macOS)
        return Text("⚠️")
      #else
        return Image(systemName: "exclamationmark.triangle.fill")
      #endif
    }
  }

  private class BindingObject<Value>: ObservableObject {
    let wrappedValue: Binding<Value>

    init(binding: Binding<Value>) {
      wrappedValue = binding
    }
  }

  private func describeCase<Enum>(_ enum: Enum) -> String {
    let mirror = Mirror(reflecting: `enum`)
    let `case`: String
    if mirror.displayStyle == .enum, let child = mirror.children.first, let label = child.label {
      let childMirror = Mirror(reflecting: child.value)
      let associatedValuesMirror =
        childMirror.displayStyle == .tuple
        ? childMirror
        : Mirror(`enum`, unlabeledChildren: [child.value], displayStyle: .tuple)
      `case` = """
        \(label)(\
        \(associatedValuesMirror.children.map { "\($0.label ?? "_"):" }.joined())\
        )
        """
    } else {
      `case` = "\(`enum`)"
    }
    var type = String(reflecting: Enum.self)
    if let index = type.firstIndex(of: ".") {
      type.removeSubrange(...index)
    }
    return "\(type).\(`case`)"
  }

  // NB: Deprecated after 0.5.0

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension View {
    @_disfavoredOverload
    @available(
      *,
      deprecated,
      message:
        "'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals."
    )
    public func alert<Value>(
      unwrapping value: Binding<AlertState<Value>?>,
      action handler: @escaping (Value) async -> Void = { (_: Void) async in }
    ) -> some View {
      alert(value) { (value: Value?) in
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
        "'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals."
    )
    public func alert<Enum, Value>(
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, AlertState<Value>>,
      action handler: @escaping (Value) async -> Void = { (_: Void) async in }
    ) -> some View {
      alert(unwrapping: `enum`, case: casePath) { (value: Value?) async in
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
        "'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals."
    )
    public func confirmationDialog<Value>(
      unwrapping value: Binding<ConfirmationDialogState<Value>?>,
      action handler: @escaping (Value) async -> Void = { (_: Void) async in }
    ) -> some View {
      confirmationDialog(unwrapping: value) { (value: Value?) in
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
        "'View.alert' now passes an optional action to its handler to allow you to handle action-less dismissals."
    )
    public func confirmationDialog<Enum, Value>(
      unwrapping enum: Binding<Enum?>,
      case casePath: CasePath<Enum, ConfirmationDialogState<Value>>,
      action handler: @escaping (Value) async -> Void = { (_: Void) async in }
    ) -> some View {
      confirmationDialog(unwrapping: `enum`, case: casePath) { (value: Value?) async in
        if let value = value {
          await handler(value)
        }
      }
    }
  }

  // NB: Deprecated after 0.3.0

  @available(*, deprecated, renamed: "init(_:pattern:then:else:)")
  extension IfCaseLet {
    public init(
      _ enum: Binding<Enum>,
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
