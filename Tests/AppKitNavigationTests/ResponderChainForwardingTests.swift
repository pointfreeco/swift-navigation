#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  // NB: Imported publicly because Swift 6.2 rejects the 'NSApplicationDelegate' conformance below
  //     as public otherwise, even on a private class. Later compilers accept either import.
  public import AppKit
  import AppKitNavigation
  import Testing

  /// An action whose target is `nil` travels up the responder chain. When the library takes over a
  /// target-action pair, that action still has to reach the chain.
  ///
  /// The chain ends at the application's delegate, so a recipient installed there receives the
  /// action without any window on screen.
  private final class ApplicationDelegateRecipient: NSObject, NSApplicationDelegate {
    var recordedActionCount = 0
    var changeFontCount = 0

    @objc func recordAction(_ sender: Any?) {
      recordedActionCount += 1
    }

    @objc func changeFont(_ sender: NSFontManager?) {
      changeFontCount += 1
    }
  }

  @MainActor
  @Suite struct ResponderChainForwardingTests {
    private func withApplicationDelegate(
      _ recipient: ApplicationDelegateRecipient, _ body: () -> Void
    ) {
      let application = NSApplication.shared
      let previousDelegate = application.delegate
      application.delegate = recipient
      defer { application.delegate = previousDelegate }
      body()
    }

    @Test("a menu item's responder-chain action keeps firing alongside closure actions")
    func menuItemResponderChainActionKeepsFiring() {
      let recipient = ApplicationDelegateRecipient()
      withApplicationDelegate(recipient) {
        let menuItem = NSMenuItem(
          title: "Record",
          action: #selector(ApplicationDelegateRecipient.recordAction(_:)),
          keyEquivalent: ""
        )
        let menu = NSMenu()
        menu.addItem(menuItem)
        menuItem.addAction { _ in }

        menu.performActionForItem(at: 0)
      }

      #expect(recipient.recordedActionCount == 1)
    }

    /// The font panel sends `changeFont:` up the responder chain through the shared font manager,
    /// whose target is `nil`; binding a font must not cut text views off from it.
    @Test("binding a font keeps the font manager's responder-chain action firing")
    func bindingAFontKeepsTheResponderChainActionFiring() {
      let recipient = ApplicationDelegateRecipient()
      withApplicationDelegate(recipient) {
        @UIBinding var textStyle = TextStyle(font: NSFont.systemFont(ofSize: 12))
        let fontManager = NSFontManager.shared
        fontManager.bind(font: $textStyle.font)

        fontManager.sendAction()
      }

      #expect(recipient.changeFontCount == 1)
    }

    /// Holds the font in a value, the way a model would, rather than binding a class instance
    /// directly.
    private struct TextStyle {
      var font: NSFont
    }
  }
#endif
