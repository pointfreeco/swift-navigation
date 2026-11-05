#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

extension NSButton {
    /// Creates a checkbox with the specified title and registers the binding against whether or
    /// not it is checked.
    ///
    /// - Parameters:
    ///   - title: The title displayed next to the checkbox.
    ///   - isOn: The binding to read from for whether the checkbox is checked, and write to when
    ///     the user checks or unchecks it.
    public convenience init(checkboxWithTitle title: String, isOn: UIBinding<Bool>) {
        self.init(checkboxWithTitle: title, target: nil, action: nil)
        bind(isOn: isOn)
    }

    /// Creates a checkbox with the specified title that is checked whenever a set contains a
    /// member.
    ///
    /// - Parameters:
    ///   - title: The title displayed next to the checkbox.
    ///   - options: The binding to read from for whether the checkbox is checked, and write to
    ///     when the user checks or unchecks it.
    ///   - member: The member that checking the checkbox inserts into the set, and unchecking it
    ///     removes.
    public convenience init<Options: SetAlgebra>(
        checkboxWithTitle title: String,
        isOn options: UIBinding<Options>,
        contains member: Options.Element
    ) {
        self.init(checkboxWithTitle: title, target: nil, action: nil)
        bind(isOn: options, contains: member)
    }

    /// Establishes a two-way connection between a binding and whether the button is on.
    ///
    /// Use this with checkboxes, and with other buttons whose state the user toggles. A mixed
    /// state counts as off.
    ///
    /// - Parameter isOn: The binding to read from for whether the button is on, and write to when
    ///   the user turns it on or off.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(isOn: UIBinding<Bool>) -> ObserveToken {
        bind(isOn, to: \.appKitNavigationIsOn) { button, isOn, _ in
            button.appKitNavigationIsOn = isOn
        }
    }

    /// Establishes a two-way connection between whether the button is on and whether a set
    /// contains a member.
    ///
    /// Turning the button on inserts the member into the set, and turning it off removes it. Any
    /// `SetAlgebra` works, option sets included:
    ///
    /// ```swift
    /// for kind in DeclarationKind.allCases {
    ///   let checkbox = NSButton(
    ///     checkboxWithTitle: kind.title, isOn: $model.shownKinds, contains: kind
    ///   )
    ///   stackView.addArrangedSubview(checkbox)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - options: The binding to read from for whether the button is on, and write to when the
    ///     user turns it on or off.
    ///   - member: The member that turning the button on inserts into the set, and turning it off
    ///     removes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Options: SetAlgebra>(
        isOn options: UIBinding<Options>,
        contains member: Options.Element
    ) -> ObserveToken {
        bind(isOn: options[containsMember: KeyPathArgument(member)])
    }

    // NB: Exposed to Objective-C so the binding can observe it, and named after the library so
    //     that it can never replace a method AppKit has, or adds later, under the same selector.
    @objc var appKitNavigationIsOn: Bool {
        set { state = newValue ? .on : .off }
        get { state == .on }
    }
}

extension SetAlgebra {
    fileprivate subscript(containsMember member: KeyPathArgument<Element>) -> Bool {
        get { contains(member.value) }
        set {
            if newValue {
                insert(member.value)
            } else {
                remove(member.value)
            }
        }
    }
}
#endif
