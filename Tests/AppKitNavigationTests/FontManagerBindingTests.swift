#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  @MainActor
  @Suite struct FontManagerBindingTests {
    /// Stands in for the text view the font panel normally edits. The font manager only sends its
    /// action while some responder implements `changeFont:`, and the responder chain ends at the
    /// application's delegate, so installing one there works without any window.
    private final class ChangeFontResponder: NSObject, NSApplicationDelegate {
      @objc func changeFont(_ sender: NSFontManager?) {}
    }

    /// The font panel's trait buttons and menu items go through `addFontTrait(_:)`, which records
    /// the change and sends the font manager's action; `convert(_:)` then applies it to a font.
    @Test("a change from the font panel is applied to the bound font")
    func fontPanelChangeIsAppliedToTheBoundFont() throws {
      let responder = ChangeFontResponder()
      let application = NSApplication.shared
      let previousDelegate = application.delegate
      application.delegate = responder
      defer { application.delegate = previousDelegate }

      @UIBinding var textStyle = TextStyle(font: try #require(NSFont(name: "Helvetica", size: 20)))
      let fontManager = NSFontManager.shared
      fontManager.bind(font: $textStyle.font)

      let boldMenuItem = NSMenuItem()
      boldMenuItem.tag = Int(NSFontTraitMask.boldFontMask.rawValue)
      fontManager.addFontTrait(boldMenuItem)

      #expect(textStyle.font.familyName == "Helvetica")
      #expect(textStyle.font.pointSize == 20)
      #expect(fontManager.traits(of: textStyle.font).contains(.boldFontMask))
    }

    /// Holds the font in a value, the way a model would, rather than binding a class instance
    /// directly.
    private struct TextStyle {
      var font: NSFont
    }
  }
#endif
