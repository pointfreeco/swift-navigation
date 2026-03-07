import CustomDump
import Foundation

#if canImport(SwiftUI)
  import SwiftUI
#endif

/// An equatable description of SwiftUI `Text`. Useful for storing rich text in feature models
/// that can still be tested for equality.
///
/// Although `SwiftUI.Text` and `SwiftUI.LocalizedStringKey` are value types that conform to
/// `Equatable`, their `==` do not return `true` when used with seemingly equal values. If we were
/// to naively store these values in state, our tests may begin to fail.
///
/// ``TextState`` solves this problem by providing an interface similar to `SwiftUI.Text` that can
/// be held in state and asserted against.
///
/// Let's say you wanted to hold some dynamic, styled text content in your app state. You could use
/// ``TextState``:
///
/// ```swift
/// @Observable
/// class Model {
///   var label = TextState("")
/// }
/// ```
///
/// Your model can then assign a value to this state using an API similar to that of `SwiftUI.Text`.
///
/// ```swift
/// self.label = TextState("Hello, ") + TextState(name).bold() + TextState("!")
/// ```
///
/// And your view can render it by passing it to a `SwiftUI.Text` initializer:
///
/// ```swift
/// var body: some View {
///   Text(self.model.label)
/// }
/// ```
///
/// SwiftUI Navigation comes with a few convenience APIs for alerts and dialogs that wrap
/// ``TextState`` under the hood. See ``AlertState`` and ``ConfirmationDialogState`` accordingly.
///
/// In the future, should `SwiftUI.Text` and `SwiftUI.LocalizedStringKey` reliably conform to
/// `Equatable`, ``TextState`` may be deprecated.
///
/// - Note: ``TextState`` does not support _all_ `LocalizedStringKey` permutations at this time
///   (interpolated `SwiftUI.Image`s, for example). ``TextState`` also uses reflection to determine
///   `LocalizedStringKey` equatability, so be mindful of edge cases.
public struct TextState: Equatable, Hashable, Sendable {
  fileprivate let storage: Storage

  #if canImport(SwiftUI)
    fileprivate var modifiers: [Modifier] = []

    fileprivate enum Modifier: Equatable, Hashable, Sendable {
      case accessibilityHeading(AccessibilityHeadingLevel)
      case accessibilityLabel(TextState)
      case accessibilityTextContentType(AccessibilityTextContentType)
      case baselineOffset(CGFloat)
      case bold(isActive: Bool)
      case font(Font?)
      case fontDesign(Font.Design?)
      case fontWeight(Font.Weight?)
      case fontWidth(FontWidth?)
      case foregroundColor(Color?)
      case italic(isActive: Bool)
      case kerning(CGFloat)
      case monospacedDigit
      case speechAdjustedPitch(Double)
      case speechAlwaysIncludesPunctuation(Bool)
      case speechAnnouncementsQueued(Bool)
      case speechSpellsOutCharacters(Bool)
      case strikethrough(isActive: Bool, pattern: LineStylePattern?, color: Color?)
      case tracking(CGFloat)
      case underline(isActive: Bool, pattern: LineStylePattern?, color: Color?)
    }

    public enum FontWidth: String, Equatable, Hashable, Sendable {
      case compressed
      case condensed
      case expanded
      case standard

      @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
      var toSwiftUI: SwiftUI.Font.Width {
        switch self {
        case .compressed: return .compressed
        case .condensed: return .condensed
        case .expanded: return .expanded
        case .standard: return .standard
        }
      }
    }

    public enum LineStylePattern: String, Equatable, Hashable, Sendable {
      case dash
      case dashDot
      case dashDotDot
      case dot
      case solid

      @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
      var toSwiftUI: SwiftUI.Text.LineStyle.Pattern {
        switch self {
        case .dash: return .dash
        case .dashDot: return .dashDot
        case .dashDotDot: return .dashDotDot
        case .dot: return .dot
        case .solid: return .solid
        }
      }
    }
  #endif

  // NB: LocalizedStringKey is documented as being Sendable, but its conformance appears to be
  //     unavailable.
  fileprivate enum Storage: Equatable, Hashable, @unchecked Sendable {
    indirect case concatenated(TextState, TextState)
    #if canImport(SwiftUI)
      case localizedStringKey(
        LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: StaticString?
      )
    #endif
    #if canImport(Darwin)
      case localizedStringResource(LocalizedStringResourceBox)
    #endif
    case verbatim(String)

    static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.concatenated(let l1, let l2), .concatenated(let r1, let r2)):
        return l1 == r1 && l2 == r2
      #if canImport(Darwin)
        case (.concatenated, .localizedStringResource),
          (.localizedStringResource, .concatenated):
          // NB: We do not attempt to equate concatenated cases.
          return false
      #endif
      case (.concatenated, .verbatim),
        (.verbatim, .concatenated):
        // NB: We do not attempt to equate concatenated cases.
        return false
      case (.verbatim(let lhs), .verbatim(let rhs)):
        return lhs == rhs

      #if canImport(Darwin)
        case (.verbatim(let string), .localizedStringResource(let resource)),
          (.localizedStringResource(let resource), .verbatim(let string)):
          return string == resource.asString()

        case (.localizedStringResource(let lhs), .localizedStringResource(let rhs)):
          return lhs.asString() == rhs.asString()
      #endif

      #if canImport(SwiftUI)
        case (.concatenated, .localizedStringKey),
          (.localizedStringKey, .concatenated):
          // NB: We do not attempt to equate concatenated cases.
          return false
        case (
          .verbatim(let string), .localizedStringKey(let key, let table, let bundle, let comment)
        ),
          (.localizedStringKey(let key, let table, let bundle, let comment), .verbatim(let string)):
          return string == key.formatted(tableName: table, bundle: bundle, comment: comment)

        case (
          .localizedStringKey(let lk, let lt, let lb, let lc),
          .localizedStringKey(let rk, let rt, let rb, let rc)
        ):
          return lk.formatted(tableName: lt, bundle: lb, comment: lc)
            == rk.formatted(tableName: rt, bundle: rb, comment: rc)

        case (
          .localizedStringKey(let key, let table, let bundle, let comment),
          .localizedStringResource(let resource)
        ),
          (
            .localizedStringResource(let resource),
            .localizedStringKey(let key, let table, let bundle, let comment)
          ):
          return key.formatted(tableName: table, bundle: bundle, comment: comment)
            == resource.asString()

      #endif
      }
    }

    func hash(into hasher: inout Hasher) {
      switch self {
      case (.concatenated(let first, let second)):
        hasher.combine(first)
        hasher.combine(second)

      #if canImport(SwiftUI)
        case .localizedStringKey(let key, let tableName, let bundle, let comment):
          hasher.combine(key.formatted(tableName: tableName, bundle: bundle, comment: comment))
      #endif

      #if canImport(Darwin)
        case .localizedStringResource(let resource):
          hasher.combine(resource.asString())
      #endif

      case .verbatim(let string):
        hasher.combine(string)
      }
    }
  }
}

// MARK: - LocalizedStringResourceBox

#if canImport(Darwin)
  private struct LocalizedStringResourceBox: @unchecked Sendable {
    // REVISIT: Make 'Any' into 'any Sendable' when minimum deployment target is iOS 18
    let value: Any

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    init(_ resource: LocalizedStringResource) {
      self.value = resource
    }

    func asText() -> Text {
      guard
        #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *),
        let resource = value as? LocalizedStringResource
      else {
        preconditionFailure(
          "LocalizedStringResourceBox should only be exposed where LocalizedStringResource is available."
        )
      }

      return Text(resource)
    }

    func asString() -> String {
      guard
        #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *),
        let resource = value as? LocalizedStringResource
      else {
        preconditionFailure(
          "LocalizedStringResourceBox should only be exposed where LocalizedStringResource is available."
        )
      }

      return String(localized: resource)
    }
  }
#endif

// MARK: - API

extension TextState {
  public init(verbatim content: String) {
    self.storage = .verbatim(content)
  }

  @_disfavoredOverload
  public init<S: StringProtocol>(_ content: S) {
    self.init(verbatim: String(content))
  }

  #if canImport(SwiftUI)
    public init(
      _ key: LocalizedStringKey,
      tableName: String? = nil,
      bundle: Bundle? = nil,
      comment: StaticString? = nil
    ) {
      self.storage = .localizedStringKey(
        key,
        tableName: tableName,
        bundle: bundle,
        comment: comment
      )
    }
  #endif

  #if canImport(Darwin)
    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public init(
      _ resource: LocalizedStringResource
    ) {
      self.storage = .localizedStringResource(
        LocalizedStringResourceBox(resource)
      )
    }
  #endif

  public static func + (lhs: Self, rhs: Self) -> Self {
    .init(storage: .concatenated(lhs, rhs))
  }

  #if canImport(SwiftUI)
    public func baselineOffset(_ baselineOffset: CGFloat) -> Self {
      var `self` = self
      `self`.modifiers.append(.baselineOffset(baselineOffset))
      return `self`
    }

    public func bold() -> Self {
      var `self` = self
      `self`.modifiers.append(.bold(isActive: true))
      return `self`
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func bold(isActive: Bool) -> Self {
      var `self` = self
      `self`.modifiers.append(.bold(isActive: isActive))
      return `self`
    }

    public func font(_ font: Font?) -> Self {
      var `self` = self
      `self`.modifiers.append(.font(font))
      return `self`
    }

    public func fontDesign(_ design: Font.Design?) -> Self {
      var `self` = self
      `self`.modifiers.append(.fontDesign(design))
      return `self`
    }

    public func fontWeight(_ weight: Font.Weight?) -> Self {
      var `self` = self
      `self`.modifiers.append(.fontWeight(weight))
      return `self`
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func fontWidth(_ width: FontWidth?) -> Self {
      var `self` = self
      `self`.modifiers.append(.fontWidth(width))
      return `self`
    }

    public func foregroundColor(_ color: Color?) -> Self {
      var `self` = self
      `self`.modifiers.append(.foregroundColor(color))
      return `self`
    }

    public func italic() -> Self {
      var `self` = self
      `self`.modifiers.append(.italic(isActive: true))
      return `self`
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func italic(isActive: Bool) -> Self {
      var `self` = self
      `self`.modifiers.append(.italic(isActive: isActive))
      return `self`
    }

    public func kerning(_ kerning: CGFloat) -> Self {
      var `self` = self
      `self`.modifiers.append(.kerning(kerning))
      return `self`
    }

    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func monospacedDigit() -> Self {
      var `self` = self
      `self`.modifiers.append(.monospacedDigit)
      return `self`
    }

    public func strikethrough(_ isActive: Bool = true, color: Color? = nil) -> Self {
      var `self` = self
      `self`.modifiers.append(.strikethrough(isActive: isActive, pattern: .solid, color: color))
      return `self`
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func strikethrough(
      _ isActive: Bool = true,
      pattern: LineStylePattern,
      color: Color? = nil
    ) -> Self {
      var `self` = self
      `self`.modifiers.append(.strikethrough(isActive: isActive, pattern: pattern, color: color))
      return `self`
    }

    public func tracking(_ tracking: CGFloat) -> Self {
      var `self` = self
      `self`.modifiers.append(.tracking(tracking))
      return `self`
    }

    public func underline(_ isActive: Bool = true, color: Color? = nil) -> Self {
      var `self` = self
      `self`.modifiers.append(.underline(isActive: isActive, pattern: .solid, color: color))
      return `self`
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func underline(
      _ isActive: Bool = true,
      pattern: LineStylePattern,
      color: Color? = nil
    ) -> Self {
      var `self` = self
      `self`.modifiers.append(.underline(isActive: isActive, pattern: pattern, color: color))
      return `self`
    }
  #endif
}

// MARK: Accessibility

#if canImport(SwiftUI)
  extension TextState {
    public enum AccessibilityTextContentType: String, Equatable, Hashable, Sendable {
      case console, fileSystem, messaging, narrative, plain, sourceCode, spreadsheet, wordProcessing

      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      var toSwiftUI: SwiftUI.AccessibilityTextContentType {
        switch self {
        case .console: return .console
        case .fileSystem: return .fileSystem
        case .messaging: return .messaging
        case .narrative: return .narrative
        case .plain: return .plain
        case .sourceCode: return .sourceCode
        case .spreadsheet: return .spreadsheet
        case .wordProcessing: return .wordProcessing
        }
      }
    }

    public enum AccessibilityHeadingLevel: String, Equatable, Hashable, Sendable {
      case h1, h2, h3, h4, h5, h6, unspecified

      @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
      var toSwiftUI: SwiftUI.AccessibilityHeadingLevel {
        switch self {
        case .h1: return .h1
        case .h2: return .h2
        case .h3: return .h3
        case .h4: return .h4
        case .h5: return .h5
        case .h6: return .h6
        case .unspecified: return .unspecified
        }
      }
    }
  }

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension TextState {
    public func accessibilityHeading(_ headingLevel: AccessibilityHeadingLevel) -> Self {
      var `self` = self
      `self`.modifiers.append(.accessibilityHeading(headingLevel))
      return `self`
    }

    public func accessibilityLabel(_ label: Self) -> Self {
      var `self` = self
      `self`.modifiers.append(.accessibilityLabel(label))
      return `self`
    }

    public func accessibilityLabel(_ string: String) -> Self {
      var `self` = self
      `self`.modifiers.append(.accessibilityLabel(.init(string)))
      return `self`
    }

    public func accessibilityLabel<S: StringProtocol>(_ string: S) -> Self {
      var `self` = self
      `self`.modifiers.append(.accessibilityLabel(.init(string)))
      return `self`
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func accessibilityLabel(
      _ resource: LocalizedStringResource
    ) -> Self {
      var `self` = self
      `self`.modifiers.append(
        .accessibilityLabel(.init(verbatim: String(localized: resource)))
      )
      return `self`
    }

    public func accessibilityLabel(
      _ key: LocalizedStringKey,
      tableName: String? = nil,
      bundle: Bundle? = nil,
      comment: StaticString? = nil
    ) -> Self {
      var `self` = self
      `self`.modifiers.append(
        .accessibilityLabel(.init(key, tableName: tableName, bundle: bundle, comment: comment))
      )
      return `self`
    }

    public var accessibilityLabel: TextState? {
      for modifier in self.modifiers.reversed() {
        if case .accessibilityLabel(let accessibilityLabel) = modifier {
          return accessibilityLabel
        }
      }
      return nil
    }

    public func accessibilityTextContentType(_ type: AccessibilityTextContentType) -> Self {
      var `self` = self
      `self`.modifiers.append(.accessibilityTextContentType(type))
      return `self`
    }

    public func speechAdjustedPitch(_ value: Double) -> Self {
      var `self` = self
      `self`.modifiers.append(.speechAdjustedPitch(value))
      return `self`
    }

    public func speechAlwaysIncludesPunctuation(_ value: Bool = true) -> Self {
      var `self` = self
      `self`.modifiers.append(.speechAlwaysIncludesPunctuation(value))
      return `self`
    }

    public func speechAnnouncementsQueued(_ value: Bool = true) -> Self {
      var `self` = self
      `self`.modifiers.append(.speechAnnouncementsQueued(value))
      return `self`
    }

    public func speechSpellsOutCharacters(_ value: Bool = true) -> Self {
      var `self` = self
      `self`.modifiers.append(.speechSpellsOutCharacters(value))
      return `self`
    }
  }

  extension Text {
    public init(_ state: TextState) {
      let text: Text
      switch state.storage {
      case .concatenated(let first, let second):
        text = Text(first) + Text(second)
      case .localizedStringKey(let content, let tableName, let bundle, let comment):
        text = .init(content, tableName: tableName, bundle: bundle, comment: comment)
      case .localizedStringResource(let resourceBox):
        text = resourceBox.asText()
      case .verbatim(let content):
        text = .init(verbatim: content)
      }
      self = state.modifiers.reduce(text) { text, modifier in
        switch modifier {
        case .accessibilityHeading(let level):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.accessibilityHeading(level.toSwiftUI)
          } else {
            return text
          }
        case .accessibilityLabel(let value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
          switch value.storage {
          case .verbatim(let string):
            return text.accessibilityLabel(string)
          case .localizedStringKey(let key, let tableName, let bundle, let comment):
            return text.accessibilityLabel(
              Text(key, tableName: tableName, bundle: bundle, comment: comment)
            )
          case .localizedStringResource(let resourceBox):
            return text.accessibilityLabel(
              resourceBox.asText()
            )
          case .concatenated(_, _):
            assertionFailure("`.accessibilityLabel` does not support concatenated `TextState`")
              return text
            }
          } else {
            return text
          }
        case .accessibilityTextContentType(let type):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.accessibilityTextContentType(type.toSwiftUI)
          } else {
            return text
          }
        case .baselineOffset(let baselineOffset):
          return text.baselineOffset(baselineOffset)
        case .bold(let isActive):
          if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            return text.bold(isActive)
          } else {
            return text.bold()
          }
        case .font(let font):
          return text.font(font)
        case .fontDesign(let design):
          if #available(iOS 16.1, macOS 13, tvOS 16.1, watchOS 9.1, *) {
            return text.fontDesign(design)
          } else {
            return text
          }
        case .fontWeight(let weight):
          return text.fontWeight(weight)
        case .fontWidth(let width):
          if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            return text.fontWidth(width?.toSwiftUI)
          } else {
            return text
          }
        case .foregroundColor(let color):
          return text.foregroundColor(color)
        case .italic(let isActive):
          if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            return text.italic(isActive)
          } else {
            return text.italic()
          }
        case .kerning(let kerning):
          return text.kerning(kerning)
        case .monospacedDigit:
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.monospacedDigit()
          } else {
            return text
          }
        case .speechAdjustedPitch(let value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechAdjustedPitch(value)
          } else {
            return text
          }
        case .speechAlwaysIncludesPunctuation(let value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechAlwaysIncludesPunctuation(value)
          } else {
            return text
          }
        case .speechAnnouncementsQueued(let value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechAnnouncementsQueued(value)
          } else {
            return text
          }
        case .speechSpellsOutCharacters(let value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechSpellsOutCharacters(value)
          } else {
            return text
          }
        case .strikethrough(let isActive, let pattern, let color):
          if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *), let pattern = pattern {
            return text.strikethrough(isActive, pattern: pattern.toSwiftUI, color: color)
          } else {
            return text.strikethrough(isActive, color: color)
          }
        case .tracking(let tracking):
          return text.tracking(tracking)
        case .underline(let isActive, let pattern, let color):
          if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *), let pattern = pattern {
            return text.underline(isActive, pattern: pattern.toSwiftUI, color: color)
          } else {
            return text.underline(isActive, color: color)
          }
        }
      }
    }
  }
#endif

extension String {
  public init(state: TextState, locale: Locale? = nil) {
    switch state.storage {
    case .concatenated(let lhs, let rhs):
      self = String(state: lhs, locale: locale) + String(state: rhs, locale: locale)

    #if canImport(SwiftUI)
      case .localizedStringKey(let key, let tableName, let bundle, let comment):
        self = key.formatted(
          locale: locale,
          tableName: tableName,
          bundle: bundle,
          comment: comment
        )
    #endif

    #if canImport(Darwin)
      case .localizedStringResource(let resourceBox):
        self = resourceBox.asString()
    #endif

    case .verbatim(let string):
      self = string
    }
  }
}

#if canImport(SwiftUI)
  extension LocalizedStringKey {
    // NB: `LocalizedStringKey` conforms to `Equatable` but returns false for equivalent format
    //     strings. To account for this we reflect on it to extract and string-format its storage.
    fileprivate func formatted(
      locale: Locale? = nil,
      tableName: String? = nil,
      bundle: Bundle? = nil,
      comment: StaticString? = nil
    ) -> String {
      let children = Array(Mirror(reflecting: self).children)
      let key = children[0].value as! String
      let arguments: [CVarArg] = Array(Mirror(reflecting: children[2].value).children)
        .compactMap {
          let children = Array(Mirror(reflecting: $0.value).children)
          let value: Any
          let formatter: Formatter?
          // `LocalizedStringKey.FormatArgument` differs depending on OS/platform.
          if children[0].label == "storage" {
            (value, formatter) =
              Array(Mirror(reflecting: children[0].value).children)[0].value as! (Any, Formatter?)
          } else {
            value = children[0].value
            formatter = children[1].value as? Formatter
          }
          return formatter?.string(for: value) ?? value as! CVarArg
        }

      let format = NSLocalizedString(
        key,
        tableName: tableName,
        bundle: bundle ?? .main,
        value: "",
        comment: comment.map(String.init) ?? ""
      )
      return String(format: format, locale: locale, arguments: arguments)
    }
  }
#endif

// MARK: - CustomDumpRepresentable

extension TextState: CustomDumpRepresentable {
  public var customDumpValue: Any {
    func dumpHelp(_ textState: Self) -> String {
      var output: String
      switch textState.storage {
      case .concatenated(let lhs, let rhs):
        output = dumpHelp(lhs) + dumpHelp(rhs)
      #if canImport(SwiftUI)
        case .localizedStringKey(let key, let tableName, let bundle, let comment):
          output = key.formatted(tableName: tableName, bundle: bundle, comment: comment)
      #endif
      #if canImport(Darwin)
        case .localizedStringResource(let resourceBox):
          output = resourceBox.asString()
      #endif

      case .verbatim(let string):
        output = string
      }
      func tag(_ name: String, attribute: String? = nil, _ value: String? = nil) {
        output = """
          <\(name)\(attribute.map { " \($0)" } ?? "")\(value.map { "=\($0)" } ?? "")>\
          \(output)\
          </\(name)>
          """
      }
      #if canImport(SwiftUI)
        for modifier in textState.modifiers {
          switch modifier {
          case .accessibilityHeading(let headingLevel):
            tag("accessibility-heading-level", headingLevel.rawValue)
          case .accessibilityLabel(let value):
            tag("accessibility-label", dumpHelp(value))
          case .accessibilityTextContentType(let type):
            tag("accessibility-text-content-type", type.rawValue)
          case .baselineOffset(let baselineOffset):
            tag("baseline-offset", "\(baselineOffset)")
          case .bold(isActive: true), .fontWeight(.some(.bold)):
            output = "**\(output)**"
          case .font(.some):
            break  // TODO: capture Font description using DSL similar to TextState and print here
          case .fontDesign(.some(let design)):
            func describe(design: Font.Design) -> String {
              switch design {
              case .default: return "default"
              case .serif: return "serif"
              case .rounded: return "rounded"
              case .monospaced: return "monospaced"
              @unknown default: return "\(design)"
              }
            }
            tag("font-design", describe(design: design))
          case .fontWeight(.some(let weight)):
            func describe(weight: Font.Weight) -> String {
              switch weight {
              case .black: return "black"
              case .bold: return "bold"
              case .heavy: return "heavy"
              case .light: return "light"
              case .medium: return "medium"
              case .regular: return "regular"
              case .semibold: return "semibold"
              case .thin: return "thin"
              default: return "\(weight)"
              }
            }
            tag("font-weight", describe(weight: weight))
          case .fontWidth(.some(let width)):
            tag("font-width", width.rawValue)
          case .foregroundColor(.some(let color)):
            tag("foreground-color", "\(color)")
          case .italic(isActive: true):
            output = "_\(output)_"
          case .kerning(let kerning):
            tag("kerning", "\(kerning)")
          case .speechAdjustedPitch(let value):
            tag("speech-adjusted-pitch", "\(value)")
          case .speechAlwaysIncludesPunctuation(true):
            tag("speech-always-includes-punctuation")
          case .speechAnnouncementsQueued(true):
            tag("speech-announcements-queued")
          case .speechSpellsOutCharacters(true):
            tag("speech-spells-out-characters")
          case .strikethrough(isActive: true, pattern: _, color: .some(let color)):
            tag("s", attribute: "color", "\(color)")
          case .strikethrough(isActive: true, pattern: _, color: .none):
            output = "~~\(output)~~"
          case .tracking(let tracking):
            tag("tracking", "\(tracking)")
          case .underline(isActive: true, pattern: _, .some(let color)):
            tag("u", attribute: "color", "\(color)")
          case .underline(isActive: true, pattern: _, color: .none):
            tag("u")
          case .bold(isActive: false),
            .font(.none),
            .fontDesign(.none),
            .fontWeight(.none),
            .fontWidth(.none),
            .foregroundColor(.none),
            .italic(isActive: false),
            .monospacedDigit,
            .speechAlwaysIncludesPunctuation(false),
            .speechAnnouncementsQueued(false),
            .speechSpellsOutCharacters(false),
            .strikethrough(isActive: false, pattern: _, color: _),
            .underline(isActive: false, pattern: _, color: _):
            break
          }
        }
      #endif
      return output
    }

    return dumpHelp(self)
  }
}
