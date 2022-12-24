import Dependencies
import SwiftUI

@main
struct StandupsApp: App {
  var body: some Scene {
    WindowGroup {
      StandupsList(model: StandupsListModel())
    }
  }
}
