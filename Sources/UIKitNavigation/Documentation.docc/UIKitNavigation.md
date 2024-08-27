# ``UIKitNavigation``

Tools for making SwiftUI navigation simpler, more ergonomic and more precise.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swift-navigation)
- [Discussions](https://github.com/pointfreeco/swift-navigation/discussions)
- [Point-Free Videos](https://www.pointfree.co/collections/ukit)

## Overview

UIKit provides a few simple tools for navigation, but none of them are state-driven. Its navigation
tools are what is known as "fire-and-forget", which means you simply invoke a method to trigger
a navigation, but there is no representation of that event in your feature's state.


For example, to present a sheet from a button press one can simply do:

```swift
let button = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
  present(SettingsViewController(), animated: true)
})
```

This makes it easy to get started with navigation, but there are a few problems with this:

* It is difficult to determine from your feature's logic what child features are currently 
presented. You can check the `presentedViewController` property on `UIViewController` directly, 
but then that logic must exist in the view (and so hard to test), and you have to do extra work
to inspect the type-erased controller to truly see what is being presented.
* It is difficult to perform deep-linking to any feature of your app. You must duplicate the 
logic that invokes `present` or `pushViewController` in another part of your app in order to
deep-link into child features.

SwiftUI has taught us, it is incredibly powerful to be able to drive navigation from state. It 
allows you to encapsulate more of your feature's logic in an isolated and testable domain, and it 
unlocks deep linking for free since one just needs to construct a piece of state that represents 
where you want to navigate to, hand it to SwiftUI, and let SwiftUI do the rest.

The UIKitNavigation library brings a powerful suite of navigation tools to UIKit that are heavily
inspired by SwiftUI. For example, if you have a feature that can navigate to 3 different screens,
you can model that as an enum with 3 cases and some optional state: 

```swift
@Observable
class FeatureModel {
  var destination: Destination?

  enum Destination {
    case addItem(AddItemModel)
    case deleteItemAlert
    case editItem(EditItemModel)
  }
}
```

This allows us to prove that at most one of these destinations can be active at a time. And it
would be great if we could present and dismiss these child features based on the value of
`destination`. 

This is possible, but first we have to make one small change to the `Destination` enum by annotating
it with the `@CasePathable` macro:

```diff
+@CasePathable
 enum Destination {
   // ...
 }
```

This allows us to derive key paths and properties for each case of an enum, which is not currently
possible in native Swift.

With that done one can drive navigation in a _view controller_ using tools in the library: 

```swift
class FeatureViewController: UIViewController {
  @UIBindable var model: FeatureModel

  func viewDidLoad() {
    super.viewDidLoad()

    // Set up view hierarchy

    present(item: $model.destination.addItem) { addItemModel in
      AddItemViewController(model: addItemModel)
    }
    present(isPresented: Binding($model.destination.deleteItemAlert)) {
      let alert = UIAlertController(title: "Delete?", message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Yes", style: .destructive))
      alert.addAction(UIAlertAction(title: "No", style: .cancel))
      return alert
    }
    navigationDestination(item: $model.destination.editItem) { editItemModel in
      EditItemViewController(model: editItemModel)
    }
  }
}
```

By using the libraries navigation tools we can be guaranteed that the model will be kept in sync
with the view. When the state becomes non-`nil` the corresponding form of navigation will be 
triggered, and when the presented view is dismissed, the state will be `nil`'d out.

Another powerful aspect of SwiftUI is its ability to update its UI whenever state in an observable
model changes. And thanks to Swift's observation tools this can be done done implicitly and 
minimally: whichever fields are accessed in the `body` of the view are automatically tracked 
so that when they change the view updates.

Our UIKitNavigation library comes with a tool that brings this power to UIKit, and it's called
``observe(isolation:_:)-9xf99``:

```swift
observe { [weak self] in
  guard let self else { return }
  
  countLabel.text = "Count: \(model.count)"
  factLabel.isHidden = model.fact == nil 
  if let fact = model.fact {
    factLabel.text = fact
  }
  activityIndicator.isHidden = !model.isLoadingFact
}
```

Whichever fields are accessed inside `observe` (such as `count`, `fact` and `isLoadingFact` above)
are automatically tracked, so that whenever they are mutated the trailing closure of `observe`
will be invoked again, allowing us to update the UI with the freshest data.

All of these tools are built on top of Swift's powerful Observation framework. However, that 
framework only works on newer versions of Apple's platforms: iOS 17+, macOS 14+, tvOS 17+ and
watchOS 10+. However, thanks to our back-port of Swift's observation tools (see 
[Perception](http://github.com/pointfreeco/swift-perception)), you can make use of our tools 
right away, going all the way back to the iOS 13 era of platforms.


## Topics

### Animations

- ``withUIKitAnimation(_:_:completion:)``
- ``UIKitAnimation``

### Controls

- ``UIControlProtocol``
- ``UIKit/UIColorWell``
- ``UIKit/UIDatePicker``
- ``UIKit/UIPageControl``
- ``UIKit/UISegmentedControl``
- ``UIKit/UISlider``
- ``UIKit/UIStepper``
- ``UIKit/UISwitch``
- ``UIKit/UITextField``

### Navigation

- ``UIKit/UIViewController``
- ``UIKit/UIAlertController``
- ``UIKit/UITraitCollection``

### Xcode previews

- ``UIViewRepresenting``
- ``UIViewControllerRepresenting``
