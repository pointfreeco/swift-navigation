#if canImport(AppKit) && !targetEnvironment(macCatalyst)

@_spi(Internals) public import SwiftNavigation
public import AppKit

extension NSFontManager: @unchecked @retroactive Sendable {}

@MainActor
extension NSFontManager {
  /// Returns the shared font manager, with the binding registered against its selected font.
  ///
  /// `NSFontManager()` returns the shared font manager, so this binds the same instance as
  /// `NSFontManager.shared.bind(font:)`.
  ///
  /// - Parameter font: The binding to read from for the selected font, and write to when a
  ///   change from the font panel or the font menu is applied.
  public convenience init(font: UIBinding<NSFont>) {
    self.init()
    bind(font: font)
  }

  /// Establishes a two-way connection between a binding and the font manager's selected font.
  ///
  /// The binding's font becomes the selected font that the font panel shows. When the user changes
  /// it from the font panel or the font menu, the change is applied to the binding's font, the way
  /// a text view applies it to its own.
  ///
  /// > Important: The font manager only sends font changes while some responder in the chain
  /// > implements `changeFont(_:)` — usually the text view being edited. While none does, changes
  /// > from the font panel do not reach the binding either.
  ///
  /// - Parameter font: The binding to read from for the selected font, and write to when a
  ///   change from the font panel or the font menu is applied.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind(font: UIBinding<NSFont>) -> ObserveToken {
    bind(font, to: \.appKitNavigationSelectedFont)
  }

  // NB: Exposed to Objective-C so the binding can observe it, and named after the library so that
  //     it can never replace a method AppKit has, or adds later, under the same selector.
  @objc private var appKitNavigationSelectedFont: NSFont {
    set { setSelectedFont(newValue, isMultiple: false) }
    // NB: 'convert(_:)' applies the font panel's latest change to the font it is given. That has
    //     to be the bound font, which the setter above recorded as the selected font; converting
    //     anything else keeps only the change and loses the bound font's family and size.
    get { convert(selectedFont ?? .systemFont(ofSize: 0)) }
  }
}

@MainActor
extension NSFontManager {
  /// Establishes a two-way connection between a source of truth and a property of this control.
  ///
  /// - Parameters:
  ///   - binding: A source of truth for the control's value.
  ///   - keyPath: A key path to the control's value.
  ///   - event: The control-specific events for which the binding is updated.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind<Value>(
    _ binding: UIBinding<Value>,
    to keyPath: ReferenceWritableKeyPath<NSFontManager, Value>
  ) -> ObserveToken {
    bind(binding, to: keyPath) { control, newValue, _ in
      control[keyPath: keyPath] = newValue
    }
  }

  /// Establishes a two-way connection between a source of truth and a property of this control.
  ///
  /// - Parameters:
  ///   - binding: A source of truth for the control's value.
  ///   - keyPath: A key path to the control's value.
  ///   - event: The control-specific events for which the binding is updated.
  ///   - set: A closure that is called when the binding's value changes with a weakly-captured
  ///     control, a new value that can be used to configure the control, and a transaction, which
  ///     can be used to determine how and if the change should be animated.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind<Value>(
    _ binding: UIBinding<Value>,
    to keyPath: KeyPath<NSFontManager, Value>,
    set: @escaping (_ control: NSFontManager, _ newValue: Value, _ transaction: UITransaction) -> Void
  ) -> ObserveToken {
    establishBinding(binding, to: keyPath, of: self, through: createActionProxyIfNeeded(), set: set)
  }

  public func unbind<Value>(_ keyPath: KeyPath<NSFontManager, Value>) {
    removeBinding(to: keyPath)
  }

  private func createActionProxyIfNeeded() -> TargetActionProxy {
    if let actionProxy {
      return actionProxy
    } else {
      let actionProxy = TargetActionProxy(fontManager: self)
      self.actionProxy = actionProxy
      return actionProxy
    }
  }
}

#endif
