import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftNavigationPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    CaseBindableMacro.self
  ]
}
