#if CasePaths
  public import CasePaths

  extension UIBinding {
    /// Returns a binding to the associated value of a given case key path.
    ///
    /// - Parameter keyPath: A case key path to a specific associated value.
    /// - Returns: A new binding.
    @_disfavoredOverload
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member>>
    ) -> UIBinding<Member>?
    where Value: CasePathable {
      func open(_ location: some _UIBinding<Value>) -> UIBinding<Member?> {
        UIBinding<Member?>(
          location: _UIBindingEnumToOptionalCase(base: location, keyPath: keyPath.unsafeSendable()),
          transaction: transaction
        )
      }
      return UIBinding<Member>(open(location))
    }

    /// Returns an optional binding to the associated value of a given case key path.
    ///
    /// - Parameter keyPath: A case key path to a specific associated value.
    /// - Returns: A new binding.
    public subscript<V: CasePathable, Member>(
      dynamicMember keyPath: KeyPath<V.AllCasePaths, AnyCasePath<V, Member>>
    ) -> UIBinding<Member?>
    where Value == V? {
      func open(_ location: some _UIBinding<Value>) -> UIBinding<Member?> {
        UIBinding<Member?>(
          location: _UIBindingOptionalEnumToCase(base: location, keyPath: keyPath.unsafeSendable()),
          transaction: transaction
        )
      }
      return open(location)
    }

    /// Returns a Boolean binding to a case of a given case key path with no associated value.
    ///
    /// - Parameter keyPath: A case key path to a case with no associated value.
    /// - Returns: A new binding.
    public subscript<V: CasePathable>(
      dynamicMember keyPath: KeyPath<V.AllCasePaths, AnyCasePath<V, Void>>
    ) -> UIBinding<Bool>
    where Value == V? {
      UIBinding<Bool>(self[dynamicMember: keyPath])
    }
  }

  private final class _UIBindingEnumToOptionalCase<Base: _UIBinding, Case>: _UIBinding
  where Base.Value: CasePathable {
    let base: Base
    let keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
    let casePath: AnyCasePath<Base.Value, Case>
    init(
      base: Base, keyPath: _SendableKeyPath<Base.Value.AllCasePaths, AnyCasePath<Base.Value, Case>>
    ) {
      self.base = base
      self.keyPath = keyPath
      self.casePath = Base.Value.allCasePaths[keyPath: keyPath]
    }
    var wrappedValue: Case? {
      get {
        casePath.extract(from: base.wrappedValue)
      }
      set {
        guard let newValue, casePath.extract(from: base.wrappedValue) != nil
        else { return }
        base.wrappedValue = casePath.embed(newValue)
      }
    }
    static func == (lhs: _UIBindingEnumToOptionalCase, rhs: _UIBindingEnumToOptionalCase) -> Bool {
      lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
    }
    func hash(into hasher: inout Hasher) {
      hasher.combine(base)
      hasher.combine(keyPath)
    }
  }

  private final class _UIBindingOptionalEnumToCase<
    Base: _UIBinding<Enum?>, Enum: CasePathable, Case
  >: _UIBinding {
    let base: Base
    let keyPath: _SendableKeyPath<Enum.AllCasePaths, AnyCasePath<Enum, Case>>
    let casePath: AnyCasePath<Enum, Case>
    init(base: Base, keyPath: _SendableKeyPath<Enum.AllCasePaths, AnyCasePath<Enum, Case>>) {
      self.base = base
      self.keyPath = keyPath
      self.casePath = Enum.allCasePaths[keyPath: keyPath]
    }
    var wrappedValue: Case? {
      get {
        base.wrappedValue.flatMap(casePath.extract(from:))
      }
      set {
        guard base.wrappedValue.flatMap(casePath.extract(from:)) != nil
        else { return }
        base.wrappedValue = newValue.map(casePath.embed)
      }
    }
    static func == (lhs: _UIBindingOptionalEnumToCase, rhs: _UIBindingOptionalEnumToCase) -> Bool {
      lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
    }
    func hash(into hasher: inout Hasher) {
      hasher.combine(base)
      hasher.combine(keyPath)
    }
  }
#endif
