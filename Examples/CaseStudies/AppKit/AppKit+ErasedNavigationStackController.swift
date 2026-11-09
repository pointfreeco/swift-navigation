#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation
import AppKitPlus

final class ErasedNavigationStackController: NavigationStackController, AppKitCaseStudy {
  let caseStudyTitle = "Type-erased path"
  let readMe = """
  This case study drives a 'NavigationStackController' with the type-erased 'UINavigationPath', \
  so the stack can hold data of different types: here a number, a string and a Boolean, each \
  shown by a destination of its own.
  """
  private var model: Model!

  convenience init(model: Model) {
    @UIBindable var model = model
    self.init(path: $model.path) {
      ErasedRootViewController()
    }
    self.model = model
  }

  @Observable
  class Model {
    var path = UINavigationPath()
  }
}

/// The bottom of the stack, which registers a destination for each type of data on the path.
private final class ErasedRootViewController: XiblessViewController<NSView> {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Type-erased path"

    navigationDestination(for: Int.self) { number in
      ErasedFeatureViewController(title: "Number \(number)")
    }
    navigationDestination(for: String.self) { string in
      ErasedFeatureViewController(title: "String \"\(string)\"")
    }
    navigationDestination(for: Bool.self) { value in
      ErasedFeatureViewController(title: "Boolean \(value)")
    }

    addColumn(
      of: [
        makeButton("Push a number") { [weak self] in
          self?.traitCollection.push(value: Int.random(in: 1...1_000))
        },
        makeButton("Push a number → a string → a Boolean") { [weak self] in
          self?.traitCollection.push(value: Int.random(in: 1...1_000))
          self?.traitCollection.push(value: "Hello!")
          self?.traitCollection.push(value: Bool.random())
        },
      ],
      to: view
    )
  }
}

/// A screen on the stack: it can push data of any of the three types, or dismiss itself.
private final class ErasedFeatureViewController: XiblessViewController<NSView> {
  init(title: String) {
    super.init(nibName: nil, bundle: nil)
    self.title = title
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addColumn(
      of: [
        makeSectionLabel(title ?? ""),
        makeButton("Push a number") { [weak self] in
          self?.traitCollection.push(value: Int.random(in: 1...1_000))
        },
        makeButton("Push a string") { [weak self] in
          self?.traitCollection.push(value: "Hello!")
        },
        makeButton("Push a Boolean") { [weak self] in
          self?.traitCollection.push(value: Bool.random())
        },
        makeButton("Dismiss") { [weak self] in
          self?.traitCollection.dismiss()
        },
      ],
      to: view
    )
  }
}

#Preview {
  ErasedNavigationStackController(model: ErasedNavigationStackController.Model())
}
#endif
