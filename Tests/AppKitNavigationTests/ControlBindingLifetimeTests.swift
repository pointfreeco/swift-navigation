#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  @MainActor
  @Suite struct ControlBindingLifetimeTests {
    /// What a reused table cell does: the same text field is bound to the next row's model.
    @Test("rebinding a text field stops writing edits to the previous binding")
    func rebindingStopsWritingToThePreviousBinding() {
      @UIBinding var firstRowName = "first"
      @UIBinding var secondRowName = "second"
      let textField = NSTextField(text: $firstRowName)

      textField.bind(text: $secondRowName)
      edit(textField, to: "edited")

      #expect(firstRowName == "first")
    }

    @Test("unbinding a text field stops writing edits to the binding")
    func unbindingStopsWritingToTheBinding() {
      @UIBinding var name = "original"
      let textField = NSTextField(text: $name)

      textField.unbind(\.stringValue)
      edit(textField, to: "edited")

      #expect(name == "original")
    }

    /// The panel reports the URL the user confirmed through its private 'setFinalURL:' setter,
    /// which is what the binding hooks.
    @Test("rebinding a save panel keeps reporting the confirmed URL")
    func rebindingASavePanelKeepsReportingTheConfirmedURL() {
      @UIBinding var firstURL: URL? = nil
      @UIBinding var secondURL: URL? = nil
      let savePanel = NSSavePanel()
      savePanel.bind(url: $firstURL)
      savePanel.bind(url: $secondURL)

      let confirmedURL = URL(filePath: "/tmp/confirmed.txt")
      savePanel.perform(NSSelectorFromString("setFinalURL:"), with: confirmedURL)

      #expect(secondURL == confirmedURL)
    }

    @Test("rebinding an open panel keeps reporting the confirmed URLs")
    func rebindingAnOpenPanelKeepsReportingTheConfirmedURLs() {
      @UIBinding var firstURLs: [URL] = []
      @UIBinding var secondURLs: [URL] = []
      let openPanel = NSOpenPanel()
      openPanel.bind(urls: $firstURLs)
      openPanel.bind(urls: $secondURLs)

      let confirmedURLs = [URL(filePath: "/tmp/first.txt"), URL(filePath: "/tmp/second.txt")]
      openPanel.perform(NSSelectorFromString("setFinalURLs:"), with: confirmedURLs)

      #expect(secondURLs == confirmedURLs)
    }

    /// Types into the field the way the field editor reports it.
    private func edit(_ textField: NSTextField, to text: String) {
      textField.stringValue = text
      NotificationCenter.default.post(name: NSControl.textDidChangeNotification, object: textField)
    }
  }
#endif
