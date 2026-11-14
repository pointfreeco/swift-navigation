#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

extension NSTabViewController {
    /// Establishes a two-way connection between a binding and the selected tab, the tab at the
    /// same position as the bound value among `options`.
    ///
    /// Add the tab view items first: the tabs must match the options one for one, in order. When
    /// the user selects another tab, its option is written back to the binding.
    ///
    /// ```swift
    /// tabViewController.addTabViewItem(NSTabViewItem(viewController: allSymbolsViewController))
    /// tabViewController.addTabViewItem(NSTabViewItem(viewController: symbolKindsViewController))
    /// tabViewController.bind(selection: $model.mode, options: SidebarMode.allCases)
    /// ```
    ///
    /// A value that is not one of the options, or one with no tab, leaves the selected tab as it
    /// is and is reported as an issue.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user selects another tab.
    ///   - options: The options, in the order of the tabs.
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
        // NB: No target-action pair: the selected index is key-value observable, and changes when
        //     the user picks another tab.
        return establishBinding(index, to: \.selectedTabViewItemIndex, of: self, through: nil) {
            tabViewController, index, _ in
            guard tabViewController.tabViewItems.indices.contains(index)
            else {
                reportIssue(
                    """
                    A tab view controller's selection ('\(selection.wrappedValue)') is not one of \
                    its options, or has no tab, so the selected tab stays as it is.
                    """,
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
                return
            }
            tabViewController.selectedTabViewItemIndex = index
        }
    }

    /// Removes the binding established with
    /// ``AppKit/NSTabViewController/bind(selection:options:fileID:filePath:line:column:)``.
    public func unbindSelection() {
        removeBinding(to: \NSTabViewController.selectedTabViewItemIndex)
    }
}
#endif
