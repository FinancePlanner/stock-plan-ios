import Combine
import SwiftUI

@MainActor
final class OnboardingImportViewModel: ObservableObject {
  enum Step: Hashable {
    case mainMenu
    case chooseStockMethod
    case csv
    case manual
    case api
    case success
    case done
  }

  @Published var step: Step = .mainMenu

  func startStockImport() {
    step = .chooseStockMethod
  }

  func selectStockMethod(_ method: StockImportMethod) {
    switch method {
    case .csv:
      step = .csv
    case .manual:
      step = .manual
    case .api:
      step = .api
    }
  }

  func backToMain() { step = .mainMenu }
  func backToChooseStock() { step = .chooseStockMethod }
  func finish() { step = .success }
  func complete() { step = .done }
}
