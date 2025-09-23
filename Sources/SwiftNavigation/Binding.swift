#if canImport(SwiftUI)
  import IssueReporting
  import SwiftUI

  extension Binding {
    /// Creates a binding by projecting the base optional value to a Boolean value.
    ///
    /// Writing `false` to the binding will `nil` out the base value. Writing `true` produces a
    /// runtime warning.
    ///
    /// - Parameter base: A value to project to a Boolean value.
    public init<V>(
      _ base: Binding<V?>,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      line: UInt = #line,
      column: UInt = #column
    ) where Value == Bool {
      self =
        base[
          fileID: HashableStaticString(rawValue: fileID),
          filePath: HashableStaticString(rawValue: filePath),
          line: line,
          column: column
        ]
    }
  }

  extension Optional {
    fileprivate subscript(
      fileID fileID: HashableStaticString,
      filePath filePath: HashableStaticString,
      line line: UInt,
      column column: UInt
    ) -> Bool {
      get { self != nil }
      set {
        if newValue {
          reportIssue(
            """
            Boolean presentation binding attempted to write 'true' to a generic 'Binding<Item?>' \
            (i.e., 'Binding<\(Wrapped.self)?>').

            This is not a valid thing to do, as there is no way to convert 'true' to a new \
            instance of '\(Wrapped.self)'.
            """,
            fileID: fileID.rawValue,
            filePath: filePath.rawValue,
            line: line,
            column: column
          )
        } else {
          self = nil
        }
      }
    }
  }
#endif
