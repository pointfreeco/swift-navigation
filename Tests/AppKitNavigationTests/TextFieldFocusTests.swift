#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  @MainActor
  @Suite struct TextFieldFocusTests {
    enum Field: Hashable {
      case name
      case email
    }

    /// Clicking into a field, or tabbing to it, makes it first responder without changing any text.
    @Test("focusing a field reports it before anything is typed")
    func focusingAFieldReportsItBeforeTyping() {
      let form = Form()
      @UIBinding var focus: Field? = nil
      form.nameField.bind(focus: $focus, equals: .name)

      form.window.makeFirstResponder(form.nameField)

      #expect(focus == .name)
    }

    @Test("moving focus to another field writes nil back")
    func movingFocusAwayWritesNilBack() throws {
      let form = Form()
      @UIBinding var focus: Field? = nil
      form.nameField.bind(focus: $focus, equals: .name)
      form.window.makeFirstResponder(form.nameField)
      try #require(focus == .name, "The field never reported gaining focus")

      form.window.makeFirstResponder(form.emailField)

      #expect(focus == nil)
    }

    @Test("setting the binding focuses the field")
    func settingTheBindingFocusesTheField() async {
      let form = Form()
      @UIBinding var focus: Field? = nil
      form.nameField.bind(focus: $focus, equals: .name)

      focus = .name
      // NB: 'observe' applies the new value on a later turn of the main queue.
      await Task.yield()

      #expect(form.focusedField === form.nameField)
    }

    @Test("setting the binding to nil takes focus away from the field")
    func settingTheBindingToNilRemovesFocus() async {
      let form = Form()
      @UIBinding var focus: Field? = nil
      form.nameField.bind(focus: $focus, equals: .name)
      form.window.makeFirstResponder(form.nameField)
      focus = .name
      await Task.yield()

      focus = nil
      await Task.yield()

      #expect(form.focusedField == nil)
    }

    /// Two text fields in a window.
    @MainActor
    private struct Form {
      let window: NSWindow
      let nameField = NSTextField(string: "")
      let emailField = NSTextField(string: "")

      init() {
        window = NSWindow(
          contentRect: NSRect(x: 0, y: 0, width: 240, height: 96),
          styleMask: [.titled],
          backing: .buffered,
          defer: false
        )
        window.isReleasedWhenClosed = false
        nameField.frame = NSRect(x: 20, y: 56, width: 200, height: 24)
        emailField.frame = NSRect(x: 20, y: 20, width: 200, height: 24)
        window.contentView?.addSubview(nameField)
        window.contentView?.addSubview(emailField)
      }

      /// The text field being edited: the window's first responder is then the field editor,
      /// whose delegate is that text field.
      var focusedField: NSTextField? {
        (window.firstResponder as? NSTextView)?.delegate as? NSTextField
      }
    }
  }
#endif
