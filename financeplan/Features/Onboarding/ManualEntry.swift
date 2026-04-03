import Foundation

struct ManualEntry: Identifiable, Equatable {
  let id = UUID()
  var symbol: String = ""
  var quantity: String = ""
  var price: String = ""
}
