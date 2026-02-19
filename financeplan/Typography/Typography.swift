import SwiftUI

public enum Typography {
  // Display & Headings
  case display
  case heading
  case hero
  case title
  case headline

  // Body content
  case body
  case small
  case mini
  case nano
  case tiny

  // Metadata & Support
  case caption
  case footnote
  case overline

  // Functional roles
  case button
  case label
  case code
  case link
}

extension Typography {
  public var defaultWeight: TypographyFontWeight {
    switch self {
    case .button, .display, .heading, .hero, .title:
      .bold
    case .headline:
      .semibold
    default:
      .regular
    }
  }
}
