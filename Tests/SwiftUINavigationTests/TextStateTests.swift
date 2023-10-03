#if canImport(SwiftUI)
  import CustomDump
  import SwiftUINavigation
  import XCTest

  final class TextStateTests: XCTestCase {
    func testTextState() {
      var dump = ""
      customDump(TextState("Hello, world!"), to: &dump)
      XCTAssertEqual(
        dump,
        """
        "Hello, world!"
        """
      )

      dump = ""
      customDump(
        TextState("Hello, ")
          + TextState("world").bold().italic()
          + TextState("!"),
        to: &dump
      )
      XCTAssertEqual(
        dump,
        """
        "Hello, _**world**_!"
        """
      )

      dump = ""
      customDump(
        TextState("Offset by 10.5").baselineOffset(10.5)
          + TextState("\n") + TextState("Headline").font(.headline)
          + TextState("\n") + TextState("No font").font(nil)
          + TextState("\n") + TextState("Light font weight").fontWeight(.light)
          + TextState("\n") + TextState("No font weight").fontWeight(nil)
          + TextState("\n") + TextState("Red").foregroundColor(.red)
          + TextState("\n") + TextState("No color").foregroundColor(nil)
          + TextState("\n") + TextState("Italic").italic()
          + TextState("\n") + TextState("Kerning of 2.5").kerning(2.5)
          + TextState("\n") + TextState("Stricken").strikethrough()
          + TextState("\n") + TextState("Stricken green").strikethrough(color: .green)
          + TextState("\n") + TextState("Not stricken blue").strikethrough(false, color: .blue)
          + TextState("\n") + TextState("Tracking of 5.5").tracking(5.5)
          + TextState("\n") + TextState("Underlined").underline()
          + TextState("\n") + TextState("Underlined pink").underline(color: .pink)
          + TextState("\n") + TextState("Not underlined purple").underline(false, color: .pink),
        to: &dump
      )
      XCTAssertNoDifference(
        dump,
        #"""
        """
        <baseline-offset=10.5>Offset by 10.5</baseline-offset>
        Headline
        No font
        <font-weight=light>Light font weight</font-weight>
        No font weight
        <foreground-color=red>Red</foreground-color>
        No color
        _Italic_
        <kerning=2.5>Kerning of 2.5</kerning>
        ~~Stricken~~
        <s color=green>Stricken green</s>
        Not stricken blue
        <tracking=5.5>Tracking of 5.5</tracking>
        <u>Underlined</u>
        <u color=pink>Underlined pink</u>
        Not underlined purple
        """
        """#
      )
    }
  }
#endif  // canImport(SwiftUI)
