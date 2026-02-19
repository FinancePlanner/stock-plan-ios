import Kingfisher
import SwiftUI

public struct Icon: View {
  public static let defaultSize = CGSize(width: 24, height: 24)

  public var imageType: ImageType
  public var size: CGSize
  public var renderingMode: Image.TemplateRenderingMode?

  public var body: some View {
    if case let .web(url) = imageType {
      KFImage.url(url)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size.width, height: size.height)
    } else {
      imageType
        .image
        .resizable()
        .renderingMode(renderingMode ?? .template)
        .aspectRatio(contentMode: .fit)
        .frame(width: size.width, height: size.height)
    }
  }

  public init(
    _ imageType: ImageType,
    size: CGSize = Self.defaultSize,
    renderingMode: Image.TemplateRenderingMode? = nil
  ) {
    self.imageType = imageType
    self.size = size
    self.renderingMode = renderingMode
  }

  public init(systemName: String, size: CGSize = Self.defaultSize) {
    self.init(.system(name: systemName), size: size)
  }

  public init(
    name: String,
    size: CGSize = Self.defaultSize,
    bundle: Bundle? = nil,
    renderingMode _: Image.TemplateRenderingMode? = nil
  ) {
    self.init(.named(name, bundle: bundle), size: size)
  }
}
