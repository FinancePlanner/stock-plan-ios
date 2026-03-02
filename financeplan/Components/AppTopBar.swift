import SwiftUI

struct AppTopBar: View {
  let username: String
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    HStack(spacing: 10) {

      // LEFT: Logo + App name (Slack-like compact cluster)
      HStack(spacing: 8) {
        Circle()
          .fill(
            LinearGradient(
              colors: [
                Color(red: 0.05, green: 0.40, blue: 0.95),
                Color(red: 0.30, green: 0.58, blue: 1.00),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 30, height: 30) // slightly tighter
          .overlay(
            Text("FP")
              .font(.system(size: 12, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
          )

        VStack(alignment: .leading, spacing: 1) {
          Text("FinPlanner")
            .typography(.label, weight: .bold)
            .foregroundStyle(AppTheme.Colors.navBarForeground(for: colorScheme))
            .lineLimit(1)

          // Optional: tiny subtitle like Slack status/workspace
          Text("Workspace")
            .typography(.nano, weight: .medium)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer()

      // RIGHT: Username + avatar (Slack-ish pill)
      HStack(spacing: 8) {
        Text(username)
          .typography(.nano, weight: .semibold)
          .foregroundStyle(AppTheme.Colors.navBarForeground(for: colorScheme).opacity(0.75))
          .lineLimit(1)

        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(AppTheme.Colors.tint(for: colorScheme).opacity(0.18))
          .frame(width: 30, height: 30)
          .overlay(
            Image(systemName: "person.fill")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(AppTheme.Colors.tint(for: colorScheme))
          )
          .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .strokeBorder(AppTheme.Colors.navBarForeground(for: colorScheme).opacity(0.08), lineWidth: 1)
          }
      }
      .padding(.leading, 6)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 4)

    // ✅ The “Slack feel” mostly comes from THIS background stack:
    .background {
      ZStack {
        // 1) Blur whatever scrolls behind the bar
        Rectangle().fill(.ultraThinMaterial)

        // 2) Add your theme color on top (keeps your brand)
        AppTheme.Colors.navBarBackground(for: colorScheme).opacity(0.75)
      }
      .ignoresSafeArea(edges: .top)
    }

    // ✅ Slack-like crisp separator instead of gradient hairline
    .overlay(alignment: .bottom) {
      Divider()
        .opacity(colorScheme == .dark ? 0.35 : 0.25)
    }

    // ✅ Very subtle lift (Slack’s top bar feels “on top”)
    .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 10, y: 6)
  }
}
