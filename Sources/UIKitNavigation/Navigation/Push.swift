#if canImport(UIKit) && !os(watchOS)
  import IssueReporting
  import UIKit

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension UITraitCollection {
    /// Pushes a value onto the current navigation stack controller.
    ///
    /// When you invoke ``UIPushAction/callAsFunction(value:fileID:filePath:line:column:)`` with a
    /// value, UIKit Navigation will append a copy to the underlying path driving the current
    /// navigation stack.
    ///
    /// ```swift
    /// UIButton(primaryAction: UIAction { [weak self] _ in
    ///   self?.traitCollection.push(Path.detail)
    /// })
    /// ```
    ///
    /// If there is no navigation stack, a runtime warning will be reported, instead.
    public var push: UIPushAction { self[PushActionTrait.self] }
  }

  /// A type that can push a value onto a navigation stack controller.
  ///
  /// You will not typically refer to this type directly. Instead you will invoke the
  /// ``UIKit/UITraitCollection/push`` trait's
  /// ``callAsFunction(value:fileID:filePath:line:column:)``.
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @MainActor
  public struct UIPushAction: Sendable {
    let run: (@MainActor @Sendable (AnyHashable) -> Void)?

    /// Pushes a value onto a navigation stack controller's stack.
    ///
    /// - Parameters:
    ///   - value: A value to present. A copy of this value will be pushed onto the current
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

          'UITraitCollection.push(value:)' must be called from an object in a \
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

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  private enum PushActionTrait: UITraitDefinition {
    static let defaultValue = UIPushAction(run: nil)
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension UIMutableTraits {
    var push: UIPushAction {
      get { self[PushActionTrait.self] }
      set { self[PushActionTrait.self] = newValue }
    }
  }
#endif
