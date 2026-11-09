# ``AppKitNavigation``

Tools for making AppKit navigation simpler, more ergonomic and more precise.

## Overview

AppKitNavigation drives AppKit from observable models. Controls bind to a model's state in both
directions: they show its value and write the user's changes back. Sheets, modal windows and
popovers follow optional state: they are presented when it gains a value, dismissed when it becomes
`nil`, and write `nil` back when the user dismisses them. Their `onDismiss` closures run once for
each presentation, after it has left the screen, however it ended.

### Observing from a view or view controller

`observe` called on an object keeps its observation for as long as the object lives, and never
calls the closure again once the object is gone. So the closure can capture the object `unowned`,
which keeps `self` implicit inside it:

```swift
override func viewDidLoad() {
  super.viewDidLoad()

  observe { [unowned self] in
    titleLabel.stringValue = model.title
    saveButton.isEnabled = model.canSave
  }
}
```

This holds as long as only the object keeps the token that `observe` returns, which is the case
when you ignore the token or store it in one of the object's own properties. If you hand the token
to something that can outlive the object, capture the object `weak` instead.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swift-navigation)
- [Discussions](https://github.com/pointfreeco/swift-navigation/discussions)
- [Point-Free Videos](https://www.pointfree.co/collections/ukit)

## Topics

### Animations

- ``withAppKitAnimation(_:_:completion:)``
- ``AppKitAnimation``
- ``SwiftNavigation/UIBinding``
- ``SwiftNavigation/UITransaction``

### Xcode previews

- ``NSViewRepresenting``
- ``NSViewControllerRepresenting``

### Binding controls to state

- ``TargetActionProtocol``
- ``AppKit/NSControl``
- ``AppKit/NSTextField``
- ``AppKitTextSelection``
- ``AppKit/NSButton``
- ``AppKit/NSSwitch``
- ``AppKit/NSSlider``
- ``AppKit/NSStepper``
- ``AppKit/NSDatePicker``
- ``AppKit/NSColorWell``
- ``AppKit/NSPathControl``
- ``AppKit/NSPopUpButton``
- ``AppKit/NSSegmentedControl``
- ``AppKit/NSProgressIndicator``
- ``AppKit/NSTableView``
- ``AppKit/NSOutlineView``
- ``AppKit/NSMenuItem``
- ``AppKit/NSSplitViewItem``
- ``AppKit/NSTabViewController``
- ``AppKit/NSColorPanel``
- ``AppKit/NSFontManager``
- ``AppKit/NSSavePanel``
- ``AppKit/NSOpenPanel``

### Presenting content from state

- ``WindowBackedContent``
- ``AppKit/NSViewController``
- ``AppKit/NSWindow``
- ``AppKit/NSView``
- ``AppKit/NSToolbarItem``
- ``ObjectiveC/NSObject``
- ``AppKit/NSAlert``
