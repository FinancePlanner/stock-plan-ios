import SwiftUI

struct FrameReader: ViewModifier {
  let coordinateSpace: CoordinateSpace
  let reader: (CGRect) -> Void

  init(
    in coordinateSpace: CoordinateSpace = .local,
    _ reader: @escaping (CGRect) -> Void
  ) {
    self.coordinateSpace = coordinateSpace
    self.reader = reader
  }

  func body(content: Content) -> some View {
    content.background(
      GeometryReader { proxy in
        Color.clear.preference(
          key: CGRectValuePreferenceKey.self,
          value: proxy.frame(in: coordinateSpace)
        )
      }
      .onPreferenceChange(CGRectValuePreferenceKey.self, perform: reader)
    )
  }
}
