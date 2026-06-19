#if IssueReporting
  import IssueReporting
#elseif canImport(os)
  import os

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
    logger.warning("\(message)")
  #else
    print(message)
  #endif
}
