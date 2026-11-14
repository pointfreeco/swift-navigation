#if canImport(AppKit) && !targetEnvironment(macCatalyst)

extension UIBinding where Value: Equatable {
  /// A binding to the position of this binding's value among some options.
  ///
  /// The position is `-1` when the value is not one of the options. Writing a position chooses
  /// the option there; writing one that matches no option is reported and changes nothing.
  func optionIndex(
    among options: [Value],
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) -> UIBinding<Int> {
    optionIndex(among: { options }, fileID: fileID, filePath: filePath, line: line, column: column)
  }

  /// A binding to the position of this binding's value among options that are read again each
  /// time.
  ///
  /// Reading the position reads the options, so an observation that reads the position also
  /// tracks whatever the options read.
  func optionIndex(
    among options: @escaping () -> [Value],
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) -> UIBinding<Int> {
    self[
      indexAmong: KeyPathArgument(options),
      fileID: HashableStaticString(rawValue: fileID),
      filePath: HashableStaticString(rawValue: filePath),
      line: line,
      column: column
    ]
  }
}

extension Equatable {
  fileprivate subscript(
    indexAmong options: KeyPathArgument<() -> [Self]>,
    fileID fileID: HashableStaticString,
    filePath filePath: HashableStaticString,
    line line: UInt,
    column column: UInt
  ) -> Int {
    get { options.value().firstIndex(of: self) ?? -1 }
    set {
      let currentOptions = options.value()
      guard currentOptions.indices.contains(newValue)
      else {
        reportIssue(
          """
          A selection binding was given position \(newValue), which matches none of its \
          \(currentOptions.count) options.
          """,
          fileID: fileID.rawValue,
          filePath: filePath.rawValue,
          line: line,
          column: column
        )
        return
      }
      self = currentOptions[newValue]
    }
  }
}

#endif
