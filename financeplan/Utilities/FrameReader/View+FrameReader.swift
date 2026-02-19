import SwiftUI

extension View {
  func readMinY(into minY: Binding<CGFloat>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { minY.wrappedValue = $0.minY })
  }

  func readMaxY(into maxY: Binding<CGFloat>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { maxY.wrappedValue = $0.maxY })
  }

  func readMinX(into minX: Binding<CGFloat>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { minX.wrappedValue = $0.minX })
  }

  func readSize(into size: Binding<CGSize>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { size.wrappedValue = $0.size })
  }

  func readFrame(into frame: Binding<CGRect>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { frame.wrappedValue = $0 })
  }

  func readHeight(into height: Binding<CGFloat>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { height.wrappedValue = $0.height })
  }

  func readWidth(into width: Binding<CGFloat>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { width.wrappedValue = $0.width })
  }

  func readOrigin(into origin: Binding<CGPoint>, in coordinateSpace: CoordinateSpace = .local) -> some View {
    modifier(FrameReader(in: coordinateSpace) { origin.wrappedValue = $0.origin })
  }

  #if DEBUG
    func debugFrame(_ color: Color = .white) -> some View {
      modifier(FrameSizeInfo(color: color))
    }
  #endif
}
