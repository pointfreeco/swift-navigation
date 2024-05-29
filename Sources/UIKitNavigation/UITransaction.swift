#if canImport(UIKit)
  extension UITransaction {
    /// Creates a transaction and assigns its animation property.
    ///
    /// - Parameter animation: The animation to perform when the current state changes.
    public init(animation: UIAnimation? = nil) {
      self.init()
      self.animation = animation
    }

    /// The animation, if any, associated with the current state change.
    public var animation: UIAnimation? {
      get { self[AnimationKey.self] }
      set { self[AnimationKey.self] = newValue }
    }

    /// A Boolean value that indicates whether views should disable animations.
    public var disablesAnimations: Bool {
      get { self[DisablesAnimationsKey.self] }
      set { self[DisablesAnimationsKey.self] = newValue }
    }

    // TODO: `criteria: UIAnimationCompletionCriteria`?
    /// Adds a completion to run when the animations created with this transaction are all complete.
    ///
    /// The completion callback will always be fired exactly one time.
    public mutating func addAnimationCompletion(_ completion: @escaping @Sendable (Bool) -> Void) {
      animationCompletions.append(completion)
    }

    var animationCompletions: [@Sendable (Bool) -> Void] {
      get { self[AnimationCompletionsKey.self] }
      set { self[AnimationCompletionsKey.self] = newValue }
    }
  }

  private enum AnimationKey: UITransactionKey {
    static let defaultValue: UIAnimation? = nil
  }

  private enum AnimationCompletionsKey: UITransactionKey {
    static let defaultValue: [@Sendable (Bool) -> Void] = []
  }

  private enum DisablesAnimationsKey: UITransactionKey {
    static let defaultValue = false
  }
#endif
