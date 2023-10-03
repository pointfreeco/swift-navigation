#if canImport(SwiftUI)
  import SwiftUI

  /// A view that computes content by extracting a case from a binding to an enum and passing a
  /// non-optional binding to the case's associated value to its content closure.
  ///
  /// Useful when working with enum state and building views that require the associated value at a
  /// particular case.
  ///
  /// For example, a warehousing application may model the status of an inventory item using an enum.
  /// ``IfCaseLet`` can be used to produce bindings to the associated values of each case.
  ///
  /// ```swift
  /// enum ItemStatus {
  ///   case inStock(quantity: Int)
  ///   case outOfStock(isOnBackOrder: Bool)
  /// }
  ///
  /// struct InventoryItemView: View {
  ///   @State var status: ItemStatus
  ///
  ///   var body: some View {
  ///     IfCaseLet(self.$status, pattern: /ItemStatus.inStock) { $quantity in
  ///       HStack {
  ///         Text("Quantity: \(quantity)")
  ///         Stepper("Quantity", value: $quantity)
  ///       }
  ///       Button("Out of stock") { self.status = .outOfStock(isOnBackOrder: false) }
  ///     }
  ///     IfCaseLet(self.$status, pattern: /ItemStatus.outOfStock) { $isOnBackOrder in
  ///       Toggle("Is on back order?", isOn: $isOnBackOrder)
  ///       Button("In stock") { self.status = .inStock(quantity: 1) }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// To exhaustively handle every case of a binding to an enum, see ``Switch``. Or, to unwrap a
  /// binding to an optional, see ``IfLet``.
  public struct IfCaseLet<Enum, Case, IfContent, ElseContent>: View
  where IfContent: View, ElseContent: View {
    public let `enum`: Binding<Enum>
    public let casePath: CasePath<Enum, Case>
    public let ifContent: (Binding<Case>) -> IfContent
    public let elseContent: ElseContent

    /// Computes content by extracting a case from a binding to an enum and passing a non-optional
    /// binding to the case's associated value to its content closure.
    ///
    /// - Parameters:
    ///   - enum: A binding to an enum that holds the source of truth for the content at a particular
    ///     case. When `casePath` successfully extracts a value from `enum`, a non-optional binding to
    ///     the value is passed to the `content` closure. The closure can use this binding to produce
    ///     its content and write changes back to the source of truth. Upstream changes to the case's
    ///     value will also be instantly reflected in the presented content. If `enum` becomes a
    ///     different case, nothing is computed.
    ///   - casePath: A case path that identifies a case of `enum` that holds a source of truth for
    ///     the content.
    ///   - ifContent: A closure for computing content when `enum` matches a particular case.
    ///   - elseContent: A closure for computing content when `enum` does not match the case.
    public init(
      _ `enum`: Binding<Enum>,
      pattern casePath: CasePath<Enum, Case>,
      @ViewBuilder then ifContent: @escaping (Binding<Case>) -> IfContent,
      @ViewBuilder else elseContent: () -> ElseContent
    ) {
      self.casePath = casePath
      self.elseContent = elseContent()
      self.enum = `enum`
      self.ifContent = ifContent
    }

    public var body: some View {
      if let $case = Binding(unwrapping: self.enum, case: self.casePath) {
        self.ifContent($case)
      } else {
        self.elseContent
      }
    }
  }

  extension IfCaseLet where ElseContent == EmptyView {
    public init(
      _ `enum`: Binding<Enum>,
      pattern casePath: CasePath<Enum, Case>,
      @ViewBuilder ifContent: @escaping (Binding<Case>) -> IfContent
    ) {
      self.casePath = casePath
      self.elseContent = EmptyView()
      self.enum = `enum`
      self.ifContent = ifContent
    }
  }
#endif  // canImport(SwiftUI)
