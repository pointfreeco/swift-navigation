import ConcurrencyExtras
import IssueReporting

#if canImport(Observation)
  import Observation
#endif

/// A property wrapper type that can read and write an observable value.
///
/// Like SwiftUI's `Binding`, but works for UIKit, AppKit, and non-Apple platforms such as
/// Windows, Linux, Wasm, and more.
///
/// ``UIBinding`` has two primary use cases: a two-way connection between a property of an
/// observable model and a UI component (e.g. text field, toggle, etc.), and as a means to drive
/// navigation from state.
///
/// ### UI component bindings
///
/// Use a binding to create a two-way connection between a property that stores data, and a view
/// that displays and changes the data. A binding connects a property to a source of truth stored
/// somewhere, either from an observable model or directly. This is in contrast to SwiftUI bindings,
/// which always have a source of truth that is stored elsewhere.
///
/// For example, a button that toggles between play and pause can create a binding to a property of
/// its parent view controller using the `UIBinding` property wrapper.
///
/// ```swift
/// class PlayButton: UIControl {
///   @UIBinding var isPlaying: Bool
///
///   init(frame: CGRect = .zero, isPlaying: UIBinding<Bool>) {
///     self._isPlaying = isPlaying
///     super.init(frame: frame)
///
///     // ...
///
///     observe { [weak self] in
///       guard let self else { return }
///       titleLabel.text = isPlaying ? "Pause" : "Play"
///     }
///     addAction(
///       UIAction { [weak self] _ in self?.isPlaying.toggle() },
///       for: .touchUpInside
///     )
///   }
///
///   // ...
/// }
/// ```
///
/// The parent view controller declares a property to hold the playing state, again using the
/// `UIBinding` property wrapper, but this time with an initial value to indicate that this property
/// is the value's source of truth.
///
/// ```swift
/// final class PlayerViewController: UIViewController {
///   private var episode: Episode
///   @UIBinding private var isPlaying: Bool = false
///
///   // ...
///
///   func viewDidLoad() {
///     super.viewDidLoad()
///
///     let playButton = PlayButton(isPlaying: $isPlaying)
///     let episodeTitleLabel = UILabel()
///
///     // Configure and add subviews...
///
///     observe { [weak self] in
///       guard let self else { return
///       nowPlayingLabel.textColor = isPlaying ? .label : .secondaryLabel
///     }
///   }
///
///   // ...
/// }
/// ```
///
/// When `PlayerViewController` initializes `PlayButton`, it passes a binding of its `isPlaying`
/// state along. Applying the `$` prefix to a property wrapped value returns its ``projectedValue``,
/// which returns a binding to the value. Whenever the user taps the `PlayButton`, the
///  `PlayerViewController` updates its `isPlaying` state.
///
/// > Note: To create bindings to properties of a type that conforms to the `Observable` or
/// > `Perceptible` protocols, use the [`@UIBindable`](<doc:UIBindable>) property wrapper.
///
/// It is also possible to use bindings for UI components on other platforms beyond Apple's
/// platforms. For example, in Wasm you can bind an HTML text field to a field of the model:
///
/// ```swift
/// @UIBindable var model = Model()
///
/// let searchField = document.createElement("input")
/// searchField.bind(text: $model.searchText)
/// ```
///
/// This makes it so that any changes to the text field in the DOM are immediately played back
/// to the model, and vice-versa.
///
/// ### State-driven navigation
///
/// Bindings are also useful for creating navigation APIs that are driven off of state. For example,
/// in UIKit you can have an observable model that presents a sheet with some boolean state:
///
/// ```swift
/// @Observable
/// class FeatureModel {
///   var isPresented = false
/// }
/// ```
///
/// And then in a view controller you can drive navigation to the sheet by using a ``UIBinding``:
///
/// ```swift
/// @UIBindable var model = FeatureModel()
///
/// present(isPresented: $model.isPresented) {
///   SheetViewController()
/// }
/// ```
///
/// And you can also build your own navigation tools by utilizing ``UIBinding`` and
/// ``observe(isolation:_:)-9xf99``. You can even build navigation tools for non-Apple platforms,
/// such as Windows, Linux, Wasm and more.
///
/// For example, it is possible to build a tool that drives alerts in HTML from a binding of a
/// boolean:
///
/// ```swift
/// alert(isPresented: $model.isErrorAlertPresented) {
///   "Something went wrong."
/// }
/// ```
@dynamicMemberLookup
@propertyWrapper
public struct UIBinding<Value>: Sendable {
  fileprivate let location: any _UIBinding<Value>

  /// The binding's transaction.
  ///
  /// The transaction captures the information needed to update the view when the binding value
  /// changes.
  public var transaction = UITransaction()

  init(location: any _UIBinding<Value>, transaction: UITransaction) {
    self.location = location
    self.transaction = transaction
  }

  init<Root: AnyObject>(
    root: Root,
    keyPath: ReferenceWritableKeyPath<Root, Value>,
    transaction: UITransaction,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.init(
      location: _UIBindingWeakRoot(
        root: root,
        keyPath: keyPath,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      ),
      transaction: transaction
    )
  }

  /// Creates a binding that stores an initial wrapped value.
  ///
  /// You don't call this initializer directly. Instead, Swift calls it for you when you declare a
  /// property with the `@UIBinding` attribute and provide an initial value:
  ///
  /// ```swift
  /// final class MyViewController: UIViewController {
  ///   @UIBinding private var isPlaying: Bool = false
  ///   // ...
  /// }
  /// ```
  ///
  /// > Note: SwiftUI's `Binding` type has no such initializer because a view is reinitialized many,
  /// > many times in an application as its parent's body is recomputed, and so Swift has a separate
  /// > `@State` property wrapper that is used to create local, mutable state for a view, and you
  /// > can derive bindings from it.
  /// >
  /// > Reference types like view controllers have no such problem, and can hold onto local, mutable
  /// > state directly. Because of this, it's also totally appropriate to create bindings to these
  /// > properties directly.
  ///
  /// - Parameter value: An initial value to store in the state property.
  public init(wrappedValue value: Value) {
    self.init(
      location: _UIBindingAppendKeyPath(
        base: _UIBindingStrongRoot(root: _UIBindingWrapper(value)),
        keyPath: \.value
      ),
      transaction: UITransaction()
    )
  }

  @available(
    *,
    deprecated,
    message: """
      A '@UIBinding' must be initialized with a value, not an observable reference. Use '@UIBindable', instead.
      """,
    renamed: "UIBindable.init"
  )
  public init(wrappedValue value: Value) where Value: AnyObject {
    self.init(
      location: _UIBindingAppendKeyPath(
        base: _UIBindingStrongRoot(root: _UIBindingWrapper(value)),
        keyPath: \.value
      ),
      transaction: UITransaction()
    )
  }

  /// Creates a binding from the value of another binding.
  ///
  /// You don't call this initializer directly. Instead, Swift calls it for you when you use a
  /// property-wrapper attribute on a binding closure parameter:
  ///
  /// ```swift
  /// present(item: $model.text) { $text in
  ///   EditorViewController(text: $text)
  /// }
  /// ```
  ///
  /// - Parameter projectedValue: A binding.
  public init(projectedValue: UIBinding<Value>) {
    self = projectedValue
  }

  /// Creates a binding with an immutable value.
  ///
  /// Use this method to create a binding to a value that cannot change. This can be useful when
  /// using a `#Preview` to see how a view represents different values.
  ///
  /// ```swift
  /// // Example of binding to an immutable value.
  /// PlayButton(isPlaying: .constant(true))
  /// ```
  ///
  /// - Parameter value: An immutable value.
  /// - Returns: A binding to an immutable value.
  public static func constant(_ value: Value) -> Self {
    Self(location: _UIBindingConstant(value), transaction: UITransaction())
  }

  /// Creates a binding by projecting the base value to an unwrapped value.
  ///
  /// - Parameter base: A value to project to an unwrapped value.
  public init?(_ base: UIBinding<Value?>) {
    guard let initialValue = base.wrappedValue
    else { return nil }
    func open(_ location: some _UIBinding<Value?>) -> any _UIBinding<Value> {
      _UIBindingFromOptional(initialValue: initialValue, base: location)
    }
    self.init(location: open(base.location), transaction: base.transaction)
  }

  /// Creates a binding by projecting the base optional value to a Boolean value.
  ///
  /// - Parameters:
  ///   - base: A value to project to a Boolean value.
  ///   - fileID: The source `#fileID` associated with the binding.
  ///   - filePath: The source `#filePath` associated with the binding.
  ///   - line: The source `#line` associated with the binding.
  ///   - column: The source `#column` associated with the binding.
  public init<V>(
    _ base: UIBinding<V?>,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) where Value == Bool {
    func open(_ location: some _UIBinding<V?>) -> any _UIBinding<Value> {
      _UIBindingOptionalToBool(
        base: location,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    }
    self.init(location: open(base.location), transaction: base.transaction)
  }

  /// Creates a binding by projecting the base value to an optional value.
  ///
  /// - Parameter base: A value to project to an optional value.
  public init<V>(_ base: UIBinding<V>) where Value == V? {
    func open(_ location: some _UIBinding<V>) -> any _UIBinding<Value> {
      _UIBindingToOptional(base: location)
    }
    self.init(location: open(base.location), transaction: base.transaction)
  }

  /// Creates a binding by projecting the base value to a hashable value.
  ///
  /// - Parameter base: A `Hashable` value to project to an `AnyHashable` value.
  public init<V: Hashable>(_ base: UIBinding<V>) where Value == AnyHashable {
    func open(_ location: some _UIBinding<V>) -> any _UIBinding<Value> {
      _UIBindingToAnyHashable(base: location)
    }
    self.init(location: open(base.location), transaction: base.transaction)
  }

  /// The underlying value referenced by the binding variable.
  ///
  /// This property provides primary access to the value's data. However, you don't access
  /// `wrappedValue` directly. Instead, you use the property variable created with the ``UIBinding``
  /// attribute. In the following code example, the binding variable `isPlaying` returns the value
  /// of `wrappedValue`:
  ///
  /// ```swift
  /// class PlayButton: UIControl {
  ///   @UIBinding var isPlaying: Bool
  ///
  ///   init(frame: CGRect = .zero, isPlaying: UIBinding<Bool>) {
  ///     self._isPlaying = isPlaying
  ///     super.init(frame: frame)
  ///
  ///     // ...
  ///
  ///     observe { [weak self] in
  ///       guard let self else { return }
  ///       titleLabel.text = isPlaying ? "Pause" : "Play"
  ///     }
  ///     addAction(
  ///       UIAction { [weak self] _ in self?.isPlaying.toggle() },
  ///       for: .touchUpInside
  ///     )
  ///   }
  ///
  ///   // ...
  /// }
  /// ```
  public var wrappedValue: Value {
    get {
      location.wrappedValue
    }
    nonmutating set {
      guard UITransaction.current.isEmpty else {
        location.wrappedValue = newValue
        return
      }
      withUITransaction(transaction) {
        location.wrappedValue = newValue
      }
    }
  }

  /// A projection of the binding value that returns a binding.
  ///
  /// Use the projected value to pass a binding value down a view hierarchy. To get the
  /// `projectedValue`, prefix the property variable with `$`. For example, in the following code
  /// example `PlayerViewController` projects a binding of the property `isPlaying` to the
  /// `PlayButton` view using `$isPlaying`.
  ///
  /// ```swift
  /// final class PlayerViewController: UIViewController {
  ///   private var episode: Episode
  ///   @UIBinding private var isPlaying: Bool = false
  ///
  ///   // ...
  ///
  ///   func viewDidLoad() {
  ///     super.viewDidLoad()
  ///
  ///     let playButton = PlayButton(isPlaying: $isPlaying)
  ///     let episodeTitleLabel = UILabel()
  ///
  ///     // Configure and add subviews...
  ///
  ///     observe { [weak self] in
  ///       guard let self else { return
  ///       nowPlayingLabel.textColor = isPlaying ? .label : .secondaryLabel
  ///     }
  ///   }
  ///
  ///   // ...
  /// }
  /// ```
  public var projectedValue: Self {
    self
  }

  /// Returns a binding to the resulting value of a given key path.
  ///
  /// - Parameter keyPath: A key path to a specific resulting value.
  /// - Returns: A new binding.
  public subscript<Member>(
    dynamicMember keyPath: WritableKeyPath<Value, Member>
  ) -> UIBinding<Member> {
    func open(_ location: some _UIBinding<Value>) -> UIBinding<Member> {
      UIBinding<Member>(
        location: _UIBindingAppendKeyPath(base: location, keyPath: keyPath.unsafeSendable()),
        transaction: transaction
      )
    }
    return open(location)
  }

  /// Returns a binding to the associated value of a given case key path.
  ///
  /// - Parameter keyPath: A case key path to a specific associated value.
  /// - Returns: A new binding.
  @_disfavoredOverload
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
  ) -> UIBinding<Member>?
  where Value: CasePathable {
    func open(_ location: some _UIBinding<Value>) -> UIBinding<Member?> {
      UIBinding<Member?>(
        location: _UIBindingEnumToOptionalCase(base: location, keyPath: keyPath.unsafeSendable()),
        transaction: transaction
      )
    }
    return UIBinding<Member>(open(location))
  }

  /// Returns an optional binding to the associated value of a given key path.
  ///
  /// - Parameter keyPath: A key path to a specific value.
  /// - Returns: A new binding.
  public subscript<Wrapped, Member>(
    dynamicMember keyPath: WritableKeyPath<Wrapped, Member>
  ) -> UIBinding<Member?>
  where Value == Wrapped? {
    func open(_ location: some _UIBinding<Value>) -> UIBinding<Member?> {
      UIBinding<Member?>(
        location: _UIBindingOptionalToMember(base: location, keyPath: keyPath.unsafeSendable()),
        transaction: transaction
      )
    }
    return open(location)
  }

  /// Returns an optional binding to the associated value of a given case key path.
  ///
  /// - Parameter keyPath: A case key path to a specific associated value.
  /// - Returns: A new binding.
  public subscript<V: CasePathable, Member>(
    dynamicMember keyPath: KeyPath<V.AllCasePaths, AnyCasePath<V, Member>>
  ) -> UIBinding<Member?>
  where Value == V? {
    func open(_ location: some _UIBinding<Value>) -> UIBinding<Member?> {
      UIBinding<Member?>(
        location: _UIBindingOptionalEnumToCase(base: location, keyPath: keyPath.unsafeSendable()),
        transaction: transaction
      )
    }
    return open(location)
  }

  /// Returns a Boolean binding to a case of a given case key path with no associated value.
  ///
  /// - Parameter keyPath: A case key path to a case with no associated value.
  /// - Returns: A new binding.
  public subscript<V: CasePathable>(
    dynamicMember keyPath: KeyPath<V.AllCasePaths, AnyCasePath<V, Void>>
  ) -> UIBinding<Bool>
  where Value == V? {
    UIBinding<Bool>(self[dynamicMember: keyPath])
  }

  /// Specifies a transaction for the binding.
  ///
  /// - Parameter transaction: An instance of a ``UITransaction``.
  /// - Returns: A new binding.
  public func transaction(_ transaction: UITransaction) -> Self {
    var binding = self
    binding.transaction = transaction
    return binding
  }

  public func _printChanges(
    _ prefix: String = "",
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    func open(_ location: some _UIBinding<Value>) -> Self {
      Self(
        location: _UIBindingPrintChanges(
          base: location,
          prefix: prefix,
          fileID: fileID,
          line: line
        ),
        transaction: transaction
      )
    }
    return open(location)
  }
}

extension UIBinding: Identifiable where Value: Identifiable {
  public var id: Value.ID {
    wrappedValue.id
  }
}

/// A unique identifier for a binding.
public struct UIBindingIdentifier: Hashable, Sendable {
  private let location: AnyHashableSendable

  /// Creates an instance that uniquely identifies the given binding.
  ///
  /// - Parameter binding: An instance of a binding.
  public init<Value>(_ binding: UIBinding<Value>) {
    self.location = AnyHashableSendable(binding.location)
  }
}

protocol _UIBinding<Value>: AnyObject, Hashable, Sendable {
  associatedtype Value
  var wrappedValue: Value { get set }
}

private final class _UIBindingStrongRoot<Root: AnyObject>: _UIBinding, @unchecked Sendable {
  init(root: Root) {
    self.wrappedValue = root
  }
  var wrappedValue: Root
  static func == (lhs: _UIBindingStrongRoot, rhs: _UIBindingStrongRoot) -> Bool {
    lhs === rhs
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(wrappedValue))
  }
}

private final class _UIBindingWeakRoot<Root: AnyObject, Value>: _UIBinding, @unchecked Sendable {
  let keyPath: ReferenceWritableKeyPath<Root, Value>
  let objectIdentifier: ObjectIdentifier
  weak var root: Root?
  var value: Value
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt
  init(
    root: Root,
    keyPath: ReferenceWritableKeyPath<Root, Value>,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.keyPath = keyPath
    self.objectIdentifier = ObjectIdentifier(root)
    self.root = root
    #if DEBUG
      self.value = _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
        root[keyPath: keyPath]
      }
    #else
      self.value = root[keyPath: keyPath]
    #endif
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
  var wrappedValue: Value {
    get { root?[keyPath: keyPath] ?? value }
    set {
      if root == nil {
        reportIssue(
          """
          Binding failed to write to '@Bindable var \(Root.self)':\(fileID):\(line) because it \
          is 'nil'.

          This usually happens because the bindable model is not strongly held and so is \
          deallocated.
          """,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      }
      value = newValue
      root?[keyPath: keyPath] = value
    }
  }
  static func == (lhs: _UIBindingWeakRoot, rhs: _UIBindingWeakRoot) -> Bool {
    lhs.objectIdentifier == rhs.objectIdentifier && lhs.keyPath == rhs.keyPath
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(objectIdentifier)
    hasher.combine(keyPath)
  }
}

private final class _UIBindingWrapper<Value>: Perceptible {
  var _value: Value
  var value: Value {
    get {
      _$perceptionRegistrar.access(self, keyPath: \.value)
      return _value
    }
    set {
      _$perceptionRegistrar.withMutation(of: self, keyPath: \.value) {
        _value = newValue
      }
    }
    _modify {
      _$perceptionRegistrar.willSet(self, keyPath: \.value)
      defer { _$perceptionRegistrar.didSet(self, keyPath: \.value) }
      yield &_value
    }
  }
  let _$perceptionRegistrar = PerceptionRegistrar()
  init(_ value: Value) {
    self._value = value
  }
}

#if canImport(Observation)
  extension _UIBindingWrapper: Observable {}
#endif

private final class _UIBindingConstant<Value>: _UIBinding, @unchecked Sendable {
  let value: Value
  init(_ value: Value) {
    self.value = value
  }
  var wrappedValue: Value {
    get { value }
    set {}
  }
  static func == (lhs: _UIBindingConstant, rhs: _UIBindingConstant) -> Bool {
    lhs === rhs
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

private final class _UIBindingAppendKeyPath<Base: _UIBinding, Value>: _UIBinding, Sendable {
  let base: Base
  let keyPath: _SendableWritableKeyPath<Base.Value, Value>
  init(base: Base, keyPath: _SendableWritableKeyPath<Base.Value, Value>) {
    self.base = base
    self.keyPath = keyPath
  }
  var wrappedValue: Value {
    get { base.wrappedValue[keyPath: keyPath] }
    set { base.wrappedValue[keyPath: keyPath] = newValue }
  }
  static func == (lhs: _UIBindingAppendKeyPath, rhs: _UIBindingAppendKeyPath) -> Bool {
    lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
    hasher.combine(keyPath)
  }
}

private final class _UIBindingFromOptional<Base: _UIBinding<Value?>, Value>: _UIBinding, @unchecked
  Sendable
{
  var value: Value
  let base: Base
  init(initialValue: Value, base: Base) {
    self.value = initialValue
    self.base = base
  }
  var wrappedValue: Value {
    get {
      if let value = base.wrappedValue {
        self.value = value
      }
      return value
    }
    set {
      value = newValue
      if base.wrappedValue != nil {
        base.wrappedValue = newValue
      }
    }
  }
  static func == (lhs: _UIBindingFromOptional, rhs: _UIBindingFromOptional) -> Bool {
    lhs.base == rhs.base
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

private final class _UIBindingToOptional<Base: _UIBinding>: _UIBinding {
  let base: Base
  init(base: Base) {
    self.base = base
  }
  var wrappedValue: Base.Value? {
    get {
      base.wrappedValue
    }
    set {
      guard let newValue else { return }
      base.wrappedValue = newValue
    }
  }
  static func == (lhs: _UIBindingToOptional, rhs: _UIBindingToOptional) -> Bool {
    lhs.base == rhs.base
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

private final class _UIBindingToAnyHashable<Base: _UIBinding>: _UIBinding
where Base.Value: Hashable {
  let base: Base
  init(base: Base) {
    self.base = base
  }
  var wrappedValue: AnyHashable {
    get { base.wrappedValue }
    set { base.wrappedValue = newValue.base as! Base.Value }
  }
  static func == (lhs: _UIBindingToAnyHashable, rhs: _UIBindingToAnyHashable) -> Bool {
    lhs.base == rhs.base
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

private final class _UIBindingEnumToOptionalCase<Base: _UIBinding, Case>: _UIBinding
where Base.Value: CasePathable {
  let base: Base
  let keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
  let casePath: AnyCasePath<Base.Value, Case>
  init(
    base: Base, keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
  ) {
    self.base = base
    self.keyPath = keyPath
    self.casePath = Base.Value.allCasePaths[keyPath: keyPath]
  }
  var wrappedValue: Case? {
    get {
      casePath.extract(from: base.wrappedValue)
    }
    set {
      guard let newValue, casePath.extract(from: base.wrappedValue) != nil
      else { return }
      base.wrappedValue = casePath.embed(newValue)
    }
  }
  static func == (lhs: _UIBindingEnumToOptionalCase, rhs: _UIBindingEnumToOptionalCase) -> Bool {
    lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
    hasher.combine(keyPath)
  }
}

private final class _UIBindingOptionalToBool<
  Base: _UIBinding<Wrapped?>, Wrapped
>: _UIBinding {
  let base: Base
  let fileID: StaticString
  let filePath: StaticString
  let line: UInt
  let column: UInt
  init(
    base: Base,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    self.base = base
    self.fileID = fileID
    self.filePath = filePath
    self.line = line
    self.column = column
  }
  var wrappedValue: Bool {
    get { base.wrappedValue != nil }
    set {
      if newValue {
        reportIssue(
          """
          Boolean presentation binding attempted to write 'true' to a generic 'UIBinding<Item?>' \
          (i.e., 'UIBinding<\(Wrapped.self)?>').

          This is not a valid thing to do, as there is no way to convert 'true' to a new instance \
          of '\(Wrapped.self)'.
          """,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      } else {
        base.wrappedValue = nil
      }
    }
  }
  static func == (lhs: _UIBindingOptionalToBool, rhs: _UIBindingOptionalToBool) -> Bool {
    lhs.base == rhs.base
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

private final class _UIBindingOptionalToMember<
  Base: _UIBinding<Wrapped?>, Wrapped, Value
>: _UIBinding {
  let base: Base
  let keyPath: _SendableWritableKeyPath<Wrapped, Value>
  init(base: Base, keyPath: _SendableWritableKeyPath<Wrapped, Value>) {
    self.base = base
    self.keyPath = keyPath
  }
  var wrappedValue: Value? {
    get {
      base.wrappedValue?[keyPath: keyPath]
    }
    set {
      if let newValue {
        base.wrappedValue?[keyPath: keyPath] = newValue
      } else {
        base.wrappedValue = nil
      }
    }
  }
  static func == (lhs: _UIBindingOptionalToMember, rhs: _UIBindingOptionalToMember) -> Bool {
    lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
    hasher.combine(keyPath)
  }
}

private final class _UIBindingOptionalEnumToCase<
  Base: _UIBinding<Enum?>, Enum: CasePathable, Case
>: _UIBinding {
  let base: Base
  let keyPath: _SendableKeyPath<Enum.AllCasePaths, AnyCasePath<Enum, Case>>
  let casePath: AnyCasePath<Enum, Case>
  init(base: Base, keyPath: _SendableKeyPath<Enum.AllCasePaths, AnyCasePath<Enum, Case>>) {
    self.base = base
    self.keyPath = keyPath
    self.casePath = Enum.allCasePaths[keyPath: keyPath]
  }
  var wrappedValue: Case? {
    get {
      base.wrappedValue.flatMap(casePath.extract(from:))
    }
    set {
      guard base.wrappedValue.flatMap(casePath.extract(from:)) != nil
      else { return }
      base.wrappedValue = newValue.map(casePath.embed)
    }
  }
  static func == (lhs: _UIBindingOptionalEnumToCase, rhs: _UIBindingOptionalEnumToCase) -> Bool {
    lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
    hasher.combine(keyPath)
  }
}

private final class _UIBindingPrintChanges<Base: _UIBinding>: _UIBinding {
  let base: Base
  let prefix: String
  let fileID: StaticString
  let line: UInt
  init(base: Base, prefix: String, fileID: StaticString, line: UInt) {
    self.base = base
    self.prefix = prefix
    self.fileID = fileID
    self.line = line
  }
  var wrappedValue: Base.Value {
    get { base.wrappedValue }
    set {
      var oldDescription = ""
      debugPrint(base.wrappedValue, terminator: "", to: &oldDescription)
      var newDescription = ""
      debugPrint(newValue, terminator: "", to: &newDescription)
      print(
        "\(prefix.isEmpty ? "UIBinding<\(Value.self)>@\(fileID):\(line)" : prefix):",
        oldDescription,
        "→",
        newDescription
      )
      base.wrappedValue = newValue
    }
  }
  static func == (lhs: _UIBindingPrintChanges, rhs: _UIBindingPrintChanges) -> Bool {
    lhs.base == rhs.base
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}
