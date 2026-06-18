#if CustomDump
  public import CustomDump

  extension AlertState: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
      var children: [(label: String?, value: Any)] = [
        ("title", self.title)
      ]
      if !self.buttons.isEmpty {
        children.append(("actions", self.buttons))
      }
      if let message {
        children.append(("message", message))
      }
      return Mirror(
        self,
        children: children,
        displayStyle: .struct
      )
    }
  }

  extension ButtonState: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
      var children: [(label: String?, value: Any)] = []
      if let role = self.role {
        children.append(("role", role))
      }
      children.append(("action", self.action))
      children.append(("label", self.label))
      return Mirror(
        self,
        children: children,
        displayStyle: .struct
      )
    }
  }

  extension ButtonStateAction: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
      switch self.type {
      case .send(let action):
        return Mirror(
          self,
          children: [
            "send": action as Any
          ],
          displayStyle: .enum
        )
      #if canImport(SwiftUI)
        case .animatedSend(let action, let animation):
          return Mirror(
            self,
            children: [
              "send": (action, animation: animation)
            ],
            displayStyle: .enum
          )
      #endif
      }
    }
  }

  @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
  extension ConfirmationDialogState: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
      var children: [(label: String?, value: Any)] = []
      if self.titleVisibility != .automatic {
        children.append(("titleVisibility", self.titleVisibility))
      }
      children.append(("title", self.title))
      if !self.buttons.isEmpty {
        children.append(("actions", self.buttons))
      }
      if let message {
        children.append(("message", message))
      }
      return Mirror(
        self,
        children: children,
        displayStyle: .struct
      )
    }
  }

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
        case .localizedStringResource(let resourceBox):
          output = resourceBox.asString()

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
#endif
