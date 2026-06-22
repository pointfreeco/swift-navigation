import SwiftDiagnostics
package import SwiftSyntax
import SwiftSyntaxBuilder
package import SwiftSyntaxMacros

package enum UITransactionEntryMacro {
  static let moduleName = "SwiftNavigation"
  static let keyPrefix = "__Key_"
}

extension UITransactionEntryMacro: AccessorMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard context.isValidForEntry else {
      throw DiagnosticsError(
        diagnostics: [
          Diagnostic(
            node: node,
            message: MacroExpansionErrorMessage(
              """
              '@UITransactionEntry' macro can only attach to var declarations inside extensions of \
              'UITransaction'
              """
            )
          )
        ]
      )
    }

    guard let (_, identifier) = try bindingAndIdentifier(of: declaration) else { return [] }

    let key = "\(keyPrefix)\(identifier.text)"
    return [
      "get { self[\(raw: key).self] }",
      "set { self[\(raw: key).self] = newValue }",
      "_modify { yield &self[\(raw: key).self] }",
    ]
  }
}

extension UITransactionEntryMacro: PeerMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      context.isValidForEntry,
      let (binding, identifier) = try? bindingAndIdentifier(of: declaration)
    else {
      return []
    }

    let type = binding.typeAnnotation?.type.trimmed
    let defaultValue: ExprSyntax
    if let initializer = binding.initializer?.value {
      defaultValue = initializer.trimmed
    } else if type?.isOptional == true {
      defaultValue = "nil"
    } else {
      throw DiagnosticsError(
        diagnostics: [
          Diagnostic(
            node: Syntax(binding.typeAnnotation ?? TypeAnnotationSyntax(type: TypeSyntax("_"))),
            message: MacroExpansionErrorMessage(
              "Property missing a default value"
            )
          )
        ]
      )
    }

    let key = "\(keyPrefix)\(identifier.text)"
    let defaultValueDecl: DeclSyntax =
      type.map { "static var defaultValue: \($0) = \(defaultValue)" }
      ?? "static var defaultValue = \(defaultValue)"

    return [
      """
      private struct \(raw: key): \(raw: moduleName).UITransactionKey {
      @\(raw: moduleName)._UITransactionEntryDefaultValue
      \(defaultValueDecl)
      }
      """
    ]
  }
}

extension UITransactionEntryMacro {
  private static func bindingAndIdentifier(
    of declaration: some DeclSyntaxProtocol
  ) throws -> (binding: PatternBindingSyntax, identifier: TokenSyntax)? {
    guard
      let variable = declaration.as(VariableDeclSyntax.self),
      variable.bindingSpecifier.tokenKind == .keyword(.var)
    else {
      throw DiagnosticsError(
        diagnostics: [
          Diagnostic(
            node: declaration,
            message: MacroExpansionErrorMessage(
              "'@UITransactionEntry' can only be applied to a 'var' declaration"
            )
          )
        ]
      )
    }
    guard
      variable.bindings.count == 1,
      let binding = variable.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed
    else {
      return nil
    }
    return (binding, identifier)
  }
}

package enum UITransactionEntryDefaultValueMacro {}

extension UITransactionEntryDefaultValueMacro: AccessorMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard
      let variable = declaration.as(VariableDeclSyntax.self),
      let binding = variable.bindings.first,
      let initializer = binding.initializer?.value
    else {
      return []
    }
    return ["get { \(initializer.trimmed) }"]
  }
}

extension MacroExpansionContext {
  fileprivate var isValidForEntry: Bool {
    guard let extensionDecl = lexicalContext.first?.as(ExtensionDeclSyntax.self)
    else { return false }
    return ["UITransaction", "\(UITransactionEntryMacro.moduleName).UITransaction"]
      .contains(extensionDecl.extendedType.trimmedDescription)
  }
}

extension TypeSyntax {
  fileprivate var isOptional: Bool {
    self.is(OptionalTypeSyntax.self) || self.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
  }
}
