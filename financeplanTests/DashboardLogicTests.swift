import XCTest
import StockPlanShared
import Factory
@testable import financeplan

final class DashboardLogicTests: XCTestCase {
    
    func testDashboardResponseMapping() {
        let response = DashboardResponse(
            totalValue: 10000.0,
            dailyChange: 500.0,
            dailyChangePercent: 5.0,
            topPerformers: [],
            bottomPerformers: [],
            sectorAllocation: []
        )
        
        XCTAssertEqual(response.totalValue, 10000.0)
        XCTAssertEqual(response.dailyChange, 500.0)
        XCTAssertEqual(response.dailyChangePercent, 5.0)
    }
    
    func testDashboardInsightsMapping() {
        let insights = DashboardInsightsResponse(
            savingsRate: 20.0,
            budgetStreak: 5,
            watchlistCount: 10,
            cashBuffer: 15000.0
        )
        
        XCTAssertEqual(insights.savingsRate, 20.0)
        XCTAssertEqual(insights.budgetStreak, 5)
        XCTAssertEqual(insights.watchlistCount, 10)
        XCTAssertEqual(insights.cashBuffer, 15000.0)
    }
    
    @MainActor
    func testDashboardLoading() async throws {
        // Mock the service
        let stub = DashboardServiceStub()
        Container.shared.dashboardService.register { stub }
        
        // This test would normally live in a ViewModel test
        // but here we are verifying the service stub returns expected data
        let data = try await stub.getDashboard()
        XCTAssertEqual(data.totalValue, 124830.42)
        
        Container.shared.dashboardService.reset()
    }
}
