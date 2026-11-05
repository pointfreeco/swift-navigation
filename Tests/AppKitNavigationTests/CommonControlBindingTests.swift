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

    // MARK: - Choosing one of several options

    @Test("a pop-up button stays in step with its selection")
    func popUpButtonStaysInStep() async {
      @UIBinding var weight = Weight.regular
      let popUpButton = NSPopUpButton(selection: $weight, options: Weight.allCases, title: \.title)
      #expect(popUpButton.itemTitles == ["Light", "Regular", "Bold"])
      #expect(popUpButton.indexOfSelectedItem == 1)

      weight = .bold
      await Task.yield()
      #expect(popUpButton.indexOfSelectedItem == 2)

      popUpButton.selectItem(at: 0)
      sendAction(of: popUpButton)
      #expect(weight == .light)
    }

    /// Adding items by title would merge two options that share one.
    @Test("a pop-up button keeps an item for each option, even when titles repeat")
    func popUpButtonKeepsAnItemForEachOption() {
      @UIBinding var weight = Weight.bold
      let popUpButton = NSPopUpButton(
        selection: $weight, options: Weight.allCases, title: { _ in "Same" }
      )
      #expect(popUpButton.numberOfItems == 3)
      #expect(popUpButton.indexOfSelectedItem == 2)
    }

    @Test("a segmented control stays in step with its selection")
    func segmentedControlStaysInStep() async {
      @UIBinding var layout = Layout.list
      let segmentedControl = NSSegmentedControl(
        selection: $layout, options: [.icons, .list, .columns], title: \.title
      )
      #expect(segmentedControl.segmentCount == 3)
      #expect(segmentedControl.label(forSegment: 2) == "Columns")
      #expect(segmentedControl.selectedSegment == 1)

      layout = .columns
      await Task.yield()
      #expect(segmentedControl.selectedSegment == 2)

      segmentedControl.selectedSegment = 0
      sendAction(of: segmentedControl)
      #expect(layout == .icons)
    }

    @Test("a selection that is not one of the options is reported and selects nothing")
    func selectionOutsideTheOptionsIsReported() {
      @UIBinding var weight = Weight.bold
      var popUpButton: NSPopUpButton?
      withKnownIssue {
        popUpButton = NSPopUpButton(selection: $weight, options: [.light, .regular], title: \.title)
      }
      #expect(popUpButton?.indexOfSelectedItem == -1)
    }

    @Test("choosing an item that is not one of the options is reported and changes nothing")
    func choosingAnItemOutsideTheOptionsIsReported() {
      @UIBinding var weight = Weight.regular
      let popUpButton = NSPopUpButton(selection: $weight, options: Weight.allCases, title: \.title)
      popUpButton.menu?.addItem(withTitle: "Custom…", action: nil, keyEquivalent: "")

      popUpButton.selectItem(at: 3)
      withKnownIssue {
        sendAction(of: popUpButton)
      }
      #expect(weight == .regular)
    }

    // MARK: - Segments selected on their own

    @Test("each segment of a segmented control can stay in step with a binding of its own")
    func segmentSelectionStaysInStep() async {
      @UIBinding var showsSidebar = true
      @UIBinding var showsInspector = false
      let segmentedControl = NSSegmentedControl(
        labels: ["Sidebar", "Inspector"], trackingMode: .selectAny, target: nil, action: nil
      )
      segmentedControl.bind(isSelected: $showsSidebar, forSegment: 0)
      segmentedControl.bind(isSelected: $showsInspector, forSegment: 1)
      #expect(segmentedControl.isSelected(forSegment: 0))
      #expect(!segmentedControl.isSelected(forSegment: 1))

      showsInspector = true
      await Task.yield()
      #expect(segmentedControl.isSelected(forSegment: 1))

      // NB: Binding the second segment must not have replaced the first one's binding.
      segmentedControl.setSelected(false, forSegment: 0)
      sendAction(of: segmentedControl)
      #expect(!showsSidebar)
      #expect(showsInspector)
    }

    // MARK: - Helpers

    private enum Weight: CaseIterable {
      case light
      case regular
      case bold

      var title: String {
        switch self {
        case .light: "Light"
        case .regular: "Regular"
        case .bold: "Bold"
        }
      }
    }

    /// Not raw-representable, unlike what `bind(selectedSegment:)` takes.
    private enum Layout {
      case icons
      case list
      case columns

      var title: String {
        switch self {
        case .icons: "Icons"
        case .list: "List"
        case .columns: "Columns"
        }
      }
    }

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
