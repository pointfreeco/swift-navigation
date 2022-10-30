/// A view that controls a navigation presentation.
///
/// See
/// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink)
/// for more information.
public struct NavigationLink<Label: View, Destination: View>: View {
  private let navigationLink: (Binding<Bool>) -> SwiftUI.NavigationLink<Label, Destination>
  #if os(iOS)
    private var _isDetailLink = true
  #endif
  @State var isPresented = false
  @Binding var valueIsPresented: Bool

  #if os(iOS)
    public var body: some View {
      self.navigationLink(self.$isPresented)
        .isDetailLink(self._isDetailLink)
        .onAppear { self.isPresented = self.valueIsPresented }
        ._onChange(of: self.isPresented) { self.valueIsPresented = $0 }
        ._onChange(of: self.valueIsPresented) { self.isPresented = $0 }
    }
  #else
    public var body: some View {
      self.navigationLink
        .onAppear { self.isPresented = self.valueIsPresented }
        ._onChange(of: self.isPresented) { self.valueIsPresented = $0 }
        ._onChange(of: self.valueIsPresented) { self.isPresented = $0 }
    }
  #endif
}

extension NavigationLink {
  fileprivate init(navigationLink: SwiftUI.NavigationLink<Label, Destination>) {
    self.navigationLink = { _ in navigationLink }
    self._valueIsPresented = Binding(initialValue: false)
  }
}

extension NavigationLink {
  /// Creates a navigation link that presents the destination view when a bound value is non-`nil`.
  ///
  /// This allows you to drive navigation to a destination from an optional value. When the
  /// optional value becomes non-`nil` a binding to an honest value is derived and passed to the
  /// destination. Any edits made to the binding in the destination are automatically reflected
  /// in the parent.
  ///
  /// ```swift
  /// struct ContentView: View {
  ///   @State var postToEdit: Post?
  ///   @State var posts: [Post]
  ///
  ///   var body: some View {
  ///     ForEach(self.posts) { post in
  ///       NavigationLink(unwrapping: self.$postToEdit) { isActive in
  ///         self.postToEdit = isActive ? post : nil
  ///       } destination: { $draft in
  ///         EditPostView(post: $draft)
  ///       } label: {
  ///         Text(post.title)
  ///       }
  ///     }
  ///   }
  /// }
  ///
  /// struct EditPostView: View {
  ///   @Binding var post: Post
  ///   var body: some View { ... }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - value: A binding to an optional source of truth for the destination. When `value` is
  ///     non-`nil`, a non-optional binding to the value is passed to the `destination` closure. The
  ///     destination can use this binding to produce its content and write changes back to the
  ///     source of truth. Upstream changes to `value` will also be instantly reflected in the
  ///     destination. If `value` becomes `nil`, the destination is dismissed.
  ///   - onNavigate: A closure that executes when the link becomes active or inactive with a
  ///     boolean that describes if the link was activated or not. Use this closure to populate the
  ///     source of truth when it is passed a value of `true`. When passed `false`, the system will
  ///     automatically write `nil` to `value`.
  ///   - destination: A view for the navigation link to present.
  ///   - label: A view builder to produce a label describing the `destination` to present.
  @available(iOS, introduced: 13, deprecated: 16)
  @available(macOS, introduced: 10.15, deprecated: 13)
  @available(tvOS, introduced: 13, deprecated: 16)
  @available(watchOS, introduced: 6, deprecated: 9)
  public init<Value, WrappedDestination>(
    unwrapping value: Binding<Value?>,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder destination: (Binding<Value>) -> WrappedDestination,
    @ViewBuilder label: () -> Label
  ) where Destination == WrappedDestination? {
    var willDeepLink = value.isPresent().wrappedValue
    self.init(
      destination: Binding(unwrapping: value).map(destination),
      isActive: value.isPresent().didSet {
        if !willDeepLink {
          onNavigate($0)
        } else {
          willDeepLink = false
        }
      },
      label: label
    )
  }

  /// Creates a navigation link that presents the destination view when a bound value is non-`nil`.
  ///
  /// An overload of ``init(unwrapping:onNavigate:destination:label:)`` that takes a string title
  /// instead of a label.
  @available(iOS, introduced: 13, deprecated: 16)
  @available(macOS, introduced: 10.15, deprecated: 13)
  @available(tvOS, introduced: 13, deprecated: 16)
  @available(watchOS, introduced: 6, deprecated: 9)
  @_disfavoredOverload
  public init<Value, WrappedDestination, S: StringProtocol>(
    _ title: S,
    unwrapping value: Binding<Value?>,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder destination: (Binding<Value>) -> WrappedDestination,
    @ViewBuilder label: () -> Label
  ) where Destination == WrappedDestination?, Label == Text {
    self.init(
      unwrapping: value,
      onNavigate: onNavigate,
      destination: destination
    ) {
      Text(title)
    }
  }

  /// Creates a navigation link that presents the destination view when a bound value is non-`nil`.
  ///
  /// An overload of ``init(unwrapping:onNavigate:destination:label:)`` that takes a localized title
  /// instead of a label.
  @available(iOS, introduced: 13, deprecated: 16)
  @available(macOS, introduced: 10.15, deprecated: 13)
  @available(tvOS, introduced: 13, deprecated: 16)
  @available(watchOS, introduced: 6, deprecated: 9)
  public init<Value, WrappedDestination>(
    _ titleKey: LocalizedStringKey,
    unwrapping value: Binding<Value?>,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder destination: (Binding<Value>) -> WrappedDestination,
    @ViewBuilder label: () -> Label
  ) where Destination == WrappedDestination?, Label == Text {
    self.init(
      unwrapping: value,
      onNavigate: onNavigate,
      destination: destination
    ) {
      Text(titleKey)
    }
  }

  /// Creates a navigation link that presents the destination view when a bound enum is non-`nil`
  /// and matches a particular case.
  ///
  /// This allows you to drive navigation to a destination from an enum of values. When the
  /// optional value becomes non-`nil` _and_ matches a particular case of the enum, a binding to an
  /// honest value is derived and passed to the destination. Any edits made to the binding in the
  /// destination are automatically reflected in the parent.
  ///
  /// ```swift
  /// struct ContentView: View {
  ///   @State var route: Route?
  ///   @State var posts: [Post]
  ///
  ///   enum Route {
  ///     case edit(Post)
  ///     /* other routes */
  ///   }
  ///
  ///   var body: some View {
  ///     ForEach(self.posts) { post in
  ///       NavigationLink(unwrapping: self.$route, case: /Route.edit) { isActive in
  ///         self.route = isActive ? .edit(post) : nil
  ///       } destination: { $draft in
  ///         EditPostView(post: $draft)
  ///       } label: {
  ///         Text(post.title)
  ///       }
  ///     }
  ///   }
  /// }
  ///
  /// struct EditPostView: View {
  ///   @Binding var post: Post
  ///   var body: some View { ... }
  /// }
  /// ```
  ///
  /// See `NavigationLink.init(unwrapping:destination:onNavigate:label)` for a version of this
  /// initializer that works with optional state instead of enum state.
  ///
  /// - Parameters:
  ///   - enum: A binding to an optional source of truth for the destination. When `enum` is
  ///     non-`nil`, and `casePath` successfully extracts a value, a non-optional binding to the
  ///     value is passed to the `destination` closure. The destination can use this binding to
  ///     produce its content and write changes back to the source of truth. Upstream changes to
  ///     `enum` will also be instantly reflected in the destination. If `enum` becomes `nil`, the
  ///     destination is dismissed.
  ///   - onNavigate: A closure that executes when the link becomes active or inactive with a
  ///     boolean that describes if the link was activated or not. Use this closure to populate the
  ///     source of truth when it is passed a value of `true`. When passed `false`, the system will
  ///     automatically write `nil` to `enum`.
  ///   - destination: A view for the navigation link to present.
  ///   - label: A view builder to produce a label describing the `destination` to present.
  @available(iOS, introduced: 13, deprecated: 16)
  @available(macOS, introduced: 10.15, deprecated: 13)
  @available(tvOS, introduced: 13, deprecated: 16)
  @available(watchOS, introduced: 6, deprecated: 9)
  public init<Enum, Case, WrappedDestination>(
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder destination: (Binding<Case>) -> WrappedDestination,
    @ViewBuilder label: () -> Label
  ) where Destination == WrappedDestination? {
    self.init(
      unwrapping: `enum`.case(casePath),
      onNavigate: onNavigate,
      destination: destination,
      label: label
    )
  }

  /// Creates a navigation link that presents the destination view when a bound enum is non-`nil`
  /// and matches a particular case.
  ///
  /// An overload of ``init(unwrapping:case:onNavigate:destination:label:)`` that takes a string
  /// title instead of a label.
  @available(iOS, introduced: 13, deprecated: 16)
  @available(macOS, introduced: 10.15, deprecated: 13)
  @available(tvOS, introduced: 13, deprecated: 16)
  @available(watchOS, introduced: 6, deprecated: 9)
  public init<Enum, Case, WrappedDestination, S: StringProtocol>(
    _ title: S,
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder destination: (Binding<Case>) -> WrappedDestination
  ) where Destination == WrappedDestination?, Label == Text {
    self.init(
      unwrapping: `enum`.case(casePath),
      onNavigate: onNavigate,
      destination: destination
    ) {
      Text(title)
    }
  }

  /// Creates a navigation link that presents the destination view when a bound enum is non-`nil`
  /// and matches a particular case.
  ///
  /// An overload of ``init(unwrapping:case:onNavigate:destination:label:)`` that takes a localized
  /// title instead of a label.
  @available(iOS, introduced: 13, deprecated: 16)
  @available(macOS, introduced: 10.15, deprecated: 13)
  @available(tvOS, introduced: 13, deprecated: 16)
  @available(watchOS, introduced: 6, deprecated: 9)
  public init<Enum, Case, WrappedDestination>(
    _ titleKey: LocalizedStringKey,
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder destination: (Binding<Case>) -> WrappedDestination
  ) where Destination == WrappedDestination?, Label == Text {
    self.init(
      unwrapping: `enum`.case(casePath),
      onNavigate: onNavigate,
      destination: destination
    ) {
      Text(titleKey)
    }
  }
}

// MARK: - SwiftUI Overlays

extension NavigationLink {
  /// Creates a navigation link that presents the destination view.
  ///
  /// See
  /// [the official documentation(https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:label:)-27n7s)
  /// for more information.
  @_alwaysEmitIntoClient
  public init(
    @ViewBuilder destination: () -> Destination,
    @ViewBuilder label: () -> Label
  ) {
    self.init(destination: destination(), label: label)
  }

  /// Creates a navigation link that presents the destination view when active.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(isactive:destination:label:))
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  @_alwaysEmitIntoClient
  public init(
    isActive: Binding<Bool>,
    @ViewBuilder destination: () -> Destination,
    @ViewBuilder label: () -> Label
  ) {
    self.init(destination: destination(), isActive: isActive, label: label)
  }

  /// Creates a navigation link that presents the destination view when a bound selection variable
  /// equals a given tag value.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(tag:selection:destination:label:))
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @_alwaysEmitIntoClient
  public init<V: Hashable>(
    tag: V,
    selection: Binding<V?>,
    @ViewBuilder destination: () -> Destination,
    @ViewBuilder label: () -> Label
  ) {
    self.init(
      destination: destination(),
      tag: tag,
      selection: selection,
      label: label
    )
  }

  /// Creates a navigation link that presents the destination view.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:label:)-9dxix)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    tvOS, introduced: 13, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    watchOS, introduced: 6, deprecated: 100000, message: "Pass a closure as the destination"
  )
  public init(
    destination: Destination,
    @ViewBuilder label: () -> Label
  ) {
    self.init(navigationLink: .init(destination: destination, label: label))
  }

  /// Creates a navigation link that presents the destination view when active.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:isactive:label:))
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message: "use NavigationLink(value:label:) inside a NavigationStack or NavigationSplitView"
  )
  public init(
    destination: Destination,
    isActive: Binding<Bool>,
    @ViewBuilder label: () -> Label
  ) {
    let label = label()
    self.init(
      navigationLink: { .init(destination: destination, isActive: $0) { label } },
      valueIsPresented: isActive
    )
  }

  /// Creates a navigation link that presents the destination view when a bound selection variable
  /// equals a given tag value.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:tag:selection:label:))
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message:
      "use NavigationLink(value:label:) inside a List within a NavigationStack or NavigationSplitView"
  )
  public init<V: Hashable>(
    destination: Destination,
    tag: V,
    selection: Binding<V?>,
    @ViewBuilder label: () -> Label
  ) {
    let label = label()
    self.init(
      navigationLink: {
        .init(
          destination: destination,
          tag: tag,
          selection: $0.tag(tag)
        ) {
          label
        }
      },
      valueIsPresented: selection.isPresent()
    )
  }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension NavigationLink where Destination == Never {
  /// Creates a navigation link that presents the view corresponding to a value.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(value:label:)-4jswo)
  /// for more information.
  public init<P: Hashable>(
    value: P?,
    @ViewBuilder label: () -> Label
  ) {
    self.init(navigationLink: .init(value: value, label: label))
  }

  /// Creates a navigation link that presents the view corresponding to a value, with a text label
  /// that the link generates from a localized string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:value:)-kj9v)
  /// for more information.
  public init<P: Hashable>(
    _ titleKey: LocalizedStringKey,
    value: P?
  ) where Label == Text {
    self.init(value: value) { Text(titleKey) }
  }

  /// Creates a navigation link that presents the view corresponding to a value, with a text label
  /// that the link generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:value:)-91u0d)
  /// for more information.
  @_disfavoredOverload
  public init<S: StringProtocol, P: Hashable>(
    _ title: S,
    value: P?
  ) where Label == Text {
    self.init(value: value) { Text(title) }
  }

  /// Creates a navigation link that presents the view corresponding to a codable value.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(value:label:)-3qb8y)
  /// for more information.
  public init<P: Codable & Hashable>(
    value: P?,
    @ViewBuilder label: () -> Label
  ) {
    self.init(navigationLink: .init(value: value, label: label))
  }

  /// Creates a navigation link that presents the view corresponding to a codable value, with a text
  /// label that the link generates from a localized string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:value:)-810b2)
  /// for more information.
  public init<P: Codable & Hashable>(
    _ titleKey: LocalizedStringKey,
    value: P?
  ) where Label == Text {
    self.init(value: value) { Text(titleKey) }
  }

  /// Creates a navigation link that presents the view corresponding to a codable value, with a text
  /// label that the link generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:value:)-9ziux)
  /// for more information.
  @_disfavoredOverload
  public init<S: StringProtocol, P: Codable & Hashable>(
    _ title: S,
    value: P?
  ) where Label == Text {
    self.init(value: value) { Text(title) }
  }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension NavigationLink where Label == Text {
  /// Creates a navigation link that presents a destination view, with a text label that the link
  /// generates from a localized string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:)-7d6im)
  /// for more information.
  @_alwaysEmitIntoClient
  public init(
    _ titleKey: LocalizedStringKey,
    @ViewBuilder destination: () -> Destination
  ) {
    self.init(titleKey, destination: destination())
  }

  /// Creates a navigation link that presents a destination view, with a text label that the link
  /// generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:)-6z03e)
  /// for more information.
  @_alwaysEmitIntoClient
  @_disfavoredOverload
  public init<S: StringProtocol>(
    _ title: S,
    @ViewBuilder destination: () -> Destination
  ) {
    self.init(title, destination: destination())
  }

  /// Creates a navigation link that presents a destination view when active, with a text label that
  /// the link generates from a localized string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:isactive:destination:)-gn8q)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @_alwaysEmitIntoClient
  public init(
    _ titleKey: LocalizedStringKey,
    isActive: Binding<Bool>,
    @ViewBuilder destination: () -> Destination
  ) {
    self.init(titleKey, destination: destination(), isActive: isActive)
  }

  /// Creates a navigation link that presents a destination view when active, with a text label that
  /// the link generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:isactive:destination:)-6xw7h)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @_alwaysEmitIntoClient
  @_disfavoredOverload
  public init<S: StringProtocol>(
    _ title: S,
    isActive: Binding<Bool>,
    @ViewBuilder destination: () -> Destination
  ) {
    self.init(title, destination: destination(), isActive: isActive)
  }

  /// Creates a navigation link that presents a destination view when a bound selection variable
  /// matches a value you provide, using a text label that the link generates from a localized
  /// string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:tag:selection:destination:)-510fq)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @_alwaysEmitIntoClient
  public init<V: Hashable>(
    _ titleKey: LocalizedStringKey,
    tag: V,
    selection: Binding<V?>,
    @ViewBuilder destination: () -> Destination
  ) {
    self.init(titleKey, destination: destination(), tag: tag, selection: selection)
  }

  /// Creates a navigation link that presents a destination view when a bound selection variable
  /// matches a value you provide, using a text label that the link generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:tag:selection:destination:)-4oa09)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @_alwaysEmitIntoClient
  @_disfavoredOverload
  public init<S: StringProtocol, V: Hashable>(
    _ title: S,
    tag: V,
    selection: Binding<V?>,
    @ViewBuilder destination: () -> Destination
  ) {
    self.init(title, destination: destination(), tag: tag, selection: selection)
  }

  /// Creates a navigation link that presents a destination view, with a text label that the link
  /// generates from a localized string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:)-3xblz)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    tvOS, introduced: 13, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    watchOS, introduced: 6, deprecated: 100000, message: "Pass a closure as the destination"
  )
  public init(
    _ titleKey: LocalizedStringKey,
    destination: Destination
  ) {
    self.init(destination: destination) { Text(titleKey) }
  }

  /// Creates a navigation link that presents a destination view, with a text label that the link
  /// generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:)-6hslu)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    tvOS, introduced: 13, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @available(
    watchOS, introduced: 6, deprecated: 100000, message: "Pass a closure as the destination"
  )
  @_disfavoredOverload
  public init<S: StringProtocol>(
    _ title: S,
    destination: Destination
  ) {
    self.init(destination: destination) { Text(title) }
  }

  /// Creates a navigation link that presents a destination view when active, with a text label that
  /// the link generates from a localized string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:isactive:)-4whx5)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  public init(
    _ titleKey: LocalizedStringKey,
    destination: Destination,
    isActive: Binding<Bool>
  ) {
    self.init(destination: destination, isActive: isActive) { Text(titleKey) }
  }

  /// Creates a navigation link that presents a destination view when active, with a text label that
  /// the link generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:isactive:)-3v44)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message: "use NavigationLink(_:value:) inside a NavigationStack or NavigationSplitView"
  )
  @_disfavoredOverload
  public init<S: StringProtocol>(
    _ title: S,
    destination: Destination,
    isActive: Binding<Bool>
  ) {
    self.init(destination: destination, isActive: isActive) { Text(title) }
  }

  /// Creates a navigation link that presents a destination view when a bound selection variable
  /// matches a value you provide, using a text label that the link generates from a localized
  /// string key.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:tag:selection:)-1rm3u)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  public init<V: Hashable>(
    _ titleKey: LocalizedStringKey,
    destination: Destination,
    tag: V,
    selection: Binding<V?>
  ) {
    self.init(destination: destination, tag: tag, selection: selection) { Text(titleKey) }
  }

  /// Creates a navigation link that presents a destination view when a bound selection variable
  /// matches a value you provide, using a text label that the link generates from a title string.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/init(_:destination:tag:selection:)-6unyq)
  /// for more information.
  @available(
    iOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    macOS, introduced: 10.15, deprecated: 13,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    tvOS, introduced: 13, deprecated: 16,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @available(
    watchOS, introduced: 6, deprecated: 9,
    message:
      "use NavigationLink(_:value:) inside a List within a NavigationStack or NavigationSplitView"
  )
  @_disfavoredOverload
  public init<S: StringProtocol, V: Hashable>(
    _ title: S,
    destination: Destination,
    tag: V,
    selection: Binding<V?>
  ) {
    self.init(destination: destination, tag: tag, selection: selection) { Text(title) }
  }
}

@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension NavigationLink {
  /// Sets the navigation link to present its destination as the detail component of the containing
  /// navigation view.
  ///
  /// See
  /// [the official documentation](https://developer.apple.com/documentation/swiftui/navigationlink/isdetaillink(_:))
  /// for more information.
  @available(macOS, unavailable)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public func isDetailLink(_ isDetailLink: Bool) -> some View {
    #if os(iOS)
      Self(
        navigationLink: self.navigationLink,
        _isDetailLink: isDetailLink,
        valueIsPresented: self.$valueIsPresented
      )
    #else
      Self(
        navigationLink: self.navigationLink,
        valueIsPresented: self.$valueIsPresented
      )
    #endif
  }
}

extension Binding {
  fileprivate init(initialValue: Value) {
    var value = initialValue
    self.init(
      get: { value },
      set: { value = $0 }
    )
  }
}

extension Binding where Value == Bool {
  fileprivate func tag<V: Hashable>(_ tag: V) -> Binding<V?> {
    .init(
      get: { self.wrappedValue ? tag : nil },
      set: { self.transaction($1).wrappedValue = $0 == tag }
    )
  }
}
