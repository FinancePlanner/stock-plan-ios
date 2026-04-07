import Combine
import Foundation
import Factory
import StockPlanShared

@MainActor
final class ReportsViewModel: ObservableObject {
  @Published var statistics: StatisticsDTO?
  @Published var monthlySummaries: [BudgetMonthSummary] = []
  @Published var isLoading = false
  @Published var errorMessage: String? = nil

  private let statisticsService: any StatisticsServicing = Container.shared.statisticsService()
  private let expensesService: any ExpensesServicing = Container.shared.expensesService()
  
  private let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      return formatter
  }()

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    
    do {
      async let fetchStats = statisticsService.fetchStatisticsOverview()
      async let fetchExpenses = expensesService.getMonthlyExpenseReports(from: nil, to: nil)
      
      let (stats, summaries) = try await (fetchStats, fetchExpenses)
      
      self.statistics = stats
      self.monthlySummaries = summaries.compactMap { report -> BudgetMonthSummary? in
          guard let monthStart = dateFormatter.date(from: report.monthStart) else { return nil }
          
          var mappedActuals: [BudgetPillar: Double] = [:]
          for (key, value) in report.pillarActuals {
              if let pillar = BudgetPillar(rawValue: key) { mappedActuals[pillar] = value }
          }
          
          var mappedPlans: [BudgetPillar: Double] = [:]
          for (key, value) in report.pillarPlans {
              if let pillar = BudgetPillar(rawValue: key) { mappedPlans[pillar] = value }
          }
          
          return BudgetMonthSummary(
              monthStart: monthStart,
              planned: report.planned,
              actual: report.actual,
              salary: report.salary,
              pillarActuals: mappedActuals,
              pillarPlans: mappedPlans
          )      }.sorted { $0.monthStart > $1.monthStart }
      
    } catch {
      self.errorMessage = error.localizedDescription
    }
    
    isLoading = false
  }
}
