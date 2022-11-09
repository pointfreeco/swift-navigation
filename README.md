# SwiftUI Navigation

[![CI](https://github.com/pointfreeco/swiftui-navigation/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swiftui-navigation/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswiftui-navigation%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swiftui-navigation)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswiftui-navigation%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swiftui-navigation)

Tools for making SwiftUI navigation simpler, more ergonomic and more precise.

  * [Motivation](#motivation)
  * [Tools](#tools)
      * [Navigation overloads](#navigation-api-overloads)
      * [Navigation views](#navigation-views)
      * [Binding transformations](#binding-transformations)
      * [State-driven alerts and dialogs](#State-driven-alerts-and-dialogs)
  * [Examples](#examples)
  * [Learn more](#learn-more)
  * [Installation](#installation)
  * [Documentation](#documentation)
  * [License](#license)

## Motivation

SwiftUI comes with many forms of navigation (tabs, alerts, dialogs, modal sheets, popovers, navigation links, and more), and each comes with a few ways to construct them. These ways roughly fall in two categories:

  * "Fire-and-forget": These are initializers and methods that do not take binding arguments, which means SwiftUI fully manages navigation state internally. This makes it is easy to get something on the screen quickly, but you also have no programmatic control over the navigation. Examples of this are the initializers on [`TabView`][TabView.init] and [`NavigationLink`][NavigationLink.init] that do not take a binding.

    [NavigationLink.init]: https://developer.apple.com/documentation/swiftui/navigationlink/init(destination:label:)-27n7s
    [TabView.init]: https://developer.apple.com/documentation/swiftui/tabview/init(content:)

  * "State-driven": Most other initializers and methods do take a binding, which means you can mutate state in your domain to tell SwiftUI when it should activate or deactivate navigation. Using these APIs is more complicated than the "fire-and-forget" style, but doing so instantly gives you the ability to deep-link into any state of your application by just constructing a piece of data, handing it to a SwiftUI view, and letting SwiftUI handle the rest.

Navigation that is "state-driven" is the more powerful form of navigation, albeit slightly more complicated, but unfortunately SwiftUI does not ship with all the tools necessary to model our domains as concisely as possible and use these navigation APIs.

For example, to show a modal sheet in SwiftUI you can provide a binding of some optional state so that when the state flips to non-`nil` the modal is presented. However, the content closure of the sheet is handed a plain value, not a binding:

```swift
struct ContentView: View {
  @State var draft: Post?

  var body: some View {
    Button("Edit") {
      self.draft = Post()
    }
    .sheet(item: self.$draft) { (draft: Post) in
      EditPostView(post: draft)
    }
  }
}

struct EditPostView: View {
  let post: Post
  var body: some View { ... }
}
```

This means that the `Post` handed to the `EditPostView` is fully disconnected from the source of truth `draft` that powers the presentation of the modal. Ideally we should be able to derive a `Binding<Post>` for the draft so that any mutations `EditPostView` makes will be instantly visible in `ContentView`.

Another problem arises when trying to model multiple navigation destinations as multiple optional values. For example, suppose there are 3 different sheets that can be shown in a screen:

```swift
struct ContentView: View {
  @State var draft: Post?
  @State var settings: Settings?
  @State var userProfile: UserProfile?

  var body: some View {
    /* Main view omitted */

    .sheet(item: self.$draft) { (draft: Post) in
      EditPostView(post: draft)
    }
    .sheet(item: self.$settings) { (settings: Settings) in
      SettingsView(settings: settings)
    }
    .sheet(item: self.$userProfile) { (userProfile: Profile) in
      UserProfile(profile: userProfile)
    }
  }
}
```

This forces us to hold 3 optional values in state, which has 2^3=8 different states, 4 of which are invalid. The only valid states is for all values to be `nil` or exactly one be non-`nil`. It makes no sense if two or more values are non-`nil`, for that would representing wanting to show two modal sheets at the same time.

Ideally we'd like to represent these navigation destinations as 3 mutually exclusive states so that we could guarantee at compile time that only one can be active at a time. Luckily for us Swift’s enums are perfect for this:

```swift
enum Route {
  case draft(Post)
  case settings(Settings)
  case userProfile(Profile)
}
```

And then we could hold an optional `Route` in state to represent that we are either navigating to a specific destination or we are not navigating anywhere:

```swift
@State var route: Route?
```

This would be the most optimal way to model our navigation domain, but unfortunately SwiftUI's tools do not make easy for us to drive navigation off of enums.

This library comes with a number of `Binding` transformations and navigation API overloads that allow you to model your domain as concisely as possible, using enums, while still allowing you to use SwiftUI's navigation tools.

For example, powering multiple modal sheets off a single `Route` enum looks like this with the tools in this library:

```swift
struct ContentView {
  @State var route: Route?

  enum Route {
    case draft(Post)
    case settings(Settings)
    case userProfile(Profile)
  }

  var body: some View {
    /* Main view omitted */

    .sheet(unwrapping: self.$route, case: /Route.draft) { $draft in
      EditPostView(post: $draft)
    }
    .sheet(unwrapping: self.$route, case: /Route.settings) { $settings in
      SettingsView(settings: $settings)
    }
    .sheet(unwrapping: self.$route, case: /Route.userProfile) { $userProfile in
      UserProfile(profile: $userProfile)
    }
  }
}
```

The forward-slash syntax you see above represents a [case path](https://github.com/pointfreeco/swift-case-paths) to a particular case of an enum. Case paths are our imagining of what key paths could look like for enums, and every concept for key paths has an analogous concept for case paths:

  * Each property of an struct is naturally endowed with a key path, and so each case of an enum is endowed with a case path.
  * Key paths are constructed using a back slash, name of the type and name of the property (_e.g._, `\User.name`), and case paths are constructed similarly, but with a forward slash (_e.g._, `/Route.draft`).
  * Key paths describe how to get and set a value in some root structure, whereas case paths describe how to extract and embed a value into a root structure.

Case paths are crucial for allowing us to build the tools to drive navigation off of enum state.

## Tools

This library comes with many tools that allow you to model your domain as concisely as possible, using enums, while still allowing you to use SwiftUI's navigation APIs.

### Navigation API overloads

This library provides additional overloads for all of SwiftUI's "state-driven" navigation APIs that allow you to activate navigation based on a particular case of an enum. Further, all overloads unify presentation in a single, consistent API:

  * `NavigationLink.init(unwrapping:case:)`
  * `View.alert(unwrapping:case:)`
  * `View.confirmationDialog(unwrapping:case:)`
  * `View.fullScreenCover(unwrapping:case:)`
  * `View.popover(unwrapping:case:)`
  * `View.sheet(unwrapping:case:)`

For example, here is how a navigation link, a modal sheet and an alert can all be driven off a single enum with 3 cases:

```swift
enum Route {
  case add(Post)
  case alert(Alert)
  case edit(Post)
}

struct ContentView {
  @State var posts: [Post]
  @State var route: Route?

  var body: some View {
    ForEach(self.posts) { post in
      NavigationLink(unwrapping: self.$route, case: /Route.edit) { isActive in 
        self.route = isActive ? .edit(post) : nil 
      } destination: { $post in 
        EditPostView(post: $post)
      } label: {
        Text(post.title)
      }
    }
    .sheet(unwrapping: self.$route, case: /Route.add) { $post in
      EditPostView(post: $post)
    }
    .alert(
      title: { Text("Delete \($0.title)?") },
      unwrapping: self.$route,
      case: /Route.alert
      actions: { post in
        Button("Delete") { self.posts.remove(post) }
      },
      message: { Text($0.summary) }
    )
  }
}

struct EditPostView: View {
  @Binding var post: Post
  var body: some View { ... }
}
```

### Navigation views

This library comes with additional SwiftUI views that transform and destructure bindings, allowing you to better handle optional and enum state:

  * `IfLet`
  * `IfCaseLet`
  * `Switch`/`CaseLet`

For example, suppose you were working on an inventory application that modeled in-stock and out-of-stock as an enum:

```swift
enum ItemStatus {
  case inStock(quantity: Int)
  case outOfStock(isOnBackorder: Bool)
}
```

If you want to conditionally show a stepper view for the quantity when in-stock and a toggle for the backorder when out-of-stock, you're out of luck when it comes to using SwiftUI's standard tools. However, the `Switch` view that comes with this library allows you to destructure a `Binding<ItemStatus>` into bindings of each case so that you can present different views:

```swift
struct InventoryItemView {
  @State var status: ItemStatus

  var body: some View {
    Switch(self.$status) {
      CaseLet(/ItemStatus.inStock) { $quantity in
        HStack {
          Text("Quantity: \(quantity)")
          Stepper("Quantity", value: $quantity)
        }
        Button("Out of stock") { self.status = .outOfStock(isOnBackorder: false) }
      }

      CaseLet(/ItemStatus.outOfStock) { $isOnBackorder in
        Toggle("Is on back order?", isOn: $isOnBackorder)
        Button("In stock") { self.status = .inStock(quantity: 1) }
      }
    }
  }
}
```

### Binding transformations

This library comes with tools that transform and destructure bindings of optional and enum state, which allows you to build your own navigation views similar to the ones that ship in this library.

  * `Binding.init(unwrapping:)`
  * `Binding.case(_:)`
  * `Binding.isPresent()` and `Binding.isPresent(_:)`

For example, suppose you have built a `BottomSheet` view for presenting a modal-like view that only takes up the bottom half of the screen. You can build the entire view using the most simplistic domain modeling where navigation is driven off a single boolean binding:

```swift
struct BottomSheet<Content>: View where Content: View {
  @Binding var isActive: Bool
  let content: () -> Content

  var body: some View {
    ...
  }
}
```

Then, additional convenience initializers can be introduced that allow the bottom sheet to be created with a more concisely modeled domain.

For example, an initializer that allows the bottom sheet to be presented and dismissed with optional state, and further the content closure is provided a binding of the non-optional state. We can accomplish this using the `isPresent()` method and `Binding.init(unwrapping:)`:

```swift
extension BottomSheet {
  init<Value, WrappedContent>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder content: @escaping (Binding<Value>) -> WrappedContent
  )
  where Content == WrappedContent?
  {
    self.init(
      isActive: value.isPresent(),
      content: { Binding(unwrapping: value).map(content) }
    )
  }
}
```

An even more robust initializer can be provided by providing a binding to an optional enum _and_ a case path to specify which case of the enum triggers navigation. This can be accomplished using the `case(_:)` method on binding:

```swift
extension BottomSheet {
  init<Enum, Case, WrappedContent>(
    unwrapping enum: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    @ViewBuilder content: @escaping (Binding<Case>) -> WrappedContent
  )
  where Content == WrappedContent?
  {
    self.init(
      unwrapping: `enum`.case(casePath),
      content: content
    )
  }
}
```

Both of these more powerful initializers are just conveniences. If the user of `BottomSheet` does not want to worry about concise domain modeling they are free to continue using the `isActive` boolean binding. But the day they need the more powerful APIs they will be available.

### State-driven alerts and dialogs

SwiftUI's alert and dialog modifiers can be configured with a lot of state that populates title, message, buttons, and even button actions. This is a lot of data that is calculated at the view layer, which makes it harder to test. This library provides data types and tools that allow you to move this logic into your model, instead.

```swift
class ItemModel: ObservableObject {
  enum AlertAction {
    case deleteButtonTapped
  }

  @Published var alert: AlertState<AlertAction>?

  // ...

  func deleteButtonTapped() {
    self.alert = AlertState(
      title: TextState(self.item.name),
      message: TextState("Are you sure you want to delete this item?"),
      buttons: [
        .destructive(
          TextState("Delete"),
          action: .send(.deleteButtonTapped)
        )
      ]
    )
  }

  func alertButtonTapped(_ action: AlertAction) {
    switch action {
    case .deleteButtonTapped:
      // ...
    }
  }
}

struct ItemView: View {
  @ObservedObject var model: ItemModel

  var body: some View {
    // ...
    Button("Delete") {
      self.model.deleteButtonTapped()
    }
    .alert(
      unwrapping: self.$model.alert,
      action: self.model.alertButtonTapped
    )
  }
}
```

## Examples

This repo comes with lots of examples to demonstrate how to solve common and complex navigation problems with the library. Check out [this](./Examples) directory to see them all, including:

* [Case Studies](./Examples/CaseStudies)
  * Alerts & Confirmation Dialogs
  * Sheets & Popovers & Fullscreen Covers
  * Navigation Links
  * Routing
  * Custom Components
* [Inventory](./Examples/Inventory): A multi-screen application with lists, sheets, popovers and alerts, all driven by state and deep-linkable.

## Learn More

SwiftUI Navigation's tools were motivated and designed over the course of many episodes on [Point-Free](https://www.pointfree.co), a video series exploring functional programming and the Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and [Stephen Celis](https://twitter.com/stephencelis).

You can watch all of the episodes [here](https://www.pointfree.co/collections/swiftui/navigation).

<a href="https://www.pointfree.co/collections/swiftui/navigation">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0166.jpeg" width="600">
</a>

## Installation

You can add SwiftUI Navigation to an Xcode project by adding it as a package dependency.

> https://github.com/pointfreeco/swiftui-navigation

If you want to use SwiftUI Navigation in a [SwiftPM](https://swift.org/package-manager/) project, it's as simple as adding it to a `dependencies` clause in your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "0.1.0")
]
```

## Documentation

The latest documentation for the SwiftUI Navigation APIs is available [here](https://pointfreeco.github.io/swiftui-navigation/).

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
