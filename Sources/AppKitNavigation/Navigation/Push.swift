#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  import AppKit
  public import AppKitPlus

  extension NSTraitCollection {
    /// Pushes a value onto the navigation stack controller this content is in.
    ///
    /// Calling ``AppKitPushAction/callAsFunction(value:fileID:filePath:line:column:)`` appends a
    /// copy of the value to the path that drives the current ``NavigationStackController``:
    ///
    /// ```swift
    /// let detailButton = NSButton(title: "Details", target: nil, action: nil)
    /// detailButton.addAction { [weak self] _ in
    ///   self?.traitCollection.push(value: Route.detail)
    /// }
    /// ```
    ///
    /// Outside a navigation stack controller, the push is reported as an issue instead.
    ///
    /// Available with the `AppKitPlus` package trait.
    public var push: AppKitPushAction {
      self[PushActionTrait.self]?.action ?? AppKitPushAction(run: nil)
    }
  }

  /// Pushes a value onto a navigation stack controller.
  ///
  /// You will not typically refer to this type directly. Read it from a trait collection, as
  /// ``AppKitPlus/NSTraitCollection/push``, and call it as a function.
  ///
  /// Available with the `AppKitPlus` package trait.
  @MainActor
  public struct AppKitPushAction: Sendable {
    let run: (@MainActor @Sendable (AnyHashable) -> Void)?

    /// Pushes a value onto the navigation stack controller's path.
    ///
    /// - Parameters:
    ///   - value: The value to push. A copy is appended to the path that drives the current
    ///     ``NavigationStackController``.
    ///   - fileID: The source `#fileID` associated with the push.
    ///   - filePath: The source `#filePath` associated with the push.
    ///   - line: The source `#line` associated with the push.
    ///   - column: The source `#column` associated with the push.
    public func callAsFunction<Element: Hashable>(
      value: Element,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      line: UInt = #line,
      column: UInt = #column
    ) {
      guard let run else {
        reportIssue(
          """
          Tried to push a value from outside of a navigation stack.

          'NSTraitCollection.push(value:)' must be called from content in a \
          'NavigationStackController'.
          """,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
        return
      }
      run(value)
    }
  }

  /// Carries a push action through AppKitPlus's trait storage, which keeps only objects: a value
  /// that is not one is stored as no value at all.
  final class PushActionBox: NSObject, @unchecked Sendable {
    // NB: Unchecked, since the box never changes once made, and the action is sendable.
    let action: AppKitPushAction

    init(_ action: AppKitPushAction) {
      self.action = action
    }
  }

  enum PushActionTrait: NSTraitDefinition {
    static var defaultValue: PushActionBox? { nil }
    static var identifier: String { "AppKitNavigation.PushAction" }
  }

  extension NSMutableTraits {
    var push: AppKitPushAction {
      get { self[PushActionTrait.self]?.action ?? AppKitPushAction(run: nil) }
      set { self[PushActionTrait.self] = newValue.run == nil ? nil : PushActionBox(newValue) }
    }
  }
#endif
