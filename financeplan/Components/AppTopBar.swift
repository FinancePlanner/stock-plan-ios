import SwiftUI

/*
 Legacy full-width home header preserved for reference.

 struct AppTopBar: View {
   let username: String
   let isUserMenuPresented: Bool
   let onUserTap: () -> Void
   @Environment(\.colorScheme) private var colorScheme

   private func statChip(value: String, color: Color) -> some View {
     Text(value)
       .font(.system(size: 10, weight: .semibold, design: .rounded))
       .foregroundStyle(color)
       .padding(.horizontal, 6)
       .padding(.vertical, 3)
       .background(
         Capsule()
           .fill(color.opacity(0.1))
       )
   }

   var body: some View {
     HStack(spacing: 10) {
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
           .frame(width: 30, height: 30)
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

           statChip(value: "+2.31%", color: AppTheme.Colors.success)
         }
       }

       Spacer()

       Button(action: onUserTap) {
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
       }
       .buttonStyle(.plain)
       .padding(.leading, 6)
       .padding(.horizontal, 10)
       .padding(.vertical, 6)
       .background(
         RoundedRectangle(cornerRadius: 14, style: .continuous)
           .fill(
             isUserMenuPresented
             ? AppTheme.Colors.tint(for: colorScheme).opacity(colorScheme == .dark ? 0.22 : 0.14)
             : .clear
           )
       )
     }
     .padding(.horizontal, 14)
     .padding(.vertical, 4)
     .background {
       ZStack {
         Rectangle().fill(.ultraThinMaterial)
         AppTheme.Colors.navBarBackground(for: colorScheme).opacity(0.75)
       }
       .ignoresSafeArea(edges: .top)
     }
     .overlay(alignment: .bottom) {
       Divider()
         .opacity(colorScheme == .dark ? 0.35 : 0.25)
     }
     .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 10, y: 6)
   }
 }
 */

struct AppTopBarProfileButton: View {
  let isUserMenuPresented: Bool
  let onTap: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Button(action: onTap) {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(
          isUserMenuPresented
          ? AppTheme.Colors.tint(for: colorScheme).opacity(colorScheme == .dark ? 0.22 : 0.14)
          : AppTheme.Colors.tint(for: colorScheme).opacity(0.12)
        )
        .frame(width: 28, height: 28)
        .overlay(
          Image(systemName: "person.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.tint(for: colorScheme))
        )
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(
              AppTheme.Colors.navBarForeground(for: colorScheme).opacity(0.08),
              lineWidth: 1
            )
        }
    }
    .buttonStyle(.plain)
  }
}
