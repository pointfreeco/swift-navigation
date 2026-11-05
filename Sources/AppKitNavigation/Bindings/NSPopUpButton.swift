#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

extension NSPopUpButton {
    /// Creates a pop-up button with an item for each option, and registers the binding against
    /// the selected one.
    ///
    /// ```swift
    /// let weightPopUpButton = NSPopUpButton(
    ///   selection: $model.weight, options: Weight.allCases, title: \.displayName
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user chooses another one.
    ///   - options: The options, in the order of their items.
    ///   - title: The title of the item for an option.
    ///   - fileID: The source `#fileID` associated with the binding.
    ///   - filePath: The source `#filePath` associated with the binding.
    ///   - line: The source `#line` associated with the binding.
    ///   - column: The source `#column` associated with the binding.
    public convenience init<Value: Equatable>(
        frame: CGRect = .zero,
        selection: UIBinding<Value>,
        options: [Value],
        title: (Value) -> String,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.init(frame: frame, pullsDown: false)
        // NB: Added through the menu, since 'addItem(withTitle:)' first removes an item that has
        //     the same title, which would leave two options sharing one item.
        for option in options {
            menu?.addItem(withTitle: title(option), action: nil, keyEquivalent: "")
        }
        bind(
            selection: selection,
            options: options,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    /// Establishes a two-way connection between a binding and the item the pop-up button has
    /// selected, the item at the same position as the bound value among `options`.
    ///
    /// The pop-up button's items must match the options one for one, in order, which
    /// ``AppKit/NSPopUpButton/init(frame:selection:options:title:fileID:filePath:line:column:)``
    /// takes care of. A value that is not one of the options selects no item, and choosing an
    /// item past the last option leaves the binding alone; both are reported as issues.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user chooses another one.
    ///   - options: The options, in the order of the pop-up button's items.
    ///   - fileID: The source `#fileID` associated with the binding.
    ///   - filePath: The source `#filePath` associated with the binding.
    ///   - line: The source `#line` associated with the binding.
    ///   - column: The source `#column` associated with the binding.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Value: Equatable>(
        selection: UIBinding<Value>,
        options: [Value],
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) -> ObserveToken {
        let index = selection.optionIndex(
            among: options, fileID: fileID, filePath: filePath, line: line, column: column
        )
        return bind(index, to: \.appKitNavigationIndexOfSelectedItem) { popUpButton, index, _ in
            if index == -1 {
                reportIssue(
                    """
                    A pop-up button's selection ('\(selection.wrappedValue)') is not one of its \
                    options, so no item is selected.
                    """,
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            }
            popUpButton.appKitNavigationIndexOfSelectedItem = index
        }
    }

    // NB: Exposed to Objective-C so the binding can observe it, and named after the library so
    //     that it can never replace a method AppKit has, or adds later, under the same selector.
    @objc var appKitNavigationIndexOfSelectedItem: Int {
        set { selectItem(at: newValue) }
        get { indexOfSelectedItem }
    }
}
#endif
