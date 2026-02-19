import SwiftUI

extension Font {
  public static func avenir(size: CGFloat = 17, weight: TypographyFontWeight = .regular, isItalic: Bool = false) -> Font {
    AvenirFontScheme(weight, isItalic: isItalic, size: size).font
  }
}
