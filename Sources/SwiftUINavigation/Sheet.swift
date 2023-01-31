import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

extension View {
  /// Presents a sheet using a binding as a data source for the sheet's content.
  ///
  /// SwiftUI comes with a `sheet(item:)` view modifier that is powered by a binding to some
  /// hashable state. When this state becomes non-`nil`, it passes an unwrapped value to the content
  /// closure. This value, however, is completely static, which prevents the sheet from modifying
  /// it.
  ///
  /// This overload differs in that it passes a _binding_ to the content closure, instead. This
  /// gives the sheet the ability to write changes back to its source of truth.
  ///
  /// Also unlike `sheet(item:)`, the binding's value does _not_ need to be hashable.
  ///
  /// ```swift
  /// struct TimelineView: View {
  ///   @State var draft: Post?
  ///
  ///   var body: Body {
  ///     Button("Compose") {
  ///       self.draft = Post()
  ///     }
  ///     .sheet(unwrapping: self.$draft) { $draft in
  ///       ComposeView(post: $draft, onSubmit: { ... })
  ///     }
  ///   }
  /// }
  ///
  /// struct ComposeView: View {
  ///   @Binding var post: Post
  ///   var body: some View { ... }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - value: A binding to an optional source of truth for the sheet. When `value` is non-`nil`,
  ///     a non-optional binding to the value is passed to the `content` closure. You use this
  ///     binding to produce content that the system presents to the user in a sheet. Changes made
  ///     to the sheet's binding will be reflected back in the source of truth. Likewise, changes
  ///     to `value` are instantly reflected in the sheet. If `value` becomes `nil`, the sheet is
  ///     dismissed.
  ///   - onDismiss: The closure to execute when dismissing the sheet.
  ///   - content: A closure returning the content of the sheet.
  @MainActor
  public func sheet<Value, Content>(
    unwrapping value: Binding<Value?>,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Binding<Value>) -> Content
  ) -> some View
  where Content: View {
    self.sheet(item: value.identifiable, onDismiss: onDismiss) { _ in
      Binding(unwrapping: value).map(content)
    }
  }

  /// Presents a sheet using a binding and case path as the data source for the sheet's content.
  ///
  /// A version of `View.sheet(unwrapping:)` that works with enum state.
  ///
  /// - Parameters:
  ///   - enum: A binding to an optional enum that holds the source of truth for the sheet at a
  ///     particular case. When `enum` is non-`nil`, and `casePath` successfully extracts a value, a
  ///     non-optional binding to the value is passed to the `content` closure. You use this binding
  ///     to produce content that the system presents to the user in a sheet. Changes made to the
  ///     sheet's binding will be reflected back in the source of truth. Likewise, changes to `enum`
  ///     at the given case are instantly reflected in the sheet. If `enum` becomes `nil`, or
  ///     becomes a case other than the one identified by `casePath`, the sheet is dismissed.
  ///   - casePath: A case path that identifies a case of `enum` that holds a source of truth for
  ///     the sheet.
  ///   - onDismiss: The closure to execute when dismissing the sheet.
  ///   - content: A closure returning the content of the sheet.
  @MainActor
  public func sheet<Enum, Case, Content>(
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Binding<Case>) -> Content
  ) -> some View
  where Content: View {
    self.sheet(unwrapping: `enum`.case(casePath), onDismiss: onDismiss, content: content)
  }
}

struct AnyIdentifiable<Value>: Identifiable {
  enum ID: Hashable {
    case id(AnyHashable)
    case inferred(ObjectIdentifier, UInt32?)
  }

  let id: ID
  let value: Value

  init?<Optional: OptionalProtocol>(_ optional: Optional) where Optional.Wrapped == Value {
    guard let value = optional.wrappedValue else { return nil }
    if let identifiable = value as? any Identifiable {
      self.id = .id(AnyHashable(identifiable._id))
    } else {
      self.id = .inferred(ObjectIdentifier(Value.self), enumTag(value))
    }
    self.value = value
  }
}

protocol OptionalProtocol {
  associatedtype Wrapped
  var wrappedValue: Wrapped? { get set }
  init(wrappedValue: Wrapped?)
}

extension Optional: OptionalProtocol {
  init(wrappedValue: Wrapped?) {
    self = wrappedValue
  }
  var wrappedValue: Wrapped? {
    get { self }
    set { self = newValue }
  }
}

extension Identifiable {
  var _id: ID { self.id }
}

extension OptionalProtocol {
  var identifiable: AnyIdentifiable<Wrapped>? {
    get { AnyIdentifiable(self.wrappedValue) }
    set { self = .init(wrappedValue: newValue?.value) }
  }
}

private func enumTag<Case>(_ `case`: Case) -> UInt32? {
  let metadataPtr = unsafeBitCast(type(of: `case`), to: UnsafeRawPointer.self)
  let kind = metadataPtr.load(as: Int.self)
  let isEnumOrOptional = kind == 0x201 || kind == 0x202
  guard isEnumOrOptional else { return nil }
  let vwtPtr = (metadataPtr - MemoryLayout<UnsafeRawPointer>.size).load(as: UnsafeRawPointer.self)
  let vwt = vwtPtr.load(as: EnumValueWitnessTable.self)
  return withUnsafePointer(to: `case`) { vwt.getEnumTag($0, metadataPtr) }
}

private struct EnumValueWitnessTable {
  let f1, f2, f3, f4, f5, f6, f7, f8: UnsafeRawPointer
  let f9, f10: Int
  let f11, f12: UInt32
  let getEnumTag: @convention(c) (UnsafeRawPointer, UnsafeRawPointer) -> UInt32
  let f13, f14: UnsafeRawPointer
}
