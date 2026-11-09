#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  public import AppKit
  public import AppKitPlus
  public import SwiftNavigation

  /// A navigation controller that manages a stack of view controllers, driven by a path binding.
  ///
  /// The AppKit counterpart of SwiftUI's `NavigationStack`, built on AppKitPlus's
  /// `NSNavigationController`. The path holds data, not view controllers: register how each type
  /// of data is shown with ``AppKit/NSViewController/navigationDestination(for:destination:)``,
  /// and the controller pushes and pops view controllers as the path changes.
  ///
  /// ```swift
  /// let stackController = NavigationStackController(path: $model.path) {
  ///   PlanetListViewController(model: model)
  /// }
  ///
  /// // In PlanetListViewController.viewDidLoad():
  /// navigationDestination(for: Planet.self) { planet in
  ///   PlanetViewController(planet: planet)
  /// }
  /// ```
  ///
  /// When the user goes back — with the back button, ⌘↑ or a swipe — the path loses the elements
  /// whose view controllers were popped. Pushes and pops are animated unless the change happens in
  /// a transaction that disables animations.
  ///
  /// Available with the `AppKitPlus` package trait.
  #if !Perception
    @available(macOS 14, *)
  #endif
  @MainActor
  open class NavigationStackController: NSNavigationController {
    fileprivate var destinations:
      [DestinationType: (UINavigationPath.Element) -> (NSViewController, AnyHashable)?] = [:]
    @UIBinding fileprivate var path: [UINavigationPath.Element] = []
    private let pathDelegate = PathDelegate()
    private var root: NSViewController?
    private var hasAppliedPath = false

    /// The navigation controller's delegate.
    ///
    /// The stack controller keeps a proxy in front of the delegate you set, so that it learns of the
    /// view controllers the user pops; the proxy passes every message on to your delegate. Reading
    /// this property returns the proxy.
    // NB: AppKitPlus reads its delegate through this property, so the getter has to hand it the
    //     proxy. Setting the delegate again makes AppKitPlus ask the proxy afresh which messages
    //     it answers.
    open override weak var delegate: (any NSNavigationControllerDelegate)? {
      get { super.delegate }
      set {
        pathDelegate.base = newValue
        super.delegate = nil
        super.delegate = pathDelegate
      }
    }

    /// Creates a navigation stack controller whose stack follows a collection of hashable data.
    ///
    /// - Parameters:
    ///   - navigationBarClass: A custom navigation bar class, or `nil` for the default one.
    ///   - toolbarClass: A custom toolbar class, or `nil` for the default one.
    ///   - path: A binding to the data the stack shows, above the root view controller.
    ///   - root: The view controller at the bottom of the stack.
    public required init<Data: RandomAccessCollection & RangeReplaceableCollection>(
      navigationBarClass: AnyClass? = nil,
      toolbarClass: AnyClass? = nil,
      path: UIBinding<Data>,
      root: () -> NSViewController
    ) where Data.Element: Hashable {
      super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
      super.delegate = pathDelegate
      self._path = path.path
      let root = root()
      self.root = root
      self.viewControllers = [root]
    }

    /// Creates a navigation stack controller whose stack follows a type-erased path.
    ///
    /// - Parameters:
    ///   - navigationBarClass: A custom navigation bar class, or `nil` for the default one.
    ///   - toolbarClass: A custom toolbar class, or `nil` for the default one.
    ///   - path: A binding to the path the stack shows, above the root view controller.
    ///   - root: The view controller at the bottom of the stack.
    public required init(
      navigationBarClass: AnyClass? = nil,
      toolbarClass: AnyClass? = nil,
      path: UIBinding<UINavigationPath>,
      root: () -> NSViewController
    ) {
      super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
      super.delegate = pathDelegate
      self._path = path.elements
      let root = root()
      self.root = root
      self.viewControllers = [root]
    }

    // NB: AppKitPlus's 'init(navigationBarClass:toolbarClass:)' goes through
    //     'init(nibName:bundle:)', so a subclass has to implement it. It is not for calling: a
    //     stack controller needs a path.
    @available(*, unavailable)
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
      super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    open override func viewDidLoad() {
      super.viewDidLoad()

      traitOverrides.push = AppKitPushAction { [weak self] value in
        self?._push(value: value)
      }

      observe { [weak self] transaction in
        guard let self else { return }

        // NB: The path first applies while the view loads, when there is nothing to animate from.
        let animated = hasAppliedPath && !transaction.appKit.disablesAnimations
        hasAppliedPath = true
        let newPath = path

        let difference = newPath.difference(from: viewControllers.compactMap(\.navigationID))

        guard !difference.isEmpty else {
          if viewControllers.isEmpty, let root {
            setViewControllers([root], animated: animated)
          }
          return
        }

        if difference.count == 1,
          case .insert(newPath.count - 1, let navigationID, nil) = difference.first,
          let viewController = viewController(for: navigationID)
        {
          pushViewController(viewController, animated: animated)
        } else if difference.count == 1,
          case .remove(newPath.count, _, nil) = difference.first
        {
          popViewController(animated: animated)
        } else if difference.insertions.isEmpty, newPath.isEmpty {
          popToRootViewController(animated: animated)
        } else if difference.insertions.isEmpty,
          case let offsets = difference.removals.map(\.offset),
          let first = offsets.first,
          let last = offsets.last,
          offsets.elementsEqual(first...last),
          first == newPath.count
        {
          popToViewController(viewControllers[first], animated: animated)
        } else {
          var newPath = newPath
          let oldViewControllers =
            viewControllers.isEmpty
            ? root.map { [$0] } ?? []
            : viewControllers
          var newViewControllers: [NSViewController] = []
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
          var invalidIndices: [Int] = []
          var didPushNewViewController = false
          for (index, navigationID) in newPath.enumerated() {
            if let viewController =
              viewControllers
              .first(where: { $0.navigationID == navigationID })
            {
              newViewControllers.append(viewController)
            } else if let viewController = viewController(for: navigationID) {
              newViewControllers.append(viewController)
              didPushNewViewController = true
            } else if case .lazy(.element) = navigationID,
              !didPushNewViewController,
              let elementType = navigationID.elementType
            {
              reportIssue(
                """
                No "navigationDestination(for: \(typeName(elementType))) { … }" was found among \
                the view controllers on the path.
                """
              )
              invalidIndices.append(index)
            }
          }
          for invalidIndex in invalidIndices.reversed() {
            path.remove(at: invalidIndex)
          }
          setViewControllers(newViewControllers, animated: animated)
        }
      }
    }

    fileprivate func viewController(
      for navigationID: UINavigationPath.Element
    ) -> NSViewController? {
      guard
        let destinationType = navigationID.elementType,
        let destination = destinations[DestinationType(destinationType)],
        let (viewController, element) = destination(navigationID)
      else {
        return nil
      }
      viewController.navigationID = .eager(element)
      viewController.traitOverrides.dismiss = AppKitDismissAction {
        [weak self, weak viewController] transaction in
        guard let self, let viewController else { return }
        popFromViewController(viewController, animated: !transaction.appKit.disablesAnimations)
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

    /// Stands in as the navigation controller's delegate, so that the path learns of the
    /// view controllers the user pops, and passes every message on to the delegate the app set.
    ///
    /// AppKitPlus's navigation controller has no callback for a pop the user makes; showing the
    /// view controller below is the only sign of it.
    @MainActor
    private final class PathDelegate: NSObject, NSNavigationControllerDelegate {
      // NB: Read by the Objective-C runtime's forwarding, which is not isolated. The navigation
      //     controller only messages its delegate on the main thread.
      nonisolated(unsafe) weak var base: (any NSNavigationControllerDelegate)?

      nonisolated override func responds(to selector: Selector!) -> Bool {
        selector == #selector(PathDelegate.navigationController(_:didShow:))
          || (base?.responds(to: selector) ?? false)
      }

      nonisolated override func forwardingTarget(for selector: Selector!) -> Any? {
        base
      }

      func navigationController(
        _ navigationController: NSNavigationController,
        didShow viewController: NSViewController
      ) {
        defer {
          base?.navigationController?(navigationController, didShow: viewController)
        }
        guard let navigationController = navigationController as? NavigationStackController
        else { return }
        if let nextIndex = navigationController.path.firstIndex(where: {
          guard case .lazy = $0 else { return false }
          return true
        }) {
          let nextElement = navigationController.path[nextIndex]
          let hasSeenDestinationType =
            nextElement.elementType
            .map { navigationController.destinations.keys.contains(DestinationType($0)) }
            ?? false
          guard hasSeenDestinationType
          else {
            reportIssue(
              """
              Failed to decode item in navigation path at index \(nextIndex). Perhaps the \
              "navigationDestination" declarations have changed since the path was encoded?
              """
            )
            if let elementType = nextElement.elementType {
              reportIssue(
                """
                Missing navigation destination while decoding a "UINavigationPath". No \
                "navigationDestination(for: \(typeName(elementType))) { … }" was found among the \
                view controllers on the path.
                """
              )
            }
            navigationController.path.removeSubrange(nextIndex...)
            return
          }

          switch navigationController.path[nextIndex] {
          case .lazy(.element(let element)):
            navigationController.path[nextIndex] = .eager(element)

          case .eager, .lazy(.codable):
            fallthrough

          @unknown default: break
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
    }
  }

  extension NSViewController {
    /// Pushes a value onto the current navigation stack controller's path.
    ///
    /// Outside a ``NavigationStackController``, the push is reported as an issue instead.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameter value: The value to push.
    #if !Perception
      @available(macOS 14, *)
    #endif
    public func push<Element: Hashable>(value: Element) {
      _push(value: value)
    }

    #if !Perception
      @available(macOS 14, *)
    #endif
    fileprivate func _push<Element: Hashable>(value: Element) {
      guard let navigationController = navigationController ?? self as? NSNavigationController
      else {
        reportIssue(
          """
          Can't push value: "navigationController" is "nil".
          """
        )
        return
      }
      guard let stackController = navigationController as? NavigationStackController
      else {
        reportIssue(
          """
          Tried to push a value to a non-"NavigationStackController".
          """
        )
        return
      }
      stackController.path.append(.lazy(.element(value)))
    }

    /// Registers the view controller that the enclosing ``NavigationStackController`` shows for
    /// each element of a type on its path.
    ///
    /// Call it from a view controller already in the stack, typically the root's `viewDidLoad`,
    /// or on the stack controller itself.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - data: The type of data this destination shows.
    ///   - destination: Makes the view controller for an element of the path.
    #if !Perception
      @available(macOS 14, *)
    #endif
    public func navigationDestination<Element: Hashable>(
      for data: Element.Type,
      destination: @escaping (Element) -> NSViewController
    ) {
      guard let navigationController = navigationController ?? self as? NSNavigationController
      else {
        reportIssue(
          """
          Can't register navigation destination: "navigationController" is "nil".
          """
        )
        return
      }
      guard let stackController = navigationController as? NavigationStackController
      else {
        reportIssue(
          """
          Tried to apply a "navigationDestination" to a non-"NavigationStackController".
          """
        )
        return
      }

      stackController.destinations[NavigationStackController.DestinationType(data)] = {
        [weak stackController] element in
        guard let stackController else { return nil }

        switch element {
        case .eager(let value), .lazy(.element(let value)):
          return (destination(value as! Element), value)
        case .lazy(.codable(let value)):
          let index = stackController.path.firstIndex(of: element)!
          guard let value = value.decode()
          else {
            reportIssue(
              """
              Failed to decode item in navigation path at index \(index). Perhaps the \
              "navigationDestination" declarations have changed since the path was encoded?
              """
            )
            stackController.path.remove(at: index)
            return nil
          }
          return (destination(value as! Element), value)
        @unknown default: return nil
        }
      }
      func resolvePath() {
        if stackController.path.contains(where: {
          guard case .lazy = $0, $0.elementType == Element.self else { return false }
          return true
        }) {
          stackController.path = stackController.path
        }
      }
      #if DEBUG
        skippingPerceptionChecking {
          resolvePath()
        }
      #else
        resolvePath()
      #endif
    }

    fileprivate var navigationID: UINavigationPath.Element? {
      get {
        objc_getAssociatedObject(self, navigationIDKey) as? UINavigationPath.Element
      }
      set {
        objc_setAssociatedObject(self, navigationIDKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }

  extension NSNavigationController {
    /// Pops the given view controller and everything above it.
    @discardableResult
    func popFromViewController(
      _ viewController: NSViewController, animated: Bool
    ) -> [NSViewController]? {
      guard let index = viewControllers.firstIndex(of: viewController), index != 0 else {
        return nil
      }
      return popToViewController(viewControllers[index - 1], animated: animated)
    }
  }

  @MainActor
  private let navigationIDKey = malloc(1)!

  extension CollectionDifference.Change {
    fileprivate var offset: Int {
      switch self {
      case .insert(let offset, _, _):
        return offset
      case .remove(let offset, _, _):
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
            switch $0 {
            case .eager(let element), .lazy(.element(let element)):
              return element.base as! Element
            case .lazy(.codable):
              fallthrough
            @unknown default: fatalError()
            }
          }
        )
      }
    }
  }

  private func typeName(_ type: Any.Type) -> String {
    "\(String(reflecting: type)).self"
  }
#endif
