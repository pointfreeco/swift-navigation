public import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftNavigationPlugin: CompilerPlugin {
  var providingMacros: [any Macro.Type] {
    var macros: [any Macro.Type] = [
      UITransactionEntryDefaultValueMacro.self,
      UITransactionEntryMacro.self,
    ]
    #if CasePaths
      macros.append(CaseBindableMacro.self)
    #endif
    return macros
  }
}
