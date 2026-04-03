import Foundation

struct ImportedPosition: Identifiable, Equatable {
  let id = UUID()
  let symbol: String
  let quantity: Double
  let price: Double
}
