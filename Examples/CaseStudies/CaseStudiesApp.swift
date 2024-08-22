import SwiftUI

@main
struct CaseStudiesApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
//      ContentView()
    }
  }
}

import UIKitNavigation
struct ContentView: View {
  @State var isHidden = false
  var body: some View {
    Form {
      Text("Hello!")
        .opacity(isHidden ? 0 : 1 )

      // animations: [PlatformKey: ]
//      perform.uiKit
//      perform.wasm
//      perform.uiKit

      Button("Tap") {
        withUIKitAnimation(.linear) {
          withAnimation(.linear(duration: 0.3)) {
            isHidden.toggle()
          }
        }
      }
    }
  }
}
#Preview {

}
