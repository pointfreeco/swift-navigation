# Cross-platform

Learn the basics of how this library's tools can be used to build tools for cross-platform 
development.

## Overview

The tools provided by this library can also form the foundation of building navigation tools for
non-Apple platforms, such as Windows, Linux, Wasm and more. We do not currently provide any such
tools at this moment, but it is possible for them to be built externally.

For example, in Wasm it is possible to use the ``observe(isolation:_:)-9xf99`` function to observe
changes to a model and update the DOM:

```swift
import JavaScriptKit

var countLabel = document.createElement("span")
_ = document.body.appendChild(countLabel)

let token = observe {
  countLabel.innerText = .string("Count: \(model.count)")
}
```

And it's possible to drive navigation from state, such as an alert:

```swift
alert(isPresented: $model.isShowingErrorAlert) {
  "Something went wrong"
}
```

And you can build more advanced tools for presenting and dismissing `<dialog>`'s in the browser.
