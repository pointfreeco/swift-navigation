#if canImport(MacroTesting)
  import MacroTesting
  import SnapshotTesting
  import SwiftNavigationMacros
  import Testing

  @Suite(
    .macros(
      [
        UITransactionEntryMacro.self
      ],
      record: .failed
    )
  )
  struct UITransactionEntryMacroTests {
    @Test func basics() {
      assertMacro {
        """
        extension UITransaction {
          @UITransactionEntry var isSet: Bool = false
        }
        """
      } expansion: {
        """
        extension UITransaction {
          var isSet: Bool {
            get {
              self[__Key_isSet.self]
            }
            set {
              self[__Key_isSet.self] = newValue
            }
            _modify {
              yield &self[__Key_isSet.self]
            }
          }

          private struct __Key_isSet: SwiftNavigation.UITransactionKey {
            @SwiftNavigation._UITransactionEntryDefaultValue
            static var defaultValue: Bool = false
          }
        }
        """
      }
    }

    @Test func optionalWithoutDefault() {
      assertMacro {
        """
        extension UITransaction {
          @UITransactionEntry var name: String?
        }
        """
      } expansion: {
        """
        extension UITransaction {
          var name: String? {
            get {
              self[__Key_name.self]
            }
            set {
              self[__Key_name.self] = newValue
            }
            _modify {
              yield &self[__Key_name.self]
            }
          }

          private struct __Key_name: SwiftNavigation.UITransactionKey {
            @SwiftNavigation._UITransactionEntryDefaultValue
            static var defaultValue: String? = nil
          }
        }
        """
      }
    }

    @Test func inferredType() {
      assertMacro {
        """
        extension UITransaction {
          @UITransactionEntry var count = 0
        }
        """
      } expansion: {
        """
        extension UITransaction {
          var count {
            get {
              self[__Key_count.self]
            }
            set {
              self[__Key_count.self] = newValue
            }
            _modify {
              yield &self[__Key_count.self]
            }
          }

          private struct __Key_count: SwiftNavigation.UITransactionKey {
            @SwiftNavigation._UITransactionEntryDefaultValue
            static var defaultValue = 0
          }
        }
        """
      }
    }

    @Test func nonOptionalWithoutDefault() {
      assertMacro {
        """
        extension UITransaction {
          @UITransactionEntry var isSet: Bool
        }
        """
      } diagnostics: {
        """
        extension UITransaction {
          @UITransactionEntry var isSet: Bool
                                       ┬─────
                                       ╰─ 🛑 Property missing a default value
        }
        """
      }
    }

    @Test func appliedToLet() {
      assertMacro {
        """
        extension UITransaction {
          @UITransactionEntry let isSet: Bool = false
        }
        """
      } diagnostics: {
        """
        extension UITransaction {
          @UITransactionEntry let isSet: Bool = false
          ┬──────────────────────────────────────────
          ╰─ 🛑 '@UITransactionEntry' can only be applied to a 'var' declaration
        }
        """
      }
    }

    @Test func wrongContext() {
      assertMacro {
        """
        struct NotATransaction {
          @UITransactionEntry var isSet: Bool = false
        }
        """
      } diagnostics: {
        """
        struct NotATransaction {
          @UITransactionEntry var isSet: Bool = false
          ┬──────────────────
          ╰─ 🛑 '@UITransactionEntry' macro can only attach to var declarations inside extensions of 'UITransaction'
        }
        """
      }
    }

    @Test func topLevelContext() {
      assertMacro {
        """
        @UITransactionEntry var isSet: Bool = false
        """
      } diagnostics: {
        """
        @UITransactionEntry var isSet: Bool = false
        ┬──────────────────
        ╰─ 🛑 '@UITransactionEntry' macro can only attach to var declarations inside extensions of 'UITransaction'
        """
      }
    }
  }

  @Suite(
    .macros(
      ["_UITransactionEntryDefaultValue": UITransactionEntryDefaultValueMacro.self],
      record: .failed
    )
  )
  struct EntryDefaultValueMacroTests {
    @Test func basics() {
      assertMacro {
        """
        struct Key {
          @_UITransactionEntryDefaultValue
          static var defaultValue = 0
        }
        """
      } expansion: {
        """
        struct Key {
          static var defaultValue {
            get {
              0
            }
          }
        }
        """
      }
    }
  }
#endif
