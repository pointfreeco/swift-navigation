#if canImport(UIKit)
  import UIKit
  @_spi(Internals) import SwiftNavigation
  @_spi(RuntimeWarn) import SwiftUINavigationCore

  public class NavigationStackController: UINavigationController {
    fileprivate var destinations:
      [DestinationType: (UINavigationPath.Element) -> UIViewController?] =
        [:]
    @UIBinding fileprivate var path: [UINavigationPath.Element] = []
    private let pathDelegate = PathDelegate()
    private var root: UIViewController?

    public override weak var delegate: (any UINavigationControllerDelegate)? {
      get { pathDelegate.base }
      set { pathDelegate.base = newValue }
    }

    public convenience init<Data: RandomAccessCollection & RangeReplaceableCollection>(
      navigationBarClass: AnyClass? = nil,
      toolbarClass: AnyClass? = nil,
      path: UIBinding<Data>,
      // TODO: Should this be `rootViewController`?
      root: () -> UIViewController
    ) where Data.Element: Hashable {
      self.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
      self._path = path.path
      self.root = root()
    }

    public convenience init(
      navigationBarClass: AnyClass? = nil,
      toolbarClass: AnyClass? = nil,
      path: UIBinding<UINavigationPath>,
      // TODO: Should this be `rootViewController`?
      root: () -> UIViewController
    ) {
      self.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
      self._path = path.elements
      self.root = root()
    }

    public override func viewDidLoad() {
      super.viewDidLoad()

      super.delegate = pathDelegate

      observe { [weak self] transaction in
        guard let self else { return }

        let newPath = path

        let difference = newPath.difference(from: viewControllers.compactMap(\.navigationID))

        guard !difference.isEmpty else {
          if viewControllers.isEmpty, let root {
            setViewControllers([root], animated: true)
          }
          return
        }

        if difference.count == 1,
          case let .insert(newPath.count - 1, navigationID, nil) = difference.first,
          let viewController = viewController(for: navigationID)
        {
          pushViewController(viewController, animated: !transaction.disablesAnimations)
        } else if difference.count == 1,
          case .remove(newPath.count, _, nil) = difference.first
        {
          popViewController(animated: transaction.disablesAnimations)
        } else if difference.insertions.isEmpty, newPath.isEmpty {
          popToRootViewController(animated: transaction.disablesAnimations)
        } else if difference.insertions.isEmpty,
          case let offsets = difference.removals.map(\.offset),
          let first = offsets.first,
          let last = offsets.last,
          offsets.elementsEqual(first...last),
          first == newPath.count
        {
          popToViewController(
            viewControllers[first], animated: !transaction.disablesAnimations
          )
        } else {
          var newPath = newPath
          let oldViewControllers =
            viewControllers.isEmpty
            ? root.map { [$0] } ?? []
            : viewControllers
          var newViewControllers: [UIViewController] = []
          newViewControllers.reserveCapacity(max(viewControllers.count, newPath.count))

          loop: for viewController in oldViewControllers {
            if let navigationID = viewController.navigationID {
              guard navigationID == newPath.first
              else {
                break loop
              }
              newViewControllers.append(viewController)
              newPath.removeFirst()
            } else {
              newViewControllers.append(viewController)
            }
          }
          var invalidIndices = IndexSet()
          for (index, navigationID) in newPath.enumerated() {
            if let viewController = viewControllers.first(where: { $0.navigationID == navigationID }
            ) {
              newViewControllers.append(viewController)
            } else if let viewController = viewController(for: navigationID) {
              newViewControllers.append(viewController)
            } else if case .eager = navigationID, let elementType = navigationID.elementType {
              runtimeWarn(
                """
                No "navigationDestination(for: \(String(customDumping: elementType))) { … }" was \
                found among the view controllers on the path.
                """
              )
              invalidIndices.insert(index)
            }
          }
          path.remove(atOffsets: invalidIndices)
          setViewControllers(newViewControllers, animated: !transaction.disablesAnimations)
        }
      }
    }

    fileprivate func viewController(
      for navigationID: UINavigationPath.Element
    ) -> UIViewController? {
      guard
        let destinationType = navigationID.elementType,
        let destination = destinations[DestinationType(destinationType)],
        let viewController = destination(navigationID)
      else {
        return nil
      }
      viewController.navigationID = navigationID
      if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
        viewController.traitOverrides
          .dismiss = UIDismissAction { [weak self, weak viewController] transaction in
            guard let self, let viewController else { return }
            popFromViewController(viewController, animated: !transaction.disablesAnimations)
          }
      }
      return viewController
    }

    fileprivate struct DestinationType: Hashable {
      let rawValue: Any.Type
      init(_ rawValue: Any.Type) {
        self.rawValue = rawValue
      }
      static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
      }
      func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(rawValue))
      }
    }

    private final class PathDelegate: NSObject, UINavigationControllerDelegate {
      let viewController = UIViewController()
      weak var base: (any UINavigationControllerDelegate)?

      func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
      ) {
        base?.navigationController?(
          navigationController, willShow: viewController, animated: animated
        )
      }

      func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
      ) {
        defer {
          base?.navigationController?(
            navigationController, didShow: viewController, animated: animated
          )
        }
        let navigationController = navigationController as! NavigationStackController
        if let nextIndex = navigationController.path.firstIndex(where: {
          guard case .lazy = $0 else { return false }
          return true
        }) {
          let nextElement = navigationController.path[nextIndex]
          let canPushElement =
            nextElement.elementType
            .map { navigationController.destinations.keys.contains(DestinationType($0)) }
            ?? false
          if !canPushElement {
            runtimeWarn(
              """
              Failed to decode item in navigation path at index \(nextIndex). Perhaps the \
              "navigationDestination" declarations have changed since the path was encoded?
              """
            )
            if let elementType = nextElement.elementType {
              runtimeWarn(
                """
                Missing navigation destination while decoding a "UINavigationPath". No \
                "navigationDestination(for: \(String(customDumping: elementType))) { … }" was \
                found among the view controllers on the path.
                """
              )
            }
            navigationController.path.removeSubrange(nextIndex...)
          }
          return
        }
        DispatchQueue.main.async {
          let oldPath = navigationController.path.filter {
            guard case .eager = $0 else { return false }
            return true
          }
          let newPath = navigationController.viewControllers.compactMap(\.navigationID)
          if oldPath.count > newPath.count {
            navigationController.path = newPath
          }
        }
      }

      func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
      ) -> UIInterfaceOrientationMask {
        base?.navigationControllerSupportedInterfaceOrientations?(navigationController)
          ?? viewController.supportedInterfaceOrientations
      }

      func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
      ) -> UIInterfaceOrientation {
        base?.navigationControllerPreferredInterfaceOrientationForPresentation?(
          navigationController
        )
          ?? viewController.preferredInterfaceOrientationForPresentation
      }

      func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
      ) -> (any UIViewControllerInteractiveTransitioning)? {
        base?.navigationController?(
          navigationController, interactionControllerFor: animationController
        )
      }

      func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
      ) -> (any UIViewControllerAnimatedTransitioning)? {
        base?.navigationController?(
          navigationController, animationControllerFor: operation, from: fromVC, to: toVC
        )
      }
    }
  }

  extension UINavigationController {
    public func push<Element: Hashable>(value: Element) {
      guard let stackController = self as? NavigationStackController
      else {
        // TODO: runtimeWarn?
        return
      }
      stackController.path.append(.eager(value))
    }

    public func navigationDestination<D: Hashable>(
      for data: D.Type,
      destination: @escaping (D) -> UIViewController
    ) {
      guard let stackController = self as? NavigationStackController
      else {
        runtimeWarn(
          """
          Applied a "navigationDestination" to a non-"NavigationStackController".
          """
        )
        return
      }

      stackController.destinations[NavigationStackController.DestinationType(data)] = {
        [weak stackController] element in
        guard let stackController else { fatalError() }

        switch element {
        case let .eager(value):
          return destination(value as! D)
        case let .lazy(value):
          let index = stackController.path.firstIndex(of: element)!
          guard let value = value.decode()
          else {
            runtimeWarn(
              """
              Failed to decode item in navigation path at index \(index). Perhaps the \
              "navigationDestination" declarations have changed since the path was encoded?
              """
            )
            stackController.path.remove(at: index)
            return nil
          }
          stackController.path[index] = .eager(value)
          return destination(value as! D)
        }
      }
      if stackController.path.contains(where: { $0.elementType == D.self }) {
        stackController.path = stackController.path
      }
    }
  }

  @Perceptible
  private final class DefaultPath {
    var elements: [AnyHashable] = []
  }

  extension UIViewController {
    fileprivate var navigationID: UINavigationPath.Element? {
      get {
        objc_getAssociatedObject(self, navigationIDKey) as? UINavigationPath.Element
      }
      set {
        objc_setAssociatedObject(
          self, navigationIDKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
      }
    }
  }

  private let navigationIDKey = malloc(1)!

  extension CollectionDifference.Change {
    fileprivate var offset: Int {
      switch self {
      case let .insert(offset, _, _):
        return offset
      case let .remove(offset, _, _):
        return offset
      }
    }
  }

  extension RangeReplaceableCollection
  where
    Self: RandomAccessCollection,
    Element: Hashable
  {
    fileprivate var path: [UINavigationPath.Element] {
      get { map { .eager($0) } }
      set {
        replaceSubrange(
          startIndex..<endIndex,
          with: newValue.map {
            guard case let .eager(element) = $0 else { fatalError() }
            return element.base as! Element
          }
        )
      }
    }
  }
#endif
