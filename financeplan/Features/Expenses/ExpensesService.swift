import Foundation
import StockPlanShared
import Factory

protocol ExpensesServicing {
    // Snapshots
    func getSnapshots(year: Int?, month: Int?) async throws -> [BudgetSnapshotResponse]
    func createBudgetSnapshot(request: BudgetSnapshotRequest) async throws -> BudgetSnapshotResponse
    func updateSnapshot(snapshotId: String, payload: BudgetSnapshotRequest) async throws -> BudgetSnapshotResponse
    func deleteSnapshot(snapshotId: String) async throws
    func getSnapshotItems(snapshotId: String) async throws -> [BudgetPlanItemResponse]
    
    // Items
    func getAllPlanItems() async throws -> [BudgetPlanItemResponse]
    func createPlanItem(payload: BudgetPlanItemRequest) async throws -> BudgetPlanItemResponse
    func updatePlanItem(itemId: String, payload: BudgetPlanItemRequest) async throws -> BudgetPlanItemResponse
    func deletePlanItem(itemId: String) async throws
    
    // Expenses
    func getExpenses(from: String?, to: String?) async throws -> [ExpenseResponse]
    func createExpense(request: ExpenseRequest) async throws -> ExpenseResponse
    func updateExpense(expenseId: String, payload: ExpenseRequest) async throws -> ExpenseResponse
    func deleteExpense(expenseId: String) async throws
    
    // Reports
    func getMonthlyExpenseReports(from: String?, to: String?) async throws -> [BudgetMonthSummaryResponse]
    func getYearlyExpenseReports(from: String?, to: String?) async throws -> [BudgetYearSummaryResponse]
}

struct ExpensesHTTPService: ExpensesServicing {
    let client: ExpensesHTTPClient

    init(environmentManager: AppEnvironmentManager, authSessionManager: any AuthSessionManaging) {
        let env = environmentManager.current
        self.client = ExpensesHTTPClient(
            baseURL: env.apiBaseUrl,
            session: .shared,
            authTokenProvider: { Container.shared.authSessionStore().authToken }
        )
    }

    func getSnapshots(year: Int? = nil, month: Int? = nil) async throws -> [BudgetSnapshotResponse] {
        try await client.getSnapshots(year: year, month: month)
    }

    func createBudgetSnapshot(request: BudgetSnapshotRequest) async throws -> BudgetSnapshotResponse {
        try await client.createBudgetSnapshot(request: request)
    }

    func updateSnapshot(snapshotId: String, payload: BudgetSnapshotRequest) async throws -> BudgetSnapshotResponse {
        try await client.updateSnapshot(snapshotId: snapshotId, payload: payload)
    }

    func deleteSnapshot(snapshotId: String) async throws {
        try await client.deleteSnapshot(snapshotId: snapshotId)
    }

    func getSnapshotItems(snapshotId: String) async throws -> [BudgetPlanItemResponse] {
        try await client.getSnapshotItems(snapshotId: snapshotId)
    }

    func getAllPlanItems() async throws -> [BudgetPlanItemResponse] {
        try await client.getAllPlanItems()
    }

    func createPlanItem(payload: BudgetPlanItemRequest) async throws -> BudgetPlanItemResponse {
        try await client.createPlanItem(payload: payload)
    }

    func updatePlanItem(itemId: String, payload: BudgetPlanItemRequest) async throws -> BudgetPlanItemResponse {
        try await client.updatePlanItem(itemId: itemId, payload: payload)
    }

    func deletePlanItem(itemId: String) async throws {
        try await client.deletePlanItem(itemId: itemId)
    }

    func getExpenses(from: String? = nil, to: String? = nil) async throws -> [ExpenseResponse] {
        try await client.getExpenses(from: from, to: to)
    }

    func createExpense(request: ExpenseRequest) async throws -> ExpenseResponse {
        try await client.createExpense(request: request)
    }

    func updateExpense(expenseId: String, payload: ExpenseRequest) async throws -> ExpenseResponse {
        try await client.updateExpense(expenseId: expenseId, payload: payload)
    }

    func deleteExpense(expenseId: String) async throws {
        try await client.deleteExpense(expenseId: expenseId)
    }

    func getMonthlyExpenseReports(from: String? = nil, to: String? = nil) async throws -> [BudgetMonthSummaryResponse] {
        try await client.getMonthlyExpenseReports(from: from, to: to)
    }

    func getYearlyExpenseReports(from: String? = nil, to: String? = nil) async throws -> [BudgetYearSummaryResponse] {
        try await client.getYearlyExpenseReports(from: from, to: to)
    }
}

struct ExpensesServiceStub: ExpensesServicing {
    func getSnapshots(year: Int? = nil, month: Int? = nil) async throws -> [BudgetSnapshotResponse] { [] }
    func createBudgetSnapshot(request: BudgetSnapshotRequest) async throws -> BudgetSnapshotResponse { fatalError("Stub not implemented") }
    func updateSnapshot(snapshotId: String, payload: BudgetSnapshotRequest) async throws -> BudgetSnapshotResponse { fatalError("Stub not implemented") }
    func deleteSnapshot(snapshotId: String) async throws {}
    func getSnapshotItems(snapshotId: String) async throws -> [BudgetPlanItemResponse] { [] }
    
    func getAllPlanItems() async throws -> [BudgetPlanItemResponse] { [] }
    func createPlanItem(payload: BudgetPlanItemRequest) async throws -> BudgetPlanItemResponse { fatalError("Stub not implemented") }
    func updatePlanItem(itemId: String, payload: BudgetPlanItemRequest) async throws -> BudgetPlanItemResponse { fatalError("Stub not implemented") }
    func deletePlanItem(itemId: String) async throws {}
    
    func getExpenses(from: String? = nil, to: String? = nil) async throws -> [ExpenseResponse] { [] }
    func createExpense(request: ExpenseRequest) async throws -> ExpenseResponse { fatalError("Stub not implemented") }
    func updateExpense(expenseId: String, payload: ExpenseRequest) async throws -> ExpenseResponse { fatalError("Stub not implemented") }
    func deleteExpense(expenseId: String) async throws {}
    
    func getMonthlyExpenseReports(from: String? = nil, to: String? = nil) async throws -> [BudgetMonthSummaryResponse] { [] }
    func getYearlyExpenseReports(from: String? = nil, to: String? = nil) async throws -> [BudgetYearSummaryResponse] { [] }
}
