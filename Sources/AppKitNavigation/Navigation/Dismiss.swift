#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  import AppKit
  public import AppKitPlus
  import SwiftNavigation

  extension NSTraitCollection {
    /// Dismisses the content this trait collection belongs to, through the binding that showed it.
    ///
    /// Content that a binding pushed onto a ``NavigationStackController``, or showed with
    /// `navigationDestination`, `present`, `sheet`, `modal`, `modalSession` or `popover`, can
    /// close itself without knowing how it was shown:
    ///
    /// ```swift
    /// let doneButton = NSButton(title: "Done", target: nil, action: nil)
    /// doneButton.addAction { [weak self] _ in
    ///   self?.traitCollection.dismiss()
    /// }
    /// ```
    ///
    /// The content ends as if the user had closed it: the binding is set to `nil`, and the
    /// presentation's `onDismiss` runs once the content has left the screen. Content that was not
    /// shown through a binding reports an issue instead.
    ///
    /// Available with the `AppKitPlus` package trait.
    public var dismiss: AppKitDismissAction {
      self[DismissActionTrait.self]?.action ?? AppKitDismissAction(run: nil)
    }

    /// Whether the content this trait collection belongs to was shown through a binding, and so
    /// can ``dismiss`` itself.
    ///
    /// Available with the `AppKitPlus` package trait.
    public var isPresented: Bool { dismiss.run != nil }
  }

  /// Dismisses content that a binding showed.
  ///
  /// You will not typically refer to this type directly. Read it from a trait collection, as
  /// ``AppKitPlus/NSTraitCollection/dismiss``, and call it as a function.
  ///
  /// Available with the `AppKitPlus` package trait.
  @MainActor
  public struct AppKitDismissAction: Sendable {
    let run: (@MainActor @Sendable (UITransaction) -> Void)?

    /// Dismisses the content, through the binding that showed it.
    public func callAsFunction() {
      guard let run else {
        reportIssue(
          """
          Content requested dismissal, but couldn't be dismissed.

          'NSTraitCollection.dismiss()' must be called from content that a binding showed, for \
          example with 'NSViewController.present(item:)' or \
          'NSViewController.navigationDestination(item:)'.
          """
        )
        return
      }
      run(.current)
    }
  }

  /// Carries a dismiss action through AppKitPlus's trait storage, which keeps only objects: a
  /// value that is not one is stored as no value at all.
  final class DismissActionBox: NSObject, @unchecked Sendable {
    // NB: Unchecked, since the box never changes once made, and the action is sendable.
    let action: AppKitDismissAction

    init(_ action: AppKitDismissAction) {
      self.action = action
    }
  }

  enum DismissActionTrait: NSTraitDefinition {
    static var defaultValue: DismissActionBox? { nil }
    static var identifier: String { "AppKitNavigation.DismissAction" }
  }

  /// Content that can hand a dismiss action down to everything it shows.
  @MainActor
  protocol DismissActionHost: AnyObject {
    func installDismissAction(_ action: AppKitDismissAction)
  }

  extension NSViewController: DismissActionHost {
    func installDismissAction(_ action: AppKitDismissAction) {
      traitOverrides.dismiss = action
    }
  }

  extension NSWindow: DismissActionHost {
    func installDismissAction(_ action: AppKitDismissAction) {
      traitOverrides.dismiss = action
    }
  }

  extension NSAlert: DismissActionHost {
    func installDismissAction(_ action: AppKitDismissAction) {
      window.traitOverrides.dismiss = action
    }
  }

  extension NSMutableTraits {
    var dismiss: AppKitDismissAction {
      get { self[DismissActionTrait.self]?.action ?? AppKitDismissAction(run: nil) }
      set { self[DismissActionTrait.self] = newValue.run == nil ? nil : DismissActionBox(newValue) }
    }
  }
#endif
