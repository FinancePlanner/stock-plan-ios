import Foundation
import SwiftUI

enum ChannelSlug {
  static let maxLength: Int = 21
  static let helperText: String = "Lowercase letters, numbers, '-' and '_' only. Spaces become '-'. (max 21)"

  static func sanitize(_ input: String) -> String {
    // Lowercase and replace any whitespace with '-'
    var s = input.lowercased().map { $0.isWhitespace ? "-" : $0 }.reduce("") { $0 + String($1) }

    // Keep only allowed characters: a-z, 0-9, '-', '_'
    s = s.filter { ($0 >= "a" && $0 <= "z") || ($0 >= "0" && $0 <= "9") || $0 == "-" || $0 == "_" }

    // Enforce max length
    if s.count > maxLength { s = String(s.prefix(maxLength)) }

    return s
  }

  static func isValid(_ slug: String) -> Bool {
    slug.count >= 2 && slug.count <= maxLength
  }
}

extension View {
  func channelSlugFieldStyle() -> some View {
    self
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .keyboardType(.asciiCapable)
  }
}
