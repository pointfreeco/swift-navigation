#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import MachO
  import ObjectiveC
  import Testing

  /// A method the library adds to a class it does not own replaces whatever method that class has,
  /// or gains in a later release, under the same selector — silently, for every instance in the
  /// app. An unprefixed `textViewDidChangeSelection:` added to `NSTextField` once broke the
  /// selection handling of every text field that way. Carrying the library's name in every such
  /// selector keeps the two apart.
  // NB: On the main actor because naming an AppKit class from Swift runs its '+initialize' on
  //     the calling thread. Doing that for 'NSView' on a background thread, while other tests run
  //     in parallel, left AppKit tied to the wrong thread: event handling on the main thread then
  //     trapped, and open panels raised "already on an AppKit thread".
  @MainActor
  @Suite struct ObjectiveCMethodNamingTests {
    @Test("every Objective-C method the library adds to a system class carries its name")
    func methodsAddedToSystemClassesCarryTheLibraryName() throws {
      let addedMethods = try Self.methodsImplementedInThisBinary(
        inClassesFromImagesOf: [NSView.self, NotificationCenter.self, NSObject.self]
      )
      // NB: The library is linked into the test binary. Should that change, the scan would find
      //     nothing and pass for the wrong reason.
      try #require(
        addedMethods.contains("-[NSViewController _AppKitNavigation_hasViewAppeared]"),
        "The scan must find the library's own methods"
      )

      let unnamedMethods = addedMethods.filter { method in
        !method.localizedCaseInsensitiveContains("AppKitNavigation")
          && !Self.deliberatelyReplacedMethods.contains(method)
      }

      #expect(unnamedMethods.isEmpty, "Methods without the library's name: \(unnamedMethods)")
    }

    /// The methods the library replaces on purpose: the shim exchanges its own implementations in
    /// for these, to learn when a view controller appears, disappears or is dismissed, and what
    /// the user confirmed in a save panel.
    private static let deliberatelyReplacedMethods: Set<String> = [
      "-[NSViewController viewDidAppear]",
      "-[NSViewController viewDidDisappear]",
      "-[NSViewController dismissViewController:]",
      "-[NSSavePanel setFinalURL:]",
      "-[NSSavePanel setFinalURLs:]",
    ]

    /// Every method of the classes defined in the given classes' images whose implementation
    /// lives in this test binary, formatted the way Objective-C prints a method.
    private static func methodsImplementedInThisBinary(
      inClassesFromImagesOf representativeClasses: [AnyClass]
    ) throws -> [String] {
      let codeRange = try codeRangeOfThisBinary()
      var methodDescriptions: [String] = []
      for representativeClass in representativeClasses {
        let imageName = try #require(class_getImageName(representativeClass))
        var classCount: UInt32 = 0
        let classNames = try #require(objc_copyClassNamesForImage(imageName, &classCount))
        defer { free(classNames) }
        for classIndex in 0..<Int(classCount) {
          guard let systemClass = objc_lookUpClass(classNames[classIndex]) else { continue }
          let className = String(cString: classNames[classIndex])
          methodDescriptions += methods(
            of: systemClass, implementedIn: codeRange, prefix: "-", className: className
          )
          if let metaclass = object_getClass(systemClass) {
            methodDescriptions += methods(
              of: metaclass, implementedIn: codeRange, prefix: "+", className: className
            )
          }
        }
      }
      return methodDescriptions.sorted()
    }

    private static func methods(
      of methodOwner: AnyClass, implementedIn codeRange: Range<UInt>, prefix: String,
      className: String
    ) -> [String] {
      var methodCount: UInt32 = 0
      guard let methodList = class_copyMethodList(methodOwner, &methodCount) else { return [] }
      defer { free(methodList) }
      var methodDescriptions: [String] = []
      for methodIndex in 0..<Int(methodCount) {
        let method = methodList[methodIndex]
        guard codeRange.contains(UInt(bitPattern: method_getImplementation(method))) else {
          continue
        }
        let selectorName = String(cString: sel_getName(method_getName(method)))
        methodDescriptions.append("\(prefix)[\(className) \(selectorName)]")
      }
      return methodDescriptions
    }

    /// Where this binary's code is loaded. Comparing addresses against it is much faster than
    /// asking 'dladdr' about each of the system's tens of thousands of methods.
    private static func codeRangeOfThisBinary() throws -> Range<UInt> {
      let header = #dsohandle.assumingMemoryBound(to: mach_header_64.self)
      var codeSize: UInt = 0
      let codeStart = UInt(bitPattern: try #require(getsegmentdata(header, "__TEXT", &codeSize)))
      return codeStart..<(codeStart + codeSize)
    }
  }
#endif
