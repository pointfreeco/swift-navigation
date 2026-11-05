#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  /// Each typed binding keeps its control and its source of truth in step: the control shows the
  /// bound value, follows later changes to it, and writes the user's changes back.
  @MainActor
  @Suite(.keepsMainRunLoopRunning) struct ControlBindingRoundTripTests {
    init() {
      // NB: A control sends its action through 'NSApplication.sendAction(_:to:from:)', which
      //     silently does nothing when no application object exists yet.
      _ = NSApplication.shared
    }

    @Test("a switch stays in step with its binding")
    func switchStaysInStep() async {
      @UIBinding var isOn = true
      let switchControl = NSSwitch(isOn: $isOn)
      #expect(switchControl.state == .on)

      isOn = false
      await Task.yield()
      #expect(switchControl.state == .off)

      // NB: A click changes the switch's state without going through the property the binding
      //     observes, so only the action can carry the change back.
      switchControl.performClick(nil)
      #expect(isOn)
    }

    @Test("a slider stays in step with its binding")
    func sliderStaysInStep() async {
      @UIBinding var value: Float = 0.25
      let slider = NSSlider(value: $value)
      #expect(slider.floatValue == 0.25)

      value = 0.75
      await Task.yield()
      #expect(slider.floatValue == 0.75)

      slider.floatValue = 0.5
      sendAction(of: slider)
      #expect(value == 0.5)
    }

    @Test("a stepper stays in step with its binding")
    func stepperStaysInStep() async {
      @UIBinding var value: Double = 3
      let stepper = NSStepper(value: $value)
      #expect(stepper.doubleValue == 3)

      value = 7
      await Task.yield()
      #expect(stepper.doubleValue == 7)

      stepper.doubleValue = 5
      sendAction(of: stepper)
      #expect(value == 5)
    }

    @Test("a date picker stays in step with its binding")
    func datePickerStaysInStep() async {
      @UIBinding var date = Date(timeIntervalSinceReferenceDate: 0)
      let datePicker = NSDatePicker(date: $date)
      #expect(datePicker.dateValue == Date(timeIntervalSinceReferenceDate: 0))

      date = Date(timeIntervalSinceReferenceDate: 86_400)
      await Task.yield()
      #expect(datePicker.dateValue == Date(timeIntervalSinceReferenceDate: 86_400))

      datePicker.dateValue = Date(timeIntervalSinceReferenceDate: 172_800)
      sendAction(of: datePicker)
      #expect(date == Date(timeIntervalSinceReferenceDate: 172_800))
    }

    @Test("a color well stays in step with its binding")
    func colorWellStaysInStep() async {
      @UIBinding var swatch = Swatch(color: Self.red)
      let colorWell = NSColorWell(color: $swatch.color)
      #expect(colorWell.color == Self.red)

      swatch.color = Self.blue
      await Task.yield()
      #expect(colorWell.color == Self.blue)

      colorWell.color = Self.green
      sendAction(of: colorWell)
      #expect(swatch.color == Self.green)
    }

    @Test("a path control stays in step with its binding")
    func pathControlStaysInStep() async {
      @UIBinding var url: URL? = URL(filePath: "/System")
      let pathControl = NSPathControl(url: $url)
      #expect(pathControl.url?.lastPathComponent == "System")

      url = URL(filePath: "/Library")
      await Task.yield()
      #expect(pathControl.url?.lastPathComponent == "Library")

      pathControl.url = URL(filePath: "/Applications")
      sendAction(of: pathControl)
      #expect(url?.lastPathComponent == "Applications")
    }

    @Test("a segmented control stays in step with its binding")
    func segmentedControlStaysInStep() async {
      @UIBinding var segment = Segment.second
      let segmentedControl = NSSegmentedControl(
        labels: ["First", "Second", "Third"], trackingMode: .selectOne, target: nil, action: nil
      )
      segmentedControl.bind(selectedSegment: $segment)
      #expect(segmentedControl.selectedSegment == 1)

      segment = .third
      await Task.yield()
      #expect(segmentedControl.selectedSegment == 2)

      segmentedControl.selectedSegment = 0
      sendAction(of: segmentedControl)
      #expect(segment == .first)
    }

    /// `NSSavePanel.bind(url:)` and `NSOpenPanel.bind(urls:)` hook the private setters through
    /// which a panel records what the user confirmed. Should AppKit drop or rename them, the
    /// bindings would stop being written without any error; this test is what notices.
    @Test(
      "the private setters the panel bindings hook still exist",
      arguments: ["setFinalURL:", "setFinalURLs:"]
    )
    func panelSettersStillExist(_ selectorName: String) {
      #expect(NSSavePanel.instancesRespond(to: NSSelectorFromString(selectorName)))
    }

    private enum Segment: Int {
      case first
      case second
      case third
    }

    /// Holds the color in a value, the way a model would, rather than binding a class instance
    /// directly.
    private struct Swatch {
      var color: NSColor
    }

    private static let red = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
    private static let green = NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
    private static let blue = NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)

    /// What a control does once the user has changed its value.
    private func sendAction(of control: NSControl) {
      control.sendAction(control.action, to: control.target)
    }
  }
#endif
