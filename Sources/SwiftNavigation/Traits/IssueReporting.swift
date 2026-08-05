#if IssueReporting
  import IssueReporting
#elseif canImport(os)
  import os

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  private let logger = Logger(subsystem: "SwiftNavigation", category: "Runtime Issues")
#endif

@_transparent
package func reportIssue(
  _ message: @autoclosure () -> String? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  guard let message = message() else { return }
  #if IssueReporting
    IssueReporting.reportIssue(
      message,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  #elseif canImport(os)
    if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
      logger.warning("\(message)")
    } else {
      print(message)
    }
  #else
    print(message)
  #endif
}
