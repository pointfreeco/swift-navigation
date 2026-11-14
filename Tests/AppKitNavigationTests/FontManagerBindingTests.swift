#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  // NB: Imported publicly because Swift 6.2 rejects the 'NSApplicationDelegate' conformance below
  //     as public otherwise, even on a private class. Later compilers accept either import.
  public import AppKit
  import AppKitNavigation
  import Testing

  /// Stands in for the text view the font panel normally edits. The font manager only sends its
  /// action while some responder implements `changeFont:`, and the responder chain ends at the
  /// application's delegate, so installing one there works without any window.
  private final class ChangeFontResponder: NSObject, NSApplicationDelegate {
    @objc func changeFont(_ sender: NSFontManager?) {}
  }

  @MainActor
  @Suite struct FontManagerBindingTests {
    /// The font panel's trait buttons and menu items go through `addFontTrait(_:)`, which records
    /// the change and sends the font manager's action; `convert(_:)` then applies it to a font.
    @Test("a change from the font panel is applied to the bound font")
    func fontPanelChangeIsAppliedToTheBoundFont() throws {
      try withChangeFontResponder {
        @UIBinding var textStyle = TextStyle(font: try Self.helvetica())
        let fontManager = NSFontManager.shared
        fontManager.bind(font: $textStyle.font)

        fontManager.addFontTrait(Self.boldMenuItem())

        #expect(textStyle.font.familyName == "Helvetica")
        #expect(textStyle.font.pointSize == 20)
        #expect(fontManager.traits(of: textStyle.font).contains(.boldFontMask))
      }
    }

    @Test("rebinding the font manager stops writing changes to the previous binding")
    func rebindingStopsWritingToThePreviousBinding() throws {
      try withChangeFontResponder {
        @UIBinding var previousStyle = TextStyle(font: try Self.helvetica())
        @UIBinding var currentStyle = TextStyle(font: try Self.helvetica())
        let fontManager = NSFontManager.shared
        fontManager.bind(font: $previousStyle.font)
        fontManager.bind(font: $currentStyle.font)

        fontManager.addFontTrait(Self.boldMenuItem())

        #expect(fontManager.traits(of: currentStyle.font).contains(.boldFontMask))
        #expect(!fontManager.traits(of: previousStyle.font).contains(.boldFontMask))
      }
    }

    /// Holds the font in a value, the way a model would, rather than binding a class instance
    /// directly.
    private struct TextStyle {
      var font: NSFont
    }

    private static func helvetica() throws -> NSFont {
      try #require(NSFont(name: "Helvetica", size: 20))
    }

    /// The font menu's Bold item, which `addFontTrait(_:)` reads the trait to add from.
    private static func boldMenuItem() -> NSMenuItem {
      let boldMenuItem = NSMenuItem()
      boldMenuItem.tag = Int(NSFontTraitMask.boldFontMask.rawValue)
      return boldMenuItem
    }

    private func withChangeFontResponder(_ body: () throws -> Void) rethrows {
      let responder = ChangeFontResponder()
      let application = NSApplication.shared
      let previousDelegate = application.delegate
      application.delegate = responder
      defer { application.delegate = previousDelegate }
      try body()
    }
  }
#endif
