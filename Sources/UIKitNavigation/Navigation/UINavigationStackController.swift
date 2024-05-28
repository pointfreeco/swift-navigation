#if canImport(UIKit)
  import UIKit

  // TODO: Should this be `NavigationStackController`?
  public class UINavigationStackController: UINavigationController {
    private var destinations: [DestinationType: (Any) -> UIViewController] = [:]
    fileprivate var path = UIBinding<any RandomAccessCollection & RangeReplaceableCollection>(
      UIBindable(DefaultPath()).elements
    )
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
      self.path = UIBinding(path)
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
      self.path = UIBinding<any RandomAccessCollection & RangeReplaceableCollection>(path.elements)
      self.root = root()
    }

    public func navigationDestination<D: Hashable>(
      for data: D.Type,
      destination: @escaping (D) -> UIViewController
    ) {
      destinations[DestinationType(data)] = { destination($0 as! D) }
      if path.wrappedValue.contains(where: { $0 is D }) {
        path.wrappedValue = path.wrappedValue
      }
    }

    public override func viewDidLoad() {
      super.viewDidLoad()

      super.delegate = pathDelegate

      observe { [weak self] in
        guard let self else { return }

        let newPath = path.wrappedValue

        let difference = newPath.map { $0 as! AnyHashable }
          .difference(from: viewControllers.compactMap(\.navigationID))

        if difference.isEmpty {
          return
        } else if difference.count == 1,
          case let .insert(newPath.count, navigationID, nil) = difference.first,
          let viewController = viewController(for: navigationID)
        {
          pushViewController(viewController, animated: UIView.areAnimationsEnabled)
        } else if difference.count == 1,
          case .remove(newPath.count, _, nil) = difference.first
        {
          popViewController(animated: UIView.areAnimationsEnabled)
        } else if difference.insertions.isEmpty, newPath.isEmpty {
          popToRootViewController(animated: UIView.areAnimationsEnabled)
        } else if difference.insertions.isEmpty,
          case let offsets = difference.removals.map(\.offset),
          let first = offsets.first,
          let last = offsets.last,
          offsets.elementsEqual(first...last),
          first == newPath.count
        {
          popToViewController(
            viewControllers[first - 1], animated: UIView.areAnimationsEnabled
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
              guard navigationID == newPath.first as! AnyHashable
              else { break loop }
              newPath.removeFirst()
            } else {
              newViewControllers.append(viewController)
            }
          }
          for navigationID in newPath {
            let navigationID = navigationID as! AnyHashable
            if let viewController = viewControllers.first(where: { $0.navigationID == navigationID }
            ) {
              newViewControllers.append(viewController)
            } else if let viewController = viewController(for: navigationID) {
              newViewControllers.append(viewController)
            } else {
              // TODO: runtimeWarn
            }
          }
          setViewControllers(newViewControllers, animated: UIView.areAnimationsEnabled)
        }
      }
    }

    fileprivate func viewController(for navigationID: AnyHashable) -> UIViewController? {
      guard let destination = destinations[DestinationType(type(of: navigationID.base))] else {
        // TODO: runtimeWarn
        return nil
      }
      let viewController = destination(navigationID)
      viewController.navigationID = navigationID
      if #available(macOS 14, iOS 17, watchOS 10, tvOS 17, *) {
        viewController.traitOverrides
          .dismiss = UIDismissAction { [weak self, weak viewController] in
            guard let self, let viewController else { return }
            popFromViewController(viewController, animated: UIView.areAnimationsEnabled)
          }
      }
      return viewController
    }

    private struct DestinationType: Hashable {
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
      weak var base: (any UINavigationControllerDelegate)?
      let viewController = UIViewController()

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
        let navigationController = navigationController as! UINavigationStackController
        let oldPath = navigationController.path.wrappedValue
        let newPath = navigationController.viewControllers.map(\.navigationID)
        if oldPath.count > newPath.count {
          navigationController.path.wrappedValue = newPath
        }
        base?.navigationController?(
          navigationController, didShow: viewController, animated: animated
        )
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
    // TODO: Should this be `pushValue(_:)`?
    public func push<Element: Hashable>(value: Element) {
      guard let stackController = self as? UINavigationStackController
      else {
        // TODO: runtimeWarn?
        return
      }
      func open<P: RandomAccessCollection & RangeReplaceableCollection>(_ path: inout P) {
        path.append(value as! P.Element)
      }
      open(&stackController.path.wrappedValue)
    }
  }

  @Perceptible
  private final class DefaultPath {
    var elements: [AnyHashable] = []
  }

  extension UIViewController {
    fileprivate var navigationID: AnyHashable? {
      get {
        objc_getAssociatedObject(self, navigationIDKey) as? AnyHashable
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
#endif
