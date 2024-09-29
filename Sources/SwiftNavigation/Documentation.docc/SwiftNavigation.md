# ``SwiftNavigation``

Bringing simple and powerful navigation tools to all Swift platforms, inspired by SwiftUI.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swift-navigation)
- [Discussions](https://github.com/pointfreeco/swift-navigation/discussions)
- [Point-Free Videos](https://www.pointfree.co/)

## Overview

This library contains a suite of tools that form the foundation for building powerful state
management and navigation APIs for Apple platforms, such as SwiftUI, UIKit, and AppKit, as well as
for non-Apple platforms, such as Windows, Linux, Wasm, and more.

The SwiftNavigation library forms the foundation that more advanced tools can be built upon, such
as the UIKitNavigation and SwiftUINavigation libraries. There are two primary tools provided:

* ``observe(isolation:_:)-9xf99``: Minimally observe changes in a model.
* ``UIBinding``: Two-way binding for connecting navigation and UI components to an observable model.

In addition to these tools there are some supplementary concepts that allow you to build more 
powerful tools, such as ``UITransaction``, which associates animations and other data with state
changes, and ``UINavigationPath``, which is a type-erased stack of data that helps in describing
stack-based navigation.

All of these tools form the foundation for how one can build more powerful and robust tools for
SwiftUI, UIKit, AppKit, and even non-Apple platforms.

## Topics

### Essentials

- <doc:WhatIsNavigation>

### Observing changes to state

- ``observe(isolation:_:)-9xf99``
- ``ObjectiveC/NSObject/observe(_:)-94oxy``
- ``ObserveToken``

### Creating and sharing state

- ``UIBindable``
- ``UIBinding``

### Attaching data to mutations

- ``withUITransaction(_:_:)``
- ``withUITransaction(_:_:_:)``
- ``UITransaction``
- ``UITransactionKey``

### Stack-based navigation

- ``UINavigationPath``
- ``HashableObject``

### UI state

- ``TextState``
- ``AlertState``
- ``ConfirmationDialogState``
- ``ButtonState``
