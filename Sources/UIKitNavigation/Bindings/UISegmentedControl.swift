#if canImport(UIKit) && !os(watchOS)
  import IssueReporting
  import UIKit

  @available(iOS 14, tvOS 14, *)
  extension UISegmentedControl {
    /// Creates a new color well with the specified frame and registers the binding against the
    /// selected color.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - selectedSegment: The binding to read from for the selected color, and write to when the
    ///     selected color is changes.
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

    /// Establishes a two-way connection between a binding and the color well's selected color.
    ///
    /// - Parameter selectedSegment: The binding to read from for the selected color, and write to
    ///   when the selected color changes.
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
        to: \.selectedSegmentIndex,
        for: .valueChanged
      )
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
