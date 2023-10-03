#if canImport(SwiftUI)
  import SwiftUI

  /// A view that computes content by unwrapping a binding to an optional and passing a non-optional
  /// binding to its content closure.
  ///
  /// Useful when working with optional state and building views that require non-optional state.
  ///
  /// For example, a warehousing application may model the quantity of an inventory item using an
  /// optional integer, where a `nil` value denotes an item that is out-of-stock. In order to produce
  /// a binding to a non-optional integer for a stepper, ``IfLet`` can be used to safely unwrap the
  /// optional binding.
  ///
  /// ```swift
  /// struct InventoryItemView: View {
  ///   @State var quantity: Int?
  ///
  ///   var body: some View {
  ///     IfLet(self.$quantity) { $quantity in
  ///       HStack {
  ///         Text("Quantity: \(quantity)")
  ///         Stepper("Quantity", value: $quantity)
  ///       }
  ///       Button("Out of stock") { self.quantity = nil }
  ///     } else: {
  ///       Button("In stock") { self.quantity = 1 }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// To unwrap a particular case of a binding to an enum, see ``IfCaseLet``, or, to exhaustively
  /// handle every case, see ``Switch``.
  public struct IfLet<Value, IfContent, ElseContent>: View
  where IfContent: View, ElseContent: View {
    public let value: Binding<Value?>
    public let ifContent: (Binding<Value>) -> IfContent
    public let elseContent: ElseContent

    /// Computes content by unwrapping a binding to an optional and passing a non-optional binding to
    /// its content closure.
    ///
    /// - Parameters:
    ///   - value: A binding to an optional source of truth for the content. When `value` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `ifContent` closure. The
    ///     closure can use this binding to produce its content and write changes back to the source
    ///     of truth. Upstream changes to `value` will also be instantly reflected in the presented
    ///     content. If `value` becomes `nil`, the `elseContent` closure is used to produce content
    ///     instead.
    ///   - ifContent: A closure for computing content when `value` is non-`nil`.
    ///   - elseContent: A closure for computing content when `value` is `nil`.
    public init(
      _ value: Binding<Value?>,
      @ViewBuilder then ifContent: @escaping (Binding<Value>) -> IfContent,
      @ViewBuilder else elseContent: () -> ElseContent
    ) {
      self.value = value
      self.ifContent = ifContent
      self.elseContent = elseContent()
    }

    public var body: some View {
      if let $value = Binding(unwrapping: self.value) {
        self.ifContent($value)
      } else {
        self.elseContent
      }
    }
  }

  extension IfLet where ElseContent == EmptyView {
    /// Computes content by unwrapping a binding to an optional and passing a non-optional binding to
    /// its content closure.
    ///
    /// - Parameters:
    ///   - value: A binding to an optional source of truth for the content. When `value` is
    ///     non-`nil`, a non-optional binding to the value is passed to the `ifContent` closure. The
    ///     closure can use this binding to produce its content and write changes back to the source
    ///     of truth. Upstream changes to `value` will also be instantly reflected in the presented
    ///     content. If `value` becomes `nil`, nothing is computed.
    ///   - ifContent: A closure for computing content when `value` is non-`nil`.
    public init(
      _ value: Binding<Value?>,
      @ViewBuilder then ifContent: @escaping (Binding<Value>) -> IfContent
    ) {
      self.init(value, then: ifContent, else: { EmptyView() })
    }
  }
#endif  // canImport(SwiftUI)
