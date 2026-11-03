#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  /// Menu items and toolbar items are enabled by asking whoever receives their action. When the
  /// library takes over the target-action pair, that answer must not change.
  ///
  /// These ask the item's target directly, through the validation protocols AppKit itself uses.
  /// Going through `NSMenu.update()` instead is not deterministic in a test process: within one
  /// turn of the event loop AppKit reuses earlier validation results for the same action, so
  /// the outcome depended on which test ran first.
  /// Implements the validation methods without declaring `NSMenuItemValidation` or
  /// `NSToolbarItemValidation`, as AppKit has long allowed, so the tests also cover a receiver
  /// that only implements them informally.
  private final class Validator: NSObject {
    let isValid: Bool

    init(isValid: Bool) {
      self.isValid = isValid
    }

    @objc func performItemAction(_ sender: Any?) {}

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool { isValid }

    @objc func validateToolbarItem(_ item: NSToolbarItem) -> Bool { isValid }
  }

  @MainActor
  @Suite struct ItemValidationTests {
    @Test("a menu item's target still answers as its original target would", arguments: [false, true])
    func menuItemFollowsItsOriginalTarget(isValid: Bool) throws {
      let validator = Validator(isValid: isValid)
      let menuItem = NSMenuItem(
        title: "Item", action: #selector(Validator.performItemAction(_:)), keyEquivalent: ""
      )
      menuItem.target = validator
      menuItem.addAction { _ in }

      let validation = try #require(menuItem.target as? any NSMenuItemValidation)

      #expect(validation.validateMenuItem(menuItem) == isValid)
    }

    /// A responder-chain action that nothing in the chain handles leaves the item disabled.
    @Test("a menu item stays disabled when nothing handles its responder-chain action")
    func menuItemWithUnhandledResponderChainActionStaysDisabled() throws {
      let menuItem = NSMenuItem(
        title: "Item", action: NSSelectorFromString("actionNothingHandles:"), keyEquivalent: ""
      )
      menuItem.addAction { _ in }

      let validation = try #require(menuItem.target as? any NSMenuItemValidation)

      #expect(!validation.validateMenuItem(menuItem))
    }

    @Test("a menu item with only closure actions is enabled")
    func menuItemWithOnlyClosureActionsIsEnabled() throws {
      let menuItem = NSMenuItem(title: "Item", action: nil, keyEquivalent: "")
      menuItem.addAction { _ in }

      let validation = try #require(menuItem.target as? any NSMenuItemValidation)

      #expect(validation.validateMenuItem(menuItem))
    }

    @Test("a toolbar item's target still answers as its original target would", arguments: [false, true])
    func toolbarItemFollowsItsOriginalTarget(isValid: Bool) throws {
      let validator = Validator(isValid: isValid)
      let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("item"))
      toolbarItem.target = validator
      toolbarItem.action = #selector(Validator.performItemAction(_:))
      toolbarItem.addAction { _ in }

      let validation = try #require(toolbarItem.target as? any NSToolbarItemValidation)

      #expect(validation.validateToolbarItem(toolbarItem) == isValid)
    }
  }
#endif
