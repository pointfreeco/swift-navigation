#if canImport(SwiftUI)
  import CustomDump
  import SwiftUI

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
    fileprivate var modifiers: [Modifier] = []
    fileprivate let storage: Storage

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

      #if swift(>=5.7.1)
        @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
        var toSwiftUI: SwiftUI.Font.Width {
          switch self {
          case .compressed: return .compressed
          case .condensed: return .condensed
          case .expanded: return .expanded
          case .standard: return .standard
          }
        }
      #endif
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

    // NB: LocalizedStringKey is documented as being Sendable, but its conformance appears to be
    //     unavailable.
    fileprivate enum Storage: Equatable, Hashable, @unchecked Sendable {
      indirect case concatenated(TextState, TextState)
      case localized(
        LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: StaticString?)
      case verbatim(String)

      static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.concatenated(l1, l2), .concatenated(r1, r2)):
          return l1 == r1 && l2 == r2

        case let (.localized(lk, lt, lb, lc), .localized(rk, rt, rb, rc)):
          return lk.formatted(tableName: lt, bundle: lb, comment: lc)
            == rk.formatted(tableName: rt, bundle: rb, comment: rc)

        case let (.verbatim(lhs), .verbatim(rhs)):
          return lhs == rhs

        case let (.localized(key, tableName, bundle, comment), .verbatim(string)),
          let (.verbatim(string), .localized(key, tableName, bundle, comment)):
          return key.formatted(tableName: tableName, bundle: bundle, comment: comment) == string

        // NB: We do not attempt to equate concatenated cases.
        default:
          return false
        }
      }

      func hash(into hasher: inout Hasher) {
        enum Key {
          case concatenated
          case localized
          case verbatim
        }

        switch self {
        case let (.concatenated(first, second)):
          hasher.combine(Key.concatenated)
          hasher.combine(first)
          hasher.combine(second)

        case let .localized(key, tableName, bundle, comment):
          hasher.combine(Key.localized)
          hasher.combine(key.formatted(tableName: tableName, bundle: bundle, comment: comment))

        case let .verbatim(string):
          hasher.combine(Key.verbatim)
          hasher.combine(string)
        }
      }
    }
  }

  // MARK: - API

  extension TextState {
    public init(verbatim content: String) {
      self.storage = .verbatim(content)
    }

    @_disfavoredOverload
    public init<S: StringProtocol>(_ content: S) {
      self.init(verbatim: String(content))
    }

    public init(
      _ key: LocalizedStringKey,
      tableName: String? = nil,
      bundle: Bundle? = nil,
      comment: StaticString? = nil
    ) {
      self.storage = .localized(key, tableName: tableName, bundle: bundle, comment: comment)
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
      .init(storage: .concatenated(lhs, rhs))
    }

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
  }

  // MARK: Accessibility

  extension TextState {
    public enum AccessibilityTextContentType: String, Equatable, Hashable, Sendable {
      case console, fileSystem, messaging, narrative, plain, sourceCode, spreadsheet, wordProcessing

      #if compiler(>=5.5.1)
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
      #endif
    }

    public enum AccessibilityHeadingLevel: String, Equatable, Hashable, Sendable {
      case h1, h2, h3, h4, h5, h6, unspecified

      #if compiler(>=5.5.1)
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
      #endif
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

    public func accessibilityLabel(
      _ key: LocalizedStringKey, tableName: String? = nil, bundle: Bundle? = nil,
      comment: StaticString? = nil
    ) -> Self {
      var `self` = self
      `self`.modifiers.append(
        .accessibilityLabel(.init(key, tableName: tableName, bundle: bundle, comment: comment)))
      return `self`
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
      case let .concatenated(first, second):
        text = Text(first) + Text(second)
      case let .localized(content, tableName, bundle, comment):
        text = .init(content, tableName: tableName, bundle: bundle, comment: comment)
      case let .verbatim(content):
        text = .init(verbatim: content)
      }
      self = state.modifiers.reduce(text) { text, modifier in
        switch modifier {
        #if compiler(>=5.5.1)
          case let .accessibilityHeading(level):
            if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
              return text.accessibilityHeading(level.toSwiftUI)
            } else {
              return text
            }
          case let .accessibilityLabel(value):
            if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
              switch value.storage {
              case let .verbatim(string):
                return text.accessibilityLabel(string)
              case let .localized(key, tableName, bundle, comment):
                return text.accessibilityLabel(
                  Text(key, tableName: tableName, bundle: bundle, comment: comment))
              case .concatenated(_, _):
                assertionFailure("`.accessibilityLabel` does not support concatenated `TextState`")
                return text
              }
            } else {
              return text
            }
          case let .accessibilityTextContentType(type):
            if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
              return text.accessibilityTextContentType(type.toSwiftUI)
            } else {
              return text
            }
        #else
          case .accessibilityHeading,
            .accessibilityLabel,
            .accessibilityTextContentType:
            return text
        #endif
        case let .baselineOffset(baselineOffset):
          return text.baselineOffset(baselineOffset)
        case let .bold(isActive):
          #if swift(>=5.7.1)
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
              return text.bold(isActive)
            } else {
              return text.bold()
            }
          #else
            _ = isActive
            return text.bold()
          #endif
        case let .font(font):
          return text.font(font)
        case let .fontDesign(design):
          #if swift(>=5.7.1)
            if #available(iOS 16.1, macOS 13, tvOS 16.1, watchOS 9.1, *) {
              return text.fontDesign(design)
            } else {
              return text
            }
          #else
            _ = design
            return text
          #endif
        case let .fontWeight(weight):
          return text.fontWeight(weight)
        case let .fontWidth(width):
          #if swift(>=5.7.1)
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
              return text.fontWidth(width?.toSwiftUI)
            } else {
              return text
            }
          #else
            _ = width
            return text
          #endif
        case let .foregroundColor(color):
          return text.foregroundColor(color)
        case let .italic(isActive):
          #if swift(>=5.7.1)
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
              return text.italic(isActive)
            } else {
              return text.italic()
            }
          #else
            _ = isActive
            return text.italic()
          #endif
        case let .kerning(kerning):
          return text.kerning(kerning)
        case .monospacedDigit:
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.monospacedDigit()
          } else {
            return text
          }
        case let .speechAdjustedPitch(value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechAdjustedPitch(value)
          } else {
            return text
          }
        case let .speechAlwaysIncludesPunctuation(value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechAlwaysIncludesPunctuation(value)
          } else {
            return text
          }
        case let .speechAnnouncementsQueued(value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechAnnouncementsQueued(value)
          } else {
            return text
          }
        case let .speechSpellsOutCharacters(value):
          if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return text.speechSpellsOutCharacters(value)
          } else {
            return text
          }
        case let .strikethrough(isActive, pattern, color):
          #if swift(>=5.7.1)
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *), let pattern = pattern {
              return text.strikethrough(isActive, pattern: pattern.toSwiftUI, color: color)
            } else {
              return text.strikethrough(isActive, color: color)
            }
          #else
            _ = pattern
            return text.strikethrough(isActive, color: color)
          #endif
        case let .tracking(tracking):
          return text.tracking(tracking)
        case let .underline(isActive, pattern, color):
          #if swift(>=5.7.1)
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *), let pattern = pattern {
              return text.underline(isActive, pattern: pattern.toSwiftUI, color: color)
            } else {
              return text.underline(isActive, color: color)
            }
          #else
            _ = pattern
            return text.strikethrough(isActive, color: color)
          #endif
        }
      }
    }
  }

  extension String {
    public init(state: TextState, locale: Locale? = nil) {
      switch state.storage {
      case let .concatenated(lhs, rhs):
        self = String(state: lhs, locale: locale) + String(state: rhs, locale: locale)

      case let .localized(key, tableName, bundle, comment):
        self = key.formatted(
          locale: locale,
          tableName: tableName,
          bundle: bundle,
          comment: comment
        )

      case let .verbatim(string):
        self = string
      }
    }
  }

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

  // MARK: - CustomDumpRepresentable

  extension TextState: CustomDumpRepresentable {
    public var customDumpValue: Any {
      func dumpHelp(_ textState: Self) -> String {
        var output: String
        switch textState.storage {
        case let .concatenated(lhs, rhs):
          output = dumpHelp(lhs) + dumpHelp(rhs)
        case let .localized(key, tableName, bundle, comment):
          output = key.formatted(tableName: tableName, bundle: bundle, comment: comment)
        case let .verbatim(string):
          output = string
        }
        func tag(_ name: String, attribute: String? = nil, _ value: String? = nil) {
          output = """
            <\(name)\(attribute.map { " \($0)" } ?? "")\(value.map { "=\($0)" } ?? "")>\
            \(output)\
            </\(name)>
            """
        }
        for modifier in textState.modifiers {
          switch modifier {
          case let .accessibilityHeading(headingLevel):
            tag("accessibility-heading-level", headingLevel.rawValue)
          case let .accessibilityLabel(value):
            tag("accessibility-label", dumpHelp(value))
          case let .accessibilityTextContentType(type):
            tag("accessibility-text-content-type", type.rawValue)
          case let .baselineOffset(baselineOffset):
            tag("baseline-offset", "\(baselineOffset)")
          case .bold(isActive: true), .fontWeight(.some(.bold)):
            output = "**\(output)**"
          case .font(.some):
            break  // TODO: capture Font description using DSL similar to TextState and print here
          case let .fontDesign(.some(design)):
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
          case let .fontWeight(.some(weight)):
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
          case let .fontWidth(.some(width)):
            tag("font-width", width.rawValue)
          case let .foregroundColor(.some(color)):
            tag("foreground-color", "\(color)")
          case .italic(isActive: true):
            output = "_\(output)_"
          case let .kerning(kerning):
            tag("kerning", "\(kerning)")
          case let .speechAdjustedPitch(value):
            tag("speech-adjusted-pitch", "\(value)")
          case .speechAlwaysIncludesPunctuation(true):
            tag("speech-always-includes-punctuation")
          case .speechAnnouncementsQueued(true):
            tag("speech-announcements-queued")
          case .speechSpellsOutCharacters(true):
            tag("speech-spells-out-characters")
          case let .strikethrough(isActive: true, pattern: _, color: .some(color)):
            tag("s", attribute: "color", "\(color)")
          case .strikethrough(isActive: true, pattern: _, color: .none):
            output = "~~\(output)~~"
          case let .tracking(tracking):
            tag("tracking", "\(tracking)")
          case let .underline(isActive: true, pattern: _, .some(color)):
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
        return output
      }

      return dumpHelp(self)
    }
  }
#endif  // canImport(SwiftUI)
