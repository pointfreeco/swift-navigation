#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  /// The color panel is one per application, so these tests share it and must not overlap.
  @MainActor
  @Suite(.serialized) struct ColorPanelBindingTests {
    init() {
      // NB: The panel sends its action through 'NSApplication.sendAction(_:to:from:)', which
      //     silently does nothing when no application object exists yet.
      _ = NSApplication.shared
    }

    /// The binding takes the panel's target-action pair over and has to keep forwarding the
    /// original one, so it reads the panel's action first. The panel has no public getter for it,
    /// and reading it through key-value coding raised an exception, since KVC cannot return a
    /// selector: every call to `bind(color:)` crashed.
    @Test("the color panel reports the action it was given")
    func colorPanelReportsTheActionItWasGiven() {
      let colorPanel = NSColorPanel.shared
      let previousAction = colorPanel.action
      defer { colorPanel.action = previousAction }

      colorPanel.action = #selector(ColorRecipient.takeColor(_:))

      #expect(colorPanel.action == #selector(ColorRecipient.takeColor(_:)))
    }

    @Test("the color panel stays in step with its binding")
    func colorPanelStaysInStep() async throws {
      @UIBinding var swatch = Swatch(color: Self.red)
      let colorPanel = NSColorPanel.shared
      colorPanel.bind(color: $swatch.color)
      defer { colorPanel.unbind(\.color) }
      #expect(colorPanel.color == Self.red)

      swatch.color = Self.blue
      await Task.yield()
      #expect(colorPanel.color == Self.blue)

      // NB: What the panel does when the user picks a color.
      colorPanel.color = Self.green
      NSApplication.shared.sendAction(
        try #require(colorPanel.action), to: colorPanel.target, from: colorPanel
      )
      #expect(swatch.color == Self.green)
    }

    private final class ColorRecipient: NSObject {
      @objc func takeColor(_ sender: Any?) {}
    }

    /// Holds the color in a value, the way a model would, rather than binding a class instance
    /// directly.
    private struct Swatch {
      var color: NSColor
    }

    private static let red = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
    private static let green = NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
    private static let blue = NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
  }
#endif
