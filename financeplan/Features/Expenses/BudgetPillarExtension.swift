import Foundation
import StockPlanShared

// Re-map the DTO pillar to the UI model pillar
extension BudgetPillar {
    static var allCases: [BudgetPillar] {
        return [.fundamentals, .futureYou, .fun]
    }
}
