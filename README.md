# SwiftUI Navigation

[![CI](https://github.com/pointfreeco/swiftui-navigation/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swiftui-navigation/actions/workflows/ci.yml)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](http://pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswiftui-navigation%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swiftui-navigation)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswiftui-navigation%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swiftui-navigation)

Tools for making SwiftUI navigation simpler, more ergonomic and more precise.

  * [Overview](#overview)
  * [Examples](#examples)
  * [Learn more](#learn-more)
  * [Community](#community)
  * [Installation](#installation)
  * [Documentation](#documentation)
  * [License](#license)

## Overview

SwiftUI comes with many forms of navigation (tabs, alerts, dialogs, modal sheets, popovers, 
navigation links, and more), and each comes with a few ways to construct them. These ways roughly 
fall in two categories:

  * "Fire-and-forget": These are initializers and methods that do not take binding arguments, which 
  means SwiftUI fully manages navigation state internally. This makes it easy to get something on 
  the screen quickly, but you also have no programmatic control over the navigation. Examples of 
  this are the initializers on [`TabView`][TabView.init] and [`NavigationLink`][NavigationLink.init] 
  that do not take a binding.

  * "State-driven": Most other initializers and methods do take a binding, which means you can 
  mutate state in your domain to tell SwiftUI when it should activate or deactivate navigation. 
  Using these APIs is more complicated than the "fire-and-forget" style, but doing so instantly
  gives you the ability to deep-link into any state of your application by just constructing a 
  piece of data, handing it to a SwiftUI view, and letting SwiftUI handle the rest.

Navigation that is "state-driven" is the more powerful form of navigation, albeit slightly more 
complicated. Unfortunately, SwiftUI does not ship with all of the tools necessary to model our domains with 
enums and make use of navigation APIs. This library bridges that gap by providing APIs that allow
you to model your navigation destinations as an enum, and then drive navigation by a binding
to that enum.

Explore all of the tools this library comes with by checking out the [documentation][docs], and
reading these articles:

* **[What is navigation?][what-is-article]**:
  Learn how one can think of navigation as a domain modeling problem, and how that leads to the
  creation of concise and testable APIs for navigation.

* **[Navigation links and destinations][nav-links-dests-article]**:
  Learn how to drive navigation in NavigationView and NavigationStack in a concise and testable 
  manner.

* **[Sheets, popovers, and covers][sheets-popovers-covers-article]**:
  Learn how to present sheets, popovers and covers in a concise and testable manner.

* **[Alerts and dialogs][alerts-dialogs-article]**:
  Learn how to present alerts and confirmation dialogs in a concise and testable manner.
  
* **[Bindings][bindings]**:
  Learn how to manage certain view state, such as `@FocusState` directly in your observable classes.
  
## Examples

This repo comes with lots of examples to demonstrate how to solve common and complex navigation 
problems with the library. Check out [this](./Examples) directory to see them all, including:

* [Case Studies](./Examples/CaseStudies)
  * Alerts & Confirmation Dialogs
  * Sheets & Popovers & Fullscreen Covers
  * Navigation Links
  * Routing
  * Custom Components
* [Inventory](./Examples/Inventory): A multi-screen application with lists, sheets, popovers and 
alerts, all driven by state and deep-linkable.

## Learn More

SwiftUI Navigation's tools were motivated and designed over the course of many episodes on [Point-Free](https://www.pointfree.co), a video series exploring functional programming and the 
Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and [Stephen Celis](https://twitter.com/stephencelis).

You can watch all of the episodes [here](https://www.pointfree.co/collections/swiftui/navigation).

<a href="https://www.pointfree.co/collections/swiftui/navigation">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0211.jpeg" width="600">
</a>

## Community

If you want to discuss this library or have a question about how to use it to solve 
a particular problem, there are a number of places you can discuss with fellow 
[Point-Free](http://www.pointfree.co) enthusiasts:

* For long-form discussions, we recommend the [discussions](http://github.com/pointfreeco/swiftui-navigation/discussions) tab of this repo.
* For casual chat, we recommend the [Point-Free Community slack](http://pointfree.co/slack-invite).

## Installation

You can add SwiftUI Navigation to an Xcode project by adding it as a package dependency.

> https://github.com/pointfreeco/swiftui-navigation

If you want to use SwiftUI Navigation in a [SwiftPM](https://swift.org/package-manager/) project, 
it's as simple as adding it to a `dependencies` clause in your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "1.0.0")
]
```

## Documentation

The latest documentation for the SwiftUI Navigation APIs is available [here](http://pointfreeco.github.io/swiftui-navigation/main/documentation/swiftuinavigation/).

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[NavigationLink.init]: https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:label:)-27n7s
[TabView.init]: https://developer.apple.com/documentation/swiftui/tabview/init(content:)
[case-paths-gh]: https://github.com/pointfreeco/swift-case-paths
[what-is-article]: https://pointfreeco.github.io/swiftui-navigation/main/documentation/swiftuinavigation/whatisnavigation
[nav-links-dests-article]: https://pointfreeco.github.io/swiftui-navigation/main/documentation/swiftuinavigation/navigation
[sheets-popovers-covers-article]: https://pointfreeco.github.io/swiftui-navigation/main/documentation/swiftuinavigation/sheetspopoverscovers
[alerts-dialogs-article]: https://pointfreeco.github.io/swiftui-navigation/main/documentation/swiftuinavigation/alertsdialogs
[bindings]: https://pointfreeco.github.io/swiftui-navigation/main/documentation/swiftuinavigation/bindings
[docs]: https://pointfreeco.github.io/swiftui-navigation/main/documentation/swiftuinavigation/
