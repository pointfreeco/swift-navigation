import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftNavigationPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    CaseBindableMacro.self
  ]
}
