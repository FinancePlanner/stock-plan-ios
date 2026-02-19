import SwiftUI

public struct AvenirFontScheme: FontScheme {
  public var weight: TypographyFontWeight
  public var isItalic: Bool
  public var size: CGFloat

  // swiftlint:disable switch_case_on_newline
  public var fontName: String {
    switch (weight, isItalic) {
    case (.thin, false): "Avenir-Light" // no "UltraLight" in Avenir
    case (.thin, true): "Avenir-LightOblique"
    case (.light, false): "Avenir-Book"
    case (.light, true): "Avenir-BookOblique"
    case (.regular, false): "Avenir-Roman"
    case (.regular, true): "Avenir-Oblique"
    case (.medium, false): "Avenir-Medium"
    case (.medium, true): "Avenir-MediumOblique"
    case (.semibold, false): "Avenir-Heavy"
    case (.semibold, true): "Avenir-HeavyOblique"
    case (.bold, false): "Avenir-Black"
    case (.bold, true): "Avenir-BlackOblique"
    case (.extraBold, false): "Avenir-Black" // no ExtraBold available
    case (.extraBold, true): "Avenir-BlackOblique"
    case (.black, false): "Avenir-Black"
    case (.black, true): "Avenir-BlackOblique"
    }
  }

  // swiftlint:enable switch_case_on_newline

  public init(_ weight: TypographyFontWeight = .regular, isItalic: Bool = false, size: CGFloat = 15) {
    self.weight = weight
    self.isItalic = isItalic
    self.size = size
  }
}
