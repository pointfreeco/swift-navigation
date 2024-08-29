import CustomDump
import SwiftNavigation
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

    var textState = TextState("Offset by 10.5").baselineOffset(10.5)
    textState = textState + TextState("\n")
    textState = textState + TextState("Headline").font(.headline)
    textState = textState + TextState("\n")
    textState = textState + TextState("No font").font(nil)
    textState = textState + TextState("\n")
    textState = textState + TextState("Light font weight").fontWeight(.light)
    textState = textState + TextState("\n")
    textState = textState + TextState("No font weight").fontWeight(nil)
    textState = textState + TextState("\n")
    textState = textState + TextState("Red").foregroundColor(.red)
    textState = textState + TextState("\n")
    textState = textState + TextState("No color").foregroundColor(nil)
    textState = textState + TextState("\n")
    textState = textState + TextState("Italic").italic()
    textState = textState + TextState("\n")
    textState = textState + TextState("Kerning of 2.5").kerning(2.5)
    textState = textState + TextState("\n")
    textState = textState + TextState("Stricken").strikethrough()
    textState = textState + TextState("\n")
    textState = textState + TextState("Stricken green").strikethrough(color: .green)
    textState = textState + TextState("\n")
    textState = textState + TextState("Not stricken blue").strikethrough(false, color: .blue)
    textState = textState + TextState("\n")
    textState = textState + TextState("Tracking of 5.5").tracking(5.5)
    textState = textState + TextState("\n")
    textState = textState + TextState("Underlined").underline()
    textState = textState + TextState("\n")
    textState = textState + TextState("Underlined pink").underline(color: .pink)
    textState = textState + TextState("\n")
    textState = textState + TextState("Not underlined purple").underline(false, color: .pink)
    dump = ""
    customDump(textState, to: &dump)
    expectNoDifference(
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
