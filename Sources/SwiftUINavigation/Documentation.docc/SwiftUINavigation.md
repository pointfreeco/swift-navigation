# ``SwiftUINavigation``

Tools for making SwiftUI navigation simpler, more ergonomic and more precise.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swiftui-navigation)
- [Discussions](https://github.com/pointfreeco/swiftui-navigation/discussions)
- [Point-Free Videos](https://www.pointfree.co/collections/swiftui/navigation)

## Overview

SwiftUI comes with many forms of navigation (tabs, alerts, dialogs, modal sheets, popovers, 
navigation links, and more), and each comes with a few ways to construct them. These ways roughly 
fall in two categories:

  * "Fire-and-forget": These are initializers and methods that do not take binding arguments, which 
    means SwiftUI fully manages navigation state internally. This makes it is easy to get something 
    on the screen quickly, but you also have no programmatic control over the navigation. Examples 
    of this are the initializers on [`TabView`][TabView.init] and 
    [`NavigationLink`][NavigationLink.init] that do not take a binding.

  * "State-driven": Most other initializers and methods do take a binding, which means you can 
    mutate state in your domain to tell SwiftUI when it should activate or deactivate navigation. 
    Using these APIs is more complicated than the "fire-and-forget" style, but doing so instantly 
    gives you the ability to deep-link into any state of your application by just constructing a 
    piece of data, handing it to a SwiftUI view, and letting SwiftUI handle the rest.

Navigation that is "state-driven" is the more powerful form of navigation, albeit slightly more 
complicated. To wield it correctly you must be able to model your domain as concisely as possible,
and this usually means using enums.

Unfortunately, SwiftUI does not ship with all of the tools necessary to model our domains with 
enums and make use of navigation APIs. This library bridges that gap by providing APIs that allow
you to model your navigation destinations as an enum, and then drive navigation by a binding
to that enum.

## Topics

### Essentials

- <doc:WhatIsNavigation>

### Tools

- <doc:Navigation>
- <doc:SheetsPopoversCovers>
- <doc:AlertsDialogs>
- <doc:DestructuringViews>
- <doc:Bindings>

## See Also

The collection of videos from [Point-Free](https://www.pointfree.co) that dive deep into the
development of the library.

* [Point-Free Videos](https://www.pointfree.co/collections/swiftui/navigation)

[NavigationLink.init]: https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:label:)-27n7s
[TabView.init]: https://developer.apple.com/documentation/swiftui/tabview/init(content:)
