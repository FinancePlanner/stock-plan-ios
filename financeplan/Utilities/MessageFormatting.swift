import Factory
import SwiftUI

// MARK: - Message Formatting Utilities

enum MessageFormatting {
  @MainActor
  static func createAttributedText(
    from text: String,
    baseFont: UIFont,
    textColor: UIColor,
    palette: Palette,
    network: Network,
    syntax: AttributedString.MarkdownParsingOptions.InterpretedSyntax = .inlineOnlyPreservingWhitespace
  ) -> AttributedString {
    do {
      // Try to parse as markdown first
      var attributed = try AttributedString(
        markdown: text,
        options: .init(interpretedSyntax: syntax)
      )

      // Apply base styling
      attributed.font = baseFont
      attributed.foregroundColor = textColor

      // Enhanced styling for markdown elements
      attributed = applyMarkdownStyling(to: attributed, baseFont: baseFont, baseColor: textColor, palette: palette)

      // Apply mention styling
      attributed = applyMentionStyling(to: attributed, baseFont: baseFont, palette: palette, network: network)

      return attributed
    } catch {
      // If markdown parsing fails, fall back to plain text
      var attributed = AttributedString(text)
      attributed.font = baseFont
      attributed.foregroundColor = textColor
      return attributed
    }
  }

  private static func applyMarkdownStyling(
    to attributedString: AttributedString,
    baseFont: UIFont,
    baseColor: UIColor,
    palette: Palette
  ) -> AttributedString {
    var result = attributedString
    let baseFontSize = baseFont.pointSize

    // Iterate through all runs and enhance styling
    for run in result.runs {
      let range = run.range

      // Bold text styling
      if
        let inlinePresentationIntent = run.inlinePresentationIntent,
        inlinePresentationIntent.contains(.stronglyEmphasized)
      {
        result[range].font = .system(size: baseFontSize, weight: .bold)
        result[range].foregroundColor = baseColor.withAlphaComponent(1.0)
      }

      // Italic text styling
      if
        let inlinePresentationIntent = run.inlinePresentationIntent,
        inlinePresentationIntent.contains(.emphasized)
      {
        result[range].font = .system(size: baseFontSize, weight: .regular, design: .default).italic()
        result[range].foregroundColor = baseColor.withAlphaComponent(0.9)
      }

      // Code text styling
      if
        let inlinePresentationIntent = run.inlinePresentationIntent,
        inlinePresentationIntent.contains(.code)
      {
        result[range].font = .system(size: baseFontSize * 0.9, weight: .medium, design: .monospaced)
        result[range].foregroundColor = UIColor(palette.ocean)
        result[range].backgroundColor = UIColor(palette.input).withAlphaComponent(0.8)
      }

      // Link styling
      if run.link != nil {
        result[range].foregroundColor = UIColor(palette.blue)
        result[range].underlineStyle = .single
      }

      // Strikethrough styling
      if
        let inlinePresentationIntent = run.inlinePresentationIntent,
        inlinePresentationIntent.contains(.strikethrough)
      {
        result[range].strikethroughStyle = .single
        result[range].strikethroughColor = baseColor.withAlphaComponent(0.7)
        result[range].foregroundColor = baseColor.withAlphaComponent(0.6)
      }
    }

    return result
  }

  @MainActor
  private static func applyMentionStyling(
    to attributedString: AttributedString,
    baseFont: UIFont,
    palette: Palette,
    network: Network
  ) -> AttributedString {
    var result = attributedString
    let text = String(attributedString.characters)
    let baseFontSize = baseFont.pointSize

    // Regular expression to find mentions (@username)
    let mentionPattern = #"@([a-zA-Z0-9_]+)"#

    do {
      let regex = try NSRegularExpression(pattern: mentionPattern, options: [])
      let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))

      for match in matches.reversed() { // Reverse to maintain indices
        if let range = Range(match.range, in: text) {
          let mention = String(text[range])
          let username = String(mention.dropFirst()) // Remove @

          // Convert to AttributedString range
          if let attributedRange = Range(match.range, in: attributedString) {
            result[attributedRange].font = .system(size: baseFontSize, weight: .bold)
            result[attributedRange].foregroundColor = UIColor(palette.orange)

            // Highlight current user mentions with background color
            if username.lowercased() == network.user?.username.lowercased() {
              result[attributedRange].backgroundColor = UIColor(palette.orange.opacity(0.25))
            }

            // Add custom attribute to identify this as a mention for tap handling
            result[attributedRange].link = URL(string: "mention://\(username)")
          }
        }
      }
    } catch {
      log.app("Error creating mention regex", level: .error, error: error)
    }

    return result
  }
}
