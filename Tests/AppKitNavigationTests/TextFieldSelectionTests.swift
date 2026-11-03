#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  @MainActor
  @Suite struct TextFieldSelectionTests {
    /// AppKit implements `textViewDidChangeSelection:` itself — on `NSControl` everywhere, and on
    /// `NSTextField` from macOS 27.2 on. A method of that name added to `NSTextField` by an
    /// extension replaces it for every text field in the process, bound or not.
    @Test("AppKit's own selection handling stays in place on every text field")
    func appKitsSelectionHandlingStaysInPlace() throws {
      let method = try #require(
        class_getInstanceMethod(NSTextField.self, NSSelectorFromString("textViewDidChangeSelection:"))
      )
      var imageInfo = Dl_info()
      let implementation = unsafeBitCast(method_getImplementation(method), to: UnsafeRawPointer.self)
      try #require(dladdr(implementation, &imageInfo) != 0)
      let imagePath = String(cString: try #require(imageInfo.dli_fname))

      #expect(imagePath.hasSuffix("/AppKit"), "Implemented in \(imagePath)")
    }

    @Test("moving the selection reports it at the right characters when the text has emoji")
    func movingTheSelectionReportsTheRightCharacters() throws {
      let editingSession = try EditingSession(text: "👍ab")
      @UIBinding var selection: AppKitTextSelection? = nil
      editingSession.textField.bind(selection: $selection)

      // "a": the thumbs-up sign takes two UTF-16 code units.
      editingSession.fieldEditor.selectedRange = NSRange(location: 2, length: 1)

      let selectedRange = try #require(selection?.range)
      #expect(editingSession.textField.stringValue[selectedRange] == "a")
    }

    @Test("setting the binding selects the right characters when the text has emoji")
    func settingTheBindingSelectsTheRightCharacters() async throws {
      let editingSession = try EditingSession(text: "👍ab")
      let text = editingSession.textField.stringValue
      @UIBinding var selection: AppKitTextSelection? = nil
      editingSession.textField.bind(selection: $selection)

      let rangeOfA = try #require(text.range(of: "a"))
      selection = AppKitTextSelection(range: rangeOfA)
      // NB: 'observe' applies the new value on a later turn of the main queue.
      await Task.yield()

      #expect(editingSession.fieldEditor.selectedRange == NSRange(location: 2, length: 1))
    }

    @Test("rebinding the selection keeps reporting selection changes")
    func rebindingKeepsReportingSelectionChanges() throws {
      let editingSession = try EditingSession(text: "hello")
      @UIBinding var firstSelection: AppKitTextSelection? = nil
      @UIBinding var secondSelection: AppKitTextSelection? = nil
      editingSession.textField.bind(selection: $firstSelection)
      editingSession.textField.bind(selection: $secondSelection)

      editingSession.fieldEditor.selectedRange = NSRange(location: 1, length: 3)

      let selectedRange = try #require(secondSelection?.range)
      #expect(editingSession.textField.stringValue[selectedRange] == "ell")
    }

    /// A text field in a window, being edited, so that it has a field editor.
    @MainActor
    private struct EditingSession {
      let window: NSWindow
      let textField: NSTextField
      let fieldEditor: NSText

      init(text: String) throws {
        textField = NSTextField(string: text)
        textField.frame = NSRect(x: 20, y: 20, width: 200, height: 24)
        window = NSWindow(
          contentRect: NSRect(x: 0, y: 0, width: 240, height: 64),
          styleMask: [.titled],
          backing: .buffered,
          defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView?.addSubview(textField)
        window.makeFirstResponder(textField)
        fieldEditor = try #require(textField.currentEditor(), "The text field did not start editing")
      }
    }
  }
#endif
