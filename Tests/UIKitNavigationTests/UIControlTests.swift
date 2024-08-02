#if canImport(UIKit) && !os(watchOS)
  import UIKitNavigation
  import XCTest

  @available(iOS 14, tvOS 14, *)
  final class UIControlTests: XCTestCase {
    #if os(iOS)
      @MainActor
      func testColorWell() async throws {
        @UIBinding var color: UIColor? = .red
        let colorWell = UIColorWell(selectedColor: $color)
        XCTAssertEqual(color, .red)
        XCTAssertEqual(colorWell.selectedColor, .red)

        color = nil
        await Task.yield()
        XCTAssertEqual(color, nil)
        XCTAssertEqual(colorWell.selectedColor, nil)

        colorWell.selectedColor = .green
        XCTAssertEqual(color, .green)
        XCTAssertEqual(colorWell.selectedColor, .green)
      }

      @MainActor
      func testDatePicker() async throws {
        @UIBinding var date = Date(timeIntervalSinceReferenceDate: 0)
        let datePicker = UIDatePicker(date: $date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 0))
        XCTAssertEqual(datePicker.date, Date(timeIntervalSinceReferenceDate: 0))

        date = Date(timeIntervalSinceReferenceDate: 42)
        await Task.yield()
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 42))
        XCTAssertEqual(datePicker.date, Date(timeIntervalSinceReferenceDate: 42))

        datePicker.date = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(datePicker.date, Date(timeIntervalSince1970: 0))
      }
    #endif

    @MainActor
    func testPageControl() async throws {
      @UIBinding var page = 0
      let pageControl = UIPageControl(currentPage: $page)
      pageControl.numberOfPages = 3
      XCTAssertEqual(page, 0)
      XCTAssertEqual(pageControl.currentPage, 0)

      page += 1
      await Task.yield()
      XCTAssertEqual(page, 1)
      XCTAssertEqual(pageControl.currentPage, 1)

      pageControl.currentPage += 1
      XCTAssertEqual(page, 2)
      XCTAssertEqual(pageControl.currentPage, 2)
    }

    #if os(iOS)
      @MainActor
      func testSlider() async throws {
        @UIBinding var value: Float = 0
        let slider = UISlider(value: $value)
        XCTAssertEqual(value, 0)
        XCTAssertEqual(slider.value, 0)

        value = 0.5
        await Task.yield()
        XCTAssertEqual(value, 0.5)
        XCTAssertEqual(slider.value, 0.5)

        slider.value = 1
        XCTAssertEqual(value, 1)
        XCTAssertEqual(slider.value, 1)
      }

      @MainActor
      func testStepper() async throws {
        @UIBinding var value = 0.0
        let stepper = UIStepper(value: $value)
        XCTAssertEqual(value, 0)
        XCTAssertEqual(stepper.value, 0)

        value = 0.5
        await Task.yield()
        XCTAssertEqual(value, 0.5)
        XCTAssertEqual(stepper.value, 0.5)

        stepper.value = 1
        XCTAssertEqual(value, 1)
        XCTAssertEqual(stepper.value, 1)
      }

      @MainActor
      func testSwitch() async throws {
        @UIBinding var isOn = false
        let `switch` = UISwitch(isOn: $isOn)
        XCTAssertFalse(isOn)
        XCTAssertFalse(`switch`.isOn)

        isOn = true
        await Task.yield()
        XCTAssertTrue(isOn)
        XCTAssertTrue(`switch`.isOn)

        `switch`.isOn = false
        XCTAssertFalse(isOn)
        XCTAssertFalse(`switch`.isOn)
      }
    #endif

    @MainActor
    func testTextField() async throws {
      @UIBinding var text = ""
      let textField = UITextField(text: $text)
      XCTAssertEqual(text, "")
      XCTAssertEqual(textField.text, "")

      text += "Blob"
      await Task.yield()
      XCTAssertEqual(text, "Blob")
      XCTAssertEqual(textField.text, "Blob")

      textField.text? += ", Jr."
      XCTAssertEqual(text, "Blob, Jr.")
      XCTAssertEqual(textField.text, "Blob, Jr.")
    }

    @MainActor
    func testReBindControl() async throws {
      @UIBinding var text = ""
      let textField = UITextField(text: $text)

      @UIBinding var otherText = "Blob"
      textField.bind(text: $otherText)
      XCTAssertEqual(textField.text, "Blob")

      otherText += " Jr"
      await Task.yield()
      XCTAssertEqual(textField.text, "Blob Jr")

      text += "!!!"
      await Task.yield()
      XCTAssertEqual(textField.text, "Blob Jr")

      textField.text? += ", Esq."
      XCTAssertEqual(text, "!!!")
      XCTAssertEqual(otherText, "Blob Jr, Esq.")
    }

    @MainActor
    func testUnbind() async throws {
      @UIBinding var text = ""
      let textField = UITextField(text: $text)
      XCTAssertEqual(text, "")
      XCTAssertEqual(textField.text, "")

      text += "Blob"
      await Task.yield()
      XCTAssertEqual(text, "Blob")
      XCTAssertEqual(textField.text, "Blob")

      textField.unbind(\.text)

      text += "!"
      XCTAssertEqual(text, "Blob!")
      XCTAssertEqual(textField.text, "Blob")

      textField.text? += ", Esq."
      XCTAssertEqual(text, "Blob!")
      XCTAssertEqual(textField.text, "Blob, Esq.")
    }

    @MainActor
    func testDeinitIsolation() async {
      await Task.detached {
        @UIBinding var text = ""
        let textField = await UITextField(text: $text)
        _ = textField
      }
      .value
    }
  }
#endif
