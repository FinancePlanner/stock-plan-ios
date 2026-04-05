import Foundation
import StockPlanShared
import Factory

protocol GoalsServicing {
    func getGoals() async throws -> [GoalResponse]
    func createGoal(payload: GoalRequest) async throws -> GoalResponse
    func updateGoal(id: String, payload: GoalRequest) async throws -> GoalResponse
    func deleteGoal(id: String) async throws
}

struct DefaultGoalsService: GoalsServicing {
    let client: GoalsHTTPClient

    init(environmentManager: AppEnvironmentManager, authSessionManager: any AuthSessionManaging) {
        let env = environmentManager.current
        self.client = GoalsHTTPClient(
            baseURL: env.apiBaseUrl,
            session: .shared,
            authTokenProvider: { Container.shared.authSessionStore().authToken }
        )
    }

    func getGoals() async throws -> [GoalResponse] {
        try await client.getGoals()
    }

    func createGoal(payload: GoalRequest) async throws -> GoalResponse {
        try await client.createGoal(payload)
    }

    func updateGoal(id: String, payload: GoalRequest) async throws -> GoalResponse {
        try await client.updateGoal(id: id, payload: payload)
    }

    func deleteGoal(id: String) async throws {
        try await client.deleteGoal(id: id)
    }
}

struct GoalsServiceStub: GoalsServicing {
    func getGoals() async throws -> [GoalResponse] {
        [
            GoalResponse(id: UUID().uuidString, title: "Max out 401k"),
            GoalResponse(id: UUID().uuidString, title: "Save for European vacation")
        ]
    }
    
    func createGoal(payload: GoalRequest) async throws -> GoalResponse {
        GoalResponse(id: UUID().uuidString, title: payload.title)
    }
    
    func updateGoal(id: String, payload: GoalRequest) async throws -> GoalResponse {
        GoalResponse(id: id, title: payload.title)
    }
    
    func deleteGoal(id: String) async throws {}
}
