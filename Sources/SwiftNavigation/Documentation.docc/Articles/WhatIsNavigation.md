# What is navigation?

Learn how one can think of navigation as a domain modeling problem, and how that leads to the
creation of concise and testable APIs for navigation.

## Overview

We will define navigation as a "mode" change in an application. The most prototypical example of
this is the drill-down. A user taps a button, and a right-to-left animation transitions you from the
current screen to the next screen.

> Important: Everything that follows is mostly focused on SwiftUI and UIKit navigation, but the 
ideas apply to other platforms too, such as Windows, Linux, Wasm, and more.

But there are many more examples of navigation beyond stacks and links. Modals can be thought of as
navigation, too. A sheet can slide from bottom-to-top and transition you from the current screen to
a new screen. A full-screen cover can further take over the entire screen. Or a popover can
partially take over the screen.

Alerts and confirmation dialogs can also be thought of navigation as they are also modals that take
full control over the interface and force you to make a selection.

It's even possible for you to define your own notions of navigation, such as menus, toast
notifications, and more.

## State-driven navigation

All of these seemingly disparate examples of navigation can be unified under a single API.
Presentation and dismissal can be described with an optional piece of state:

  * When the state changes from `nil` to non-`nil`, a screen can be presented, whether that be
    _via_ a drill-down, modal, _etc._
  * And when the state changes from non-`nil` to `nil`, a screen can be dismissed.

Driving navigation from state like this can be incredibly powerful:

  * It guarantees that your model will always be in sync with the visual representation of the UI.
    It shouldn't be possible for a piece of state to be non-`nil` and not have the corresponding
    view present.
  * It easily enables deep linking capabilities. If all forms of navigation in your application are
    driven off of state, then you can instantly open your application into any state imaginable by
    simply constructing a piece of data, handing it to SwiftUI, and letting it do its thing.
  * It also allows you to write unit tests for navigation logic without resorting to UI tests, which
    can be slow, flakey, and introduce instability into your test suite. If you write a unit test
    showing that when a user performs an action that a piece of state went from `nil` to non-`nil`,
    then you can be assured that the user would be navigated to the next screen.
  * And finally, it is a platform agnostic way to think about application design. Nothing discussed
    above is SwiftUI-specific. These ideas apply to all view paradigms (SwiftUI, UIKit, AppKit, 
    etc.), and all platforms (Windows, Linux, Wasm, etc.).

This is why state-driven navigation is so great, and SwiftUI does a pretty great job at providing
these tools. However, there are ways to improve SwiftUI's tools, _and_ its possible to bring
state-driven tools to other Apple frameworks such as UIKit and AppKit, and even to other non-Apple
_platforms_, such as Windows, Linux, Wasm, and more.
