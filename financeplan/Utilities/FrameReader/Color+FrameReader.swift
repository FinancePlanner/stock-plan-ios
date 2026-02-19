import SwiftUI

#if DEBUG
  extension Color {
    var contrastingColor: Color {
      let components = UIColor(self).cgColor.components ?? [0, 0, 0]
      let red = components[0]
      let green = components.count > 1 ? components[1] : red
      let blue = components.count > 2 ? components[2] : red

      // Calculate relative luminance (0 = black, 1 = white)
      let luminance = 0.299 * red + 0.587 * green + 0.114 * blue

      return luminance > 0.5 ? .black : .white
    }
  }
#endif
