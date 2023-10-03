#if canImport(SwiftUI)
  import SwiftUI
  @_spi(RuntimeWarn) import SwiftUINavigationCore

  /// A view that can switch over a binding of enum state and exhaustively handle each case.
  ///
  /// Useful for computing a view from enum state where every case should be handled (using a
  /// ``CaseLet`` view), or where there should be a default fallback view (using a ``Default`` view).
  ///
  /// For example, a warehousing application may model the status of an inventory item using an enum
  /// with cases that distinguish in-stock and out-of-stock statuses. ``Switch`` (and ``CaseLet``) can
  /// be used to produce bindings to the associated values of each case.
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
  ///     Switch(self.$status) {
  ///       CaseLet(/ItemStatus.inStock) { $quantity in
  ///         HStack {
  ///           Text("Quantity: \(quantity)")
  ///           Stepper("Quantity", value: $quantity)
  ///         }
  ///         Button("Out of stock") { self.status = .outOfStock(isOnBackOrder: false) }
  ///       }
  ///       CaseLet(/ItemStatus.outOfStock) { $isOnBackOrder in
  ///         Toggle("Is on back order?", isOn: $isOnBackOrder)
  ///         Button("In stock") { self.status = .inStock(quantity: 1) }
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// To unwrap an individual case of a binding to an enum (_i.e._, if exhaustivity is not needed),
  /// use ``IfCaseLet``, instead. Or, to unwrap a binding to an optional, use ``IfLet``.
  ///
  /// > Note: In debug builds, exhaustivity is handled at runtime: if the `Switch` encounters an
  /// > unhandled case, and no ``Default`` view is present, a runtime warning is issued and a warning
  /// > view is presented.
  public struct Switch<Enum, Content: View>: View {
    public let `enum`: Binding<Enum>
    public let content: Content

    private init(
      enum: Binding<Enum>,
      @ViewBuilder content: () -> Content
    ) {
      self.enum = `enum`
      self.content = content()
    }

    public var body: some View {
      self.content
        .environmentObject(BindingObject(binding: self.enum))
    }
  }

  /// A view that handles a specific case of enum state in a ``Switch``.
  public struct CaseLet<Enum, Case, Content>: View
  where Content: View {
    @EnvironmentObject private var `enum`: BindingObject<Enum>
    public let casePath: CasePath<Enum, Case>
    public let content: (Binding<Case>) -> Content

    /// Computes content for a particular case of an enum handled by a ``Switch``.
    ///
    /// - Parameters:
    ///   - casePath: A case path that identifies a case of the ``Switch``'s enum that holds a source
    ///     of truth for the content.
    ///   - content: A closure returning the content to be computed from a binding to an enum case.
    public init(
      _ casePath: CasePath<Enum, Case>,
      @ViewBuilder then content: @escaping (Binding<Case>) -> Content
    ) {
      self.casePath = casePath
      self.content = content
    }

    public var body: some View {
      Binding(unwrapping: self.enum.wrappedValue, case: self.casePath).map(self.content)
    }
  }

  /// A view that covers any cases that aren't explicitly addressed in a ``Switch``.
  ///
  /// If you wish to use ``Switch`` in a non-exhaustive manner (_i.e._, you do not want to provide a
  /// ``CaseLet`` for every case of the enum), then you must insert a ``Default`` view at the end of
  /// the ``Switch``'s body, or use ``IfCaseLet`` instead.
  public struct Default<Content: View>: View {
    private let content: Content

    /// Initializes a ``Default`` view that computes content depending on if a binding to enum state
    /// does not match a particular case.
    ///
    /// - Parameter content: A function that returns a view that is visible only when the switch
    ///   view's state does not match a preceding ``CaseLet`` view.
    public init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    public var body: some View {
      self.content
    }
  }

  extension Switch {
    public init<Case1, Content1, DefaultContent>(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        CaseLet<Enum, Case1, Content1>,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        if content.0.casePath ~= `enum`.wrappedValue {
          content.0
        } else {
          content.1
        }
      }
    }

    public init<Case1, Content1>(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> CaseLet<Enum, Case1, Content1>
    )
    where
      Content == _ConditionalContent<
        CaseLet<Enum, Case1, Content1>,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      self.init(`enum`) {
        content()
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<Case1, Content1, Case2, Content2, DefaultContent>(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        default:
          content.2
        }
      }
    }

    public init<Case1, Content1, Case2, Content2>(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        _ConditionalContent<
          CaseLet<Enum, Case3, Content3>,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        case content.2.casePath:
          content.2
        default:
          content.3
        }
      }
    }

    public init<Case1, Content1, Case2, Content2, Case3, Content3>(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>
        >,
        _ConditionalContent<
          CaseLet<Enum, Case3, Content3>,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        case content.2.casePath:
          content.2
        case content.3.casePath:
          content.3
        default:
          content.4
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case5, Content5>,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        case content.2.casePath:
          content.2
        case content.3.casePath:
          content.3
        case content.4.casePath:
          content.4
        default:
          content.5
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case5, Content5>,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        case content.2.casePath:
          content.2
        case content.3.casePath:
          content.3
        case content.4.casePath:
          content.4
        case content.5.casePath:
          content.5
        default:
          content.6
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case7, Content7>,
            Default<DefaultContent>
          >
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        case content.2.casePath:
          content.2
        case content.3.casePath:
          content.3
        case content.4.casePath:
          content.4
        case content.5.casePath:
          content.5
        case content.6.casePath:
          content.6
        default:
          content.7
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case1, Content1>,
            CaseLet<Enum, Case2, Content2>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case3, Content3>,
            CaseLet<Enum, Case4, Content4>
          >
        >,
        _ConditionalContent<
          _ConditionalContent<
            CaseLet<Enum, Case5, Content5>,
            CaseLet<Enum, Case6, Content6>
          >,
          _ConditionalContent<
            CaseLet<Enum, Case7, Content7>,
            Default<_ExhaustivityCheckView<Enum>>
          >
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        content.value.6
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        Default<DefaultContent>
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        case content.2.casePath:
          content.2
        case content.3.casePath:
          content.3
        case content.4.casePath:
          content.4
        case content.5.casePath:
          content.5
        case content.6.casePath:
          content.6
        case content.7.casePath:
          content.7
        default:
          content.8
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        Default<_ExhaustivityCheckView<Enum>>
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        content.value.6
        content.value.7
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8,
      Case9, Content9,
      DefaultContent
    >(
      _ enum: Binding<Enum>,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>,
          CaseLet<Enum, Case9, Content9>,
          Default<DefaultContent>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case9, Content9>,
          Default<DefaultContent>
        >
      >
    {
      self.init(enum: `enum`) {
        let content = content().value
        switch `enum`.wrappedValue {
        case content.0.casePath:
          content.0
        case content.1.casePath:
          content.1
        case content.2.casePath:
          content.2
        case content.3.casePath:
          content.3
        case content.4.casePath:
          content.4
        case content.5.casePath:
          content.5
        case content.6.casePath:
          content.6
        case content.7.casePath:
          content.7
        case content.8.casePath:
          content.8
        default:
          content.9
        }
      }
    }

    public init<
      Case1, Content1,
      Case2, Content2,
      Case3, Content3,
      Case4, Content4,
      Case5, Content5,
      Case6, Content6,
      Case7, Content7,
      Case8, Content8,
      Case9, Content9
    >(
      _ enum: Binding<Enum>,
      file: StaticString = #fileID,
      line: UInt = #line,
      @ViewBuilder content: () -> TupleView<
        (
          CaseLet<Enum, Case1, Content1>,
          CaseLet<Enum, Case2, Content2>,
          CaseLet<Enum, Case3, Content3>,
          CaseLet<Enum, Case4, Content4>,
          CaseLet<Enum, Case5, Content5>,
          CaseLet<Enum, Case6, Content6>,
          CaseLet<Enum, Case7, Content7>,
          CaseLet<Enum, Case8, Content8>,
          CaseLet<Enum, Case9, Content9>
        )
      >
    )
    where
      Content == _ConditionalContent<
        _ConditionalContent<
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case1, Content1>,
              CaseLet<Enum, Case2, Content2>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case3, Content3>,
              CaseLet<Enum, Case4, Content4>
            >
          >,
          _ConditionalContent<
            _ConditionalContent<
              CaseLet<Enum, Case5, Content5>,
              CaseLet<Enum, Case6, Content6>
            >,
            _ConditionalContent<
              CaseLet<Enum, Case7, Content7>,
              CaseLet<Enum, Case8, Content8>
            >
          >
        >,
        _ConditionalContent<
          CaseLet<Enum, Case9, Content9>,
          Default<_ExhaustivityCheckView<Enum>>
        >
      >
    {
      let content = content()
      self.init(`enum`) {
        content.value.0
        content.value.1
        content.value.2
        content.value.3
        content.value.4
        content.value.5
        content.value.6
        content.value.7
        content.value.8
        Default { _ExhaustivityCheckView<Enum>(file: file, line: line) }
      }
    }
  }

  public struct _ExhaustivityCheckView<Enum>: View {
    @EnvironmentObject private var `enum`: BindingObject<Enum>
    let file: StaticString
    let line: UInt

    public var body: some View {
      #if DEBUG
        let message = """
          Warning: Switch.body@\(self.file):\(self.line)

          "Switch" did not handle "\(describeCase(self.enum.wrappedValue.wrappedValue))"

          Make sure that you exhaustively provide a "CaseLet" view for each case in "\(Enum.self)", \
          provide a "Default" view at the end of the "Switch", or use an "IfCaseLet" view instead.
          """
        VStack(spacing: 17) {
          self.exclamation()
            .font(.largeTitle)

          Text(message)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(.white)
        .padding()
        .background(Color.red.edgesIgnoringSafeArea(.all))
        .onAppear { runtimeWarn(message, file: self.file, line: self.line) }
      #else
        EmptyView()
      #endif
    }

    func exclamation() -> some View {
      #if os(macOS)
        return Text("⚠️")
      #else
        return Image(systemName: "exclamationmark.triangle.fill")
      #endif
    }
  }

  private class BindingObject<Value>: ObservableObject {
    let wrappedValue: Binding<Value>

    init(binding: Binding<Value>) {
      self.wrappedValue = binding
    }
  }

  private func describeCase<Enum>(_ enum: Enum) -> String {
    let mirror = Mirror(reflecting: `enum`)
    let `case`: String
    if mirror.displayStyle == .enum, let child = mirror.children.first, let label = child.label {
      let childMirror = Mirror(reflecting: child.value)
      let associatedValuesMirror =
        childMirror.displayStyle == .tuple
        ? childMirror
        : Mirror(`enum`, unlabeledChildren: [child.value], displayStyle: .tuple)
      `case` = """
        \(label)(\
        \(associatedValuesMirror.children.map { "\($0.label ?? "_"):" }.joined())\
        )
        """
    } else {
      `case` = "\(`enum`)"
    }
    var type = String(reflecting: Enum.self)
    if let index = type.firstIndex(of: ".") {
      type.removeSubrange(...index)
    }
    return "\(type).\(`case`)"
  }
#endif  // canImport(SwiftUI)
