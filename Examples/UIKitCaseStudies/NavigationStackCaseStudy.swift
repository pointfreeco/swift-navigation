import UIKitNavigation

@MainActor
@Perceptible
class AppModel {
  // var path: [Path] = []
  var path = UINavigationPath()

  // init(path: [Path]) {
  init(path: UINavigationPath = UINavigationPath()) {
    self.path = path
  }

  enum Path: Hashable {
    case collection(CollectionModel)
    case counter(CounterModel)
    case form(FormModel)
  }
}
