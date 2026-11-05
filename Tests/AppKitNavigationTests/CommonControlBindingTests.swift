#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  /// The typed bindings for checkboxes, pop-up buttons, segmented controls, split view items, tab
  /// view controllers and menu items keep the user interface and the source of truth in step: it
  /// shows the bound value, follows later changes to it, and writes the user's changes back.
  @MainActor
  @Suite struct CommonControlBindingTests {
    init() {
      // NB: A control sends its action through 'NSApplication.sendAction(_:to:from:)', which
      //     silently does nothing when no application object exists yet.
      _ = NSApplication.shared
    }

    // MARK: - Checkboxes

    @Test("a checkbox stays in step with its binding")
    func checkboxStaysInStep() async {
      @UIBinding var isOn = true
      let checkbox = NSButton(checkboxWithTitle: "Option", isOn: $isOn)
      #expect(checkbox.state == .on)

      isOn = false
      await Task.yield()
      #expect(checkbox.state == .off)

      checkbox.state = .on
      sendAction(of: checkbox)
      #expect(isOn)
    }

    @Test("a checkbox stays in step with whether a set contains its member")
    func setMembershipCheckboxStaysInStep() async {
      @UIBinding var kinds: Set<DeclarationKind> = [.classes]
      let checkbox = NSButton(checkboxWithTitle: "Protocols", isOn: $kinds, contains: .protocols)
      #expect(checkbox.state == .off)

      kinds.insert(.protocols)
      await Task.yield()
      #expect(checkbox.state == .on)

      checkbox.state = .off
      sendAction(of: checkbox)
      #expect(kinds == [.classes])
    }

    /// An option set's elements are the option set itself, which need not be hashable.
    @Test("a checkbox stays in step with whether an option set contains its option")
    func optionSetMembershipCheckboxStaysInStep() async {
      @UIBinding var options: DumpOptions = [.comments]
      let checkbox = NSButton(checkboxWithTitle: "Offsets", isOn: $options, contains: .offsets)
      #expect(checkbox.state == .off)

      checkbox.state = .on
      sendAction(of: checkbox)
      #expect(options == [.comments, .offsets])

      options = []
      await Task.yield()
      #expect(checkbox.state == .off)
    }

    // MARK: - Helpers

    private enum DeclarationKind {
      case classes
      case protocols
    }

    private struct DumpOptions: OptionSet {
      let rawValue: Int

      static let comments = DumpOptions(rawValue: 1 << 0)
      static let offsets = DumpOptions(rawValue: 1 << 1)
    }

    /// What a control does once the user has changed its value.
    private func sendAction(of control: NSControl) {
      control.sendAction(control.action, to: control.target)
    }
  }
#endif
