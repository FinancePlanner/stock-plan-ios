import SwiftUI

// MARK: - Glass Shape

/// Describes which shape the glass effect should use.
enum GlassShape {
  case rect(cornerRadius: CGFloat)
  case capsule
  case circle
}

// MARK: - Backwards-compatible Glass Modifier

/// On iOS 26+ applies the native `.glassEffect(.clear, in:)` modifier.
/// On earlier versions falls back to the existing manual glass look
/// (fill + stroke + shadow) to maintain visual parity.
struct GlassEffectModifier: ViewModifier {
  let shape: GlassShape
  let tint: Color?

  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    if #available(iOS 26, *) {
      content
        .modifier(NativeGlassModifier(shape: shape, tint: tint))
    } else {
      content
        .modifier(FallbackGlassModifier(shape: shape, tint: tint, colorScheme: colorScheme))
    }
  }
}

// MARK: - iOS 26+ Native

@available(iOS 26, *)
private struct NativeGlassModifier: ViewModifier {
  let shape: GlassShape
  let tint: Color?

  func body(content: Content) -> some View {
    switch shape {
    case .rect(let cornerRadius):
      if let tint {
        content
          .background(tint.opacity(0.08))
          .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
      } else {
        content
          .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
      }
    case .capsule:
      if let tint {
        content
          .background(tint.opacity(0.08))
          .glassEffect(.clear, in: .capsule)
      } else {
        content
          .glassEffect(.clear, in: .capsule)
      }
    case .circle:
      if let tint {
        content
          .background(tint.opacity(0.08))
          .glassEffect(.clear, in: .circle)
      } else {
        content
          .glassEffect(.clear, in: .circle)
      }
    }
  }
}

// MARK: - Pre-iOS 26 Fallback

private struct FallbackGlassModifier: ViewModifier {
  let shape: GlassShape
  let tint: Color?
  let colorScheme: ColorScheme

  private var fillColor: Color {
    tint ?? AppTheme.Colors.cardBackground(for: colorScheme)
  }

  private var strokeColor: Color {
    AppTheme.Colors.separator(for: colorScheme)
      .opacity(colorScheme == .dark ? 0.38 : 0.18)
  }

  func body(content: Content) -> some View {
    switch shape {
    case .rect(let cornerRadius):
      content
        .background(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor)
        )
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(strokeColor, lineWidth: 0.8)
        )
        .shadow(
          color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.05),
          radius: colorScheme == .dark ? 16 : 12,
          x: 0,
          y: colorScheme == .dark ? 10 : 6
        )

    case .capsule:
      content
        .background(
          Capsule()
            .fill(fillColor)
        )
        .overlay(
          Capsule()
            .stroke(strokeColor, lineWidth: 0.8)
        )
        .shadow(
          color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.04),
          radius: 8, x: 0, y: 3
        )

    case .circle:
      content
        .background(
          Circle()
            .fill(fillColor)
        )
        .overlay(
          Circle()
            .stroke(strokeColor, lineWidth: 0.8)
        )
        .shadow(
          color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.04),
          radius: 8, x: 0, y: 3
        )
    }
  }
}

// MARK: - View Extension

extension View {
  /// Applies a glass effect with backwards compatibility.
  /// On iOS 26+ uses the native `.glassEffect(.clear, in:)`.
  /// On older versions uses a manual glass-like background.
  func appGlassEffect(
    _ shape: GlassShape = .rect(cornerRadius: 24),
    tint: Color? = nil
  ) -> some View {
    modifier(GlassEffectModifier(shape: shape, tint: tint))
  }
}
