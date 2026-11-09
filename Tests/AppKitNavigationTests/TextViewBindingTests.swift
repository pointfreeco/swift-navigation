#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  /// A text view bound to a string shows it, follows later changes to it, and writes the user's
  /// edits back, without getting in the way of an input method that is composing text.
  @MainActor
  @Suite struct TextViewBindingTests {
    @Test("a text view stays in step with its binding")
    func textViewStaysInStep() async {
      @UIBinding var comment = "First draft"
      let textView = NSTextView()
      textView.bind(text: $comment)
      #expect(textView.string == "First draft")

      comment = "Second draft"
      await Task.yield()
      #expect(textView.string == "Second draft")

      textView.insertText("!", replacementRange: NSRange(location: 12, length: 0))
      #expect(comment == "Second draft!")
    }

    @Test("edits are written back only once an input method finishes composing")
    func compositionIsWrittenBackWhenItEnds() {
      @UIBinding var comment = ""
      let textView = NSTextView()
      textView.bind(text: $comment)

      textView.setMarkedText(
        "ka",
        selectedRange: NSRange(location: 2, length: 0),
        replacementRange: NSRange(location: NSNotFound, length: 0)
      )
      #expect(textView.hasMarkedText())
      #expect(comment == "")

      textView.insertText("か", replacementRange: NSRange(location: NSNotFound, length: 0))
      #expect(!textView.hasMarkedText())
      #expect(comment == "か")
    }

    @Test("a change to the binding keeps the selection where it can")
    func bindingChangeKeepsTheSelection() async {
      @UIBinding var comment = "Hello"
      let textView = NSTextView()
      textView.bind(text: $comment)
      textView.setSelectedRange(NSRange(location: 1, length: 3))

      comment = "Hello, world"
      await Task.yield()
      #expect(textView.selectedRange() == NSRange(location: 1, length: 3))

      comment = "He"
      await Task.yield()
      #expect(textView.selectedRange() == NSRange(location: 1, length: 1))
    }

    @Test("unbinding a text view stops writing edits to the binding")
    func unbindingStopsWritingEdits() {
      @UIBinding var comment = "Original"
      let textView = NSTextView()
      textView.bind(text: $comment)

      textView.unbindText()
      textView.insertText(" text", replacementRange: NSRange(location: 8, length: 0))

      #expect(comment == "Original")
    }
  }
#endif
