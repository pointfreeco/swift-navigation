import UIKitNavigation

@MainActor
@Perceptible
class AppModel {
//  var path: [Path] = []
  var path = UINavigationPath()
  init() {
    self.path = path
  }

  enum Path: Hashable {
    case collection(CollectionModel)
    case counter(CounterModel)
    case form(FormModel)
  }
}
