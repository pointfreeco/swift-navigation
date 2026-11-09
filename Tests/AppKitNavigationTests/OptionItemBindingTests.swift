#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  /// Pop-up buttons and segmented controls make their items from the options they are bound to,
  /// keep those items in step with options that change, and leave items the app adds alone.
  @MainActor
  @Suite struct OptionItemBindingTests {
    init() {
      // NB: A control sends its action through 'NSApplication.sendAction(_:to:from:)', which
      //     silently does nothing when no application object exists yet.
      _ = NSApplication.shared
    }

    // MARK: - Pop-up buttons

    @Test("binding an existing pop-up button makes an item for each option")
    func bindingMakesAnItemForEachOption() {
      @UIBinding var filter = Filter.publicOnly
      let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)

      popUpButton.bind(
        selection: $filter, options: Filter.allCases, title: \.title, image: { $0.image }
      )

      #expect(popUpButton.itemTitles == ["All", "Public", "Private"])
      #expect(popUpButton.itemArray.map(\.image) == Filter.allCases.map(\.image))
      #expect(popUpButton.indexOfSelectedItem == 1)

      popUpButton.selectItem(at: 2)
      sendAction(of: popUpButton)
      #expect(filter == .privateOnly)
    }

    @Test("a pop-up button's items follow options that change with the model")
    func itemsFollowOptionsThatChange() async {
      @UIBindable var model = TagModel(tags: ["Red", "Blue"], selectedTag: "Blue")
      let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
      popUpButton.bind(
        selection: $model.selectedTag,
        options: { [nil] + model.tags },
        title: { $0 ?? "No Tag" }
      )
      #expect(popUpButton.itemTitles == ["No Tag", "Red", "Blue"])

      model.tags.insert("Green", at: 0)
      await Task.yield()

      #expect(popUpButton.itemTitles == ["No Tag", "Green", "Red", "Blue"])
      #expect(popUpButton.titleOfSelectedItem == "Blue")
    }

    @Test("an item whose title changes with the model is retitled in place")
    func itemsAreRetitledInPlace() async {
      @UIBindable var model = TagModel(tags: ["Red"], selectedTag: "Red")
      let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
      popUpButton.bind(
        selection: $model.selectedTag,
        options: { model.tags.map(Optional.some) },
        title: { tag in "\(tag ?? "") (\(model.usageCount))" }
      )
      let item = popUpButton.itemArray.first

      model.usageCount = 3
      await Task.yield()

      #expect(popUpButton.itemTitles == ["Red (3)"])
      #expect(popUpButton.itemArray.first === item)
    }

    @Test("items the app adds stay below the options as the options change")
    func appItemsStayBelowTheOptions() async {
      @UIBindable var model = TagModel(tags: ["Red"], selectedTag: "Red")
      let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
      popUpButton.bind(
        selection: $model.selectedTag,
        options: { model.tags.map(Optional.some) },
        title: { $0 ?? "" }
      )
      let newTagItem = NSMenuItem(title: "New Tag…", action: nil, keyEquivalent: "")
      popUpButton.menu?.addItem(newTagItem)

      model.tags.append("Blue")
      await Task.yield()

      #expect(popUpButton.itemTitles == ["Red", "Blue", "New Tag…"])
      #expect(popUpButton.itemArray.last === newTagItem)
    }

    @Test("choosing an item the app added leaves the binding alone and shows the option again")
    func choosingAnAppItemLeavesTheBindingAlone() {
      @UIBindable var model = TagModel(tags: ["Red", "Blue"], selectedTag: "Blue")
      let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
      popUpButton.bind(
        selection: $model.selectedTag,
        options: { model.tags.map(Optional.some) },
        title: { $0 ?? "" }
      )
      popUpButton.menu?.addItem(withTitle: "Custom…", action: nil, keyEquivalent: "")

      popUpButton.selectItem(withTitle: "Custom…")
      sendAction(of: popUpButton)

      #expect(model.selectedTag == "Blue")
      #expect(popUpButton.titleOfSelectedItem == "Blue")
    }

    /// An item with an action of its own sends that action instead of the pop-up button's.
    @Test("choosing an item with an action of its own runs it and shows the option again")
    func choosingAnItemWithItsOwnActionShowsTheOptionAgain() {
      @UIBindable var model = TagModel(tags: ["Red", "Blue"], selectedTag: "Blue")
      let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
      popUpButton.bind(
        selection: $model.selectedTag,
        options: { model.tags.map(Optional.some) },
        title: { $0 ?? "" }
      )
      let recorder = ActionRecorder()
      let newTagItem = NSMenuItem(
        title: "New Tag…", action: #selector(ActionRecorder.record(_:)), keyEquivalent: ""
      )
      newTagItem.target = recorder
      popUpButton.menu?.addItem(newTagItem)

      let newTagIndex = popUpButton.index(of: newTagItem)
      popUpButton.selectItem(at: newTagIndex)
      popUpButton.menu?.performActionForItem(at: newTagIndex)

      #expect(recorder.callCount == 1)
      #expect(model.selectedTag == "Blue")
      #expect(popUpButton.titleOfSelectedItem == "Blue")
    }

    @Test("binding a pop-up button again reuses the items it made")
    func bindingAgainReusesTheItems() {
      @UIBinding var filter = Filter.privateOnly
      let popUpButton = NSPopUpButton(selection: $filter, options: Filter.allCases, title: \.title)

      popUpButton.bind(selection: $filter, options: [.all, .privateOnly], title: \.title)

      #expect(popUpButton.itemTitles == ["All", "Private"])
      #expect(popUpButton.titleOfSelectedItem == "Private")
    }

    // MARK: - Segmented controls

    @Test("binding a segmented control makes a segment for each option, as the options change")
    func segmentedControlMakesASegmentForEachOption() async {
      @UIBindable var model = LayoutModel(layouts: [.icons, .list], layout: .list)
      let segmentedControl = NSSegmentedControl()
      segmentedControl.bind(
        selection: $model.layout,
        options: { model.layouts },
        title: \.title,
        image: { $0.image }
      )
      #expect(segmentedControl.segmentCount == 2)
      #expect(segmentedControl.label(forSegment: 1) == "List")
      #expect(segmentedControl.image(forSegment: 0) === Layout.icons.image)
      #expect(segmentedControl.selectedSegment == 1)

      model.layouts.append(.columns)
      await Task.yield()
      #expect(segmentedControl.segmentCount == 3)
      #expect(segmentedControl.label(forSegment: 2) == "Columns")
      #expect(segmentedControl.selectedSegment == 1)

      segmentedControl.selectedSegment = 2
      sendAction(of: segmentedControl)
      #expect(model.layout == .columns)
    }

    // MARK: - Support

    /// What a control does once the user has changed its value.
    private func sendAction(of control: NSControl) {
      control.sendAction(control.action, to: control.target)
    }
  }

  private enum Filter: CaseIterable {
    case all
    case publicOnly
    case privateOnly

    var title: String {
      switch self {
      case .all: "All"
      case .publicOnly: "Public"
      case .privateOnly: "Private"
      }
    }

    @MainActor
    var image: NSImage {
      switch self {
      case .all: Self.allImage
      case .publicOnly: Self.publicImage
      case .privateOnly: Self.privateImage
      }
    }

    @MainActor private static let allImage = NSImage(size: NSSize(width: 1, height: 1))
    @MainActor private static let publicImage = NSImage(size: NSSize(width: 2, height: 2))
    @MainActor private static let privateImage = NSImage(size: NSSize(width: 3, height: 3))
  }

  private enum Layout: Equatable {
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

    @MainActor
    var image: NSImage {
      switch self {
      case .icons: Self.iconsImage
      case .list: Self.listImage
      case .columns: Self.columnsImage
      }
    }

    @MainActor private static let iconsImage = NSImage(size: NSSize(width: 1, height: 1))
    @MainActor private static let listImage = NSImage(size: NSSize(width: 2, height: 2))
    @MainActor private static let columnsImage = NSImage(size: NSSize(width: 3, height: 3))
  }

  @MainActor
  @Observable
  private final class TagModel {
    var tags: [String]
    var selectedTag: String?
    var usageCount = 0

    init(tags: [String], selectedTag: String?) {
      self.tags = tags
      self.selectedTag = selectedTag
    }
  }

  @MainActor
  @Observable
  private final class LayoutModel {
    var layouts: [Layout]
    var layout: Layout

    init(layouts: [Layout], layout: Layout) {
      self.layouts = layouts
      self.layout = layout
    }
  }

  @MainActor
  private final class ActionRecorder: NSObject {
    private(set) var callCount = 0

    @objc func record(_ sender: Any?) {
      callCount += 1
    }
  }
#endif
