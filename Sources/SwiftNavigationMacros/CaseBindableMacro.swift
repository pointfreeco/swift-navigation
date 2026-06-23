import CasePathsMacrosSupport
import SwiftDiagnostics
package import SwiftSyntax
import SwiftSyntaxBuilder
package import SwiftSyntaxMacros

package enum CaseBindableMacro {
  static let moduleName = "SwiftNavigation"
}

extension CaseBindableMacro: ExtensionMacro {
  package static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      return []
    }

    var extensions = try CasePathableMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    )

    let conformsToCaseBindable =
      enumDecl.inheritanceClause?.inheritedTypes.contains {
        ["CaseBindable", "\(moduleName).CaseBindable"].contains($0.type.trimmedDescription)
      } ?? false
    if !conformsToCaseBindable {
      let caseBindableExtension: DeclSyntax = """
        \(declaration.attributes.availability)extension \(type.trimmed): \
        \(raw: moduleName).CaseBindable {}
        """
      extensions.append(caseBindableExtension.cast(ExtensionDeclSyntax.self))
    }

    return extensions
  }
}

extension CaseBindableMacro: MemberMacro {
  package static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try expansion(of: node, providingMembersOf: declaration, in: context)
  }

  package static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw DiagnosticsError(
        diagnostics: [
          Diagnostic(
            node: declaration,
            message: MacroExpansionErrorMessage("'@CaseBindable' can only be applied to enums")
          )
        ]
      )
    }

    var decls = try CasePathableMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      in: context
    )

    let elements = enumDecl.memberBlock.members
      .flatMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements ?? [] }

    var uiBindingCases: [String] = []
    var uiSwitchCases: [String] = []
    var bindingCases: [String] = []
    var bindingSwitchCases: [String] = []

    for element in elements {
      let name = element.name.trimmed
      let hasPayload = element.parameterClause.map { !$0.parameters.isEmpty } ?? false
      if hasPayload {
        let valueType = CasePathableMacro.valueType(for: element)
        uiBindingCases.append("case \(name)(\(moduleName).UIBinding<\(valueType)>)")
        bindingCases.append("case \(name)(\(moduleName)._Binding<\(valueType)>)")
        uiSwitchCases.append("case .\(name): return .\(name)(binding._$case(\\.\(name)))")
        bindingSwitchCases.append("case .\(name): return .\(name)(binding._$case(\\.\(name)))")
      } else {
        uiBindingCases.append("case \(name)")
        bindingCases.append("case \(name)")
        uiSwitchCases.append("case .\(name): return .\(name)")
        bindingSwitchCases.append("case .\(name): return .\(name)")
      }
    }

    decls.append(
      """
      public enum UIBindingEnumeration {
      \(raw: uiBindingCases.map { "\($0)\n" }.joined())}
      """
    )
    decls.append(
      """
      public static func _$caseBinding(
      _ binding: \(raw: moduleName).UIBinding<Self>
      ) -> UIBindingEnumeration {
      switch binding.wrappedValue {
      \(raw: uiSwitchCases.map { "\($0)\n" }.joined())}
      }
      """
    )
    decls.append(
      """
      #if canImport(SwiftUI)
      public enum BindingEnumeration {
      \(raw: bindingCases.map { "\($0)\n" }.joined())}
      public static func _$caseBinding(
      _ binding: \(raw: moduleName)._Binding<Self>
      ) -> BindingEnumeration {
      switch binding._$wrappedValue {
      \(raw: bindingSwitchCases.map { "\($0)\n" }.joined())}
      }
      #endif
      """
    )

    return decls
  }
}
