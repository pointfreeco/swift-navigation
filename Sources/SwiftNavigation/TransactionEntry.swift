/// Creates a transaction value entry.
///
/// Like SwiftUI's `Entry` macro, but for ``UITransaction``.
///
/// Create ``UITransaction`` entries by extending the ``UITransaction`` structure with new
/// properties and attaching the `@UITransactionEntry` macro to the variable declarations:
///
/// ```swift
/// extension UITransaction {
///   @UITransactionEntry var myCustomValue = "Default value"
/// }
/// ```
@attached(accessor)
@attached(peer, names: prefixed(__Key_))
public macro UITransactionEntry() =
  #externalMacro(module: "SwiftNavigationMacros", type: "UITransactionEntryMacro")

@attached(accessor)
public macro _UITransactionEntryDefaultValue() =
  #externalMacro(module: "SwiftNavigationMacros", type: "UITransactionEntryDefaultValueMacro")
