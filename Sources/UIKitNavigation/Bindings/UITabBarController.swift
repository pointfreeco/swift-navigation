#if canImport(UIKit)
  import UIKit

  @available(iOS 18, *)
  extension UITabBarController {
    public func bind(selectedTab: UIBinding<String?>) -> ObservationToken {
      let token = observe { [weak self] in
        guard let self else { return }
        guard let identifier = selectedTab.wrappedValue else {
          self.selectedTab = nil
          return
        }
        guard let tab = tabs.first(where: { $0.identifier == identifier })
        else {
          // TODO: runtimeWarn
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
      let observationToken = ObservationToken {
        token.cancel()
        observation.invalidate()
      }
      // TODO: Hold onto token
      return observationToken
    }
  }
#endif
