import SwiftUINavigation

private let readMe = """
  This case study demonstrates how to progammaticaly navigate in SwiftUI. All your components can be isolated from navigation, just using a basic ViewModifier on your views for navigation.
  """

// ========================================================================
// Navigation routes
// ========================================================================

enum ARoute: Equatable {
  case b(BRoute?)
}
enum BRoute: Equatable {
  case c(CRoute?)
}
enum CRoute: Equatable {
  case d
}

// ========================================================================
// Main navigation
// ========================================================================

struct FullProgrammaticNavigation: View {
  @State var route: ARoute?

  var body: some View {
    A()
      .onTapGesture { route = .b(.none) }
      .navigate(when: $route, is: /ARoute.b) { _ in
        theBView
      }
  }

  var theBView: some View {
    B()
      .onTapGesture { route = .b(.c(.none)) }
      .navigate(when: $route.case(in: /ARoute.b), is: /BRoute.c) { _ in
        theCView
      }
  }

  var theCView: some View {
    C()
      .onTapGesture { route = .b(.c(.d)) }
      .navigate(when: $route.case(in: /ARoute.b).case(in: /BRoute.c), is: /CRoute.d) { _ in
        theDView
      }
  }

  var theDView: some View {
    D()
  }
}

// ========================================================================
// Independent A/B/C views
// ========================================================================

struct A: View {
  var body: some View {
    Text("A view - Tap to navigate to B")
  }
}

struct B: View {
  var body: some View {
    Text("B view - Tap to navigate to C")
  }
}

struct C: View {
  var body: some View {
    Text("C view - Tap to navigate to D")
  }
}

struct D: View {
  var body: some View {
    Text("D view - No navigation")
  }
}
