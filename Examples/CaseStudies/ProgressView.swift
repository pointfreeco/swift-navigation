import SwiftUI

struct ProgressView: View {
  var body: some View {
    UIViewRepresented { _ in
      let view = UIActivityIndicatorView()
      view.startAnimating()
      return view
    }
  }
}
