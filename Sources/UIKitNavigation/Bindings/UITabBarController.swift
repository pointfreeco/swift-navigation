#if swift(>=6) && canImport(UIKit) && !os(tvOS) && !os(watchOS)
  import IssueReporting
  import UIKit

  @available(iOS 18, tvOS 18, visionOS 2, *)
  extension UITabBarController {
    @discardableResult
    public func bind(
      selectedTab: UIBinding<String?>,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      line: UInt = #line,
      column: UInt = #column
    ) -> ObserveToken {
      let token = observe { [weak self] in
        guard let self else { return }
        guard let identifier = selectedTab.wrappedValue else {
          self.selectedTab = nil
          return
        }
        guard let tab = tabs.first(where: { $0.identifier == identifier })
        else {
          reportIssue(
            """
            Tab bar controller binding attempted to write an invalid identifier ('\(identifier)').

            Valid identifiers: \(tabs.map(\.identifier))
            """,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
          )
          self.selectedTab = nil
          return
        }
        self.selectedTab = tab
      }
      let observation = observe(\.selectedTab) { controller, _ in
        MainActor.assumeIsolated {
          selectedTab.wrappedValue = controller.selectedTab?.identifier
        }
      }
      let observeToken = ObserveToken {
        token.cancel()
        observation.invalidate()
      }
      self.observeToken = observeToken
      return observeToken
    }

    private var observeToken: ObserveToken? {
      get {
        objc_getAssociatedObject(self, Self.observeTokenKey) as? ObserveToken
      }
      set {
        objc_setAssociatedObject(
          self, Self.observeTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
      }
    }

    private static let observeTokenKey = malloc(1)!
  }
#endif
