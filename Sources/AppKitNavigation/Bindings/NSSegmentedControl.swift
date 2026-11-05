#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

extension NSSegmentedControl {
    /// Creates a new segmented control with the specified frame and registers the binding against
    /// the selected segment.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - selectedSegment: The binding to read from for the selected segment, and write to when the
    ///     selected segment changes.
    ///   - fileID: The source `#fileID` associated with the control.
    ///   - filePath: The source `#filePath` associated with the control.
    ///   - line: The source `#line` associated with the control.
    ///   - column: The source `#column` associated with the control.
    public convenience init(
        frame: CGRect = .zero, selectedSegment: UIBinding<some RawRepresentable<Int>>,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.init(frame: frame)
        bind(
            selectedSegment: selectedSegment,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    /// Establishes a two-way connection between a binding and the segmented control's selected
    /// segment.
    ///
    /// - Parameters:
    ///   - selectedSegment: The binding to read from for the selected segment, and write to when the
    ///     selected segment changes.
    ///   - fileID: The source `#fileID` associated with the binding.
    ///   - filePath: The source `#filePath` associated with the binding.
    ///   - line: The source `#line` associated with the binding.
    ///   - column: The source `#column` associated with the binding.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(
        selectedSegment: UIBinding<some RawRepresentable<Int>>,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) -> ObserveToken {
        let fileID = HashableStaticString(rawValue: fileID)
        let filePath = HashableStaticString(rawValue: filePath)
        return bind(
            selectedSegment[fileID: fileID, filePath: filePath, line: line, column: column],
            to: \.selectedSegment
        )
    }

    /// Creates a segmented control with a segment for each option, and registers the binding
    /// against the selected one.
    ///
    /// ```swift
    /// let layoutControl = NSSegmentedControl(
    ///   selection: $model.layout, options: Layout.allCases, title: \.title
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user selects another one.
    ///   - options: The options, in the order of their segments.
    ///   - title: The label of the segment for an option.
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
        self.init(frame: frame)
        segmentCount = options.count
        for (segment, option) in options.enumerated() {
            setLabel(title(option), forSegment: segment)
        }
        trackingMode = .selectOne
        bind(
            selection: selection,
            options: options,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    /// Establishes a two-way connection between a binding and the selected segment, the segment
    /// at the same position as the bound value among `options`.
    ///
    /// Unlike ``AppKit/NSSegmentedControl/bind(selectedSegment:fileID:filePath:line:column:)``,
    /// the value need not be raw-representable: any equatable value works. The segments must
    /// match the options one for one, in order, which
    /// ``AppKit/NSSegmentedControl/init(frame:selection:options:title:fileID:filePath:line:column:)``
    /// takes care of. A value that is not one of the options selects no segment, and selecting a
    /// segment past the last option leaves the binding alone; both are reported as issues.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user selects another one.
    ///   - options: The options, in the order of the segments.
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
        return bind(index, to: \.selectedSegment) { segmentedControl, index, _ in
            if index == -1 {
                reportIssue(
                    """
                    A segmented control's selection ('\(selection.wrappedValue)') is not one of \
                    its options, so no segment is selected.
                    """,
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            }
            segmentedControl.selectedSegment = index
        }
    }
}

extension RawRepresentable<Int> {
    fileprivate subscript(
        fileID fileID: HashableStaticString,
        filePath filePath: HashableStaticString,
        line line: UInt,
        column column: UInt
    ) -> Int {
        get { rawValue }
        set {
            guard let rawRepresentable = Self(rawValue: newValue)
            else {
                reportIssue(
                    """
                    Raw-representable 'UIBinding<\(Self.self)>' attempted to write an invalid raw value \
                    ('\(newValue)').
                    """,
                    fileID: fileID.rawValue,
                    filePath: filePath.rawValue,
                    line: line,
                    column: column
                )
                return
            }
            self = rawRepresentable
        }
    }
}
#endif
