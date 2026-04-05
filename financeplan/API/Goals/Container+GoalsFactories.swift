import Factory
import Foundation

extension Container {
    var goalsService: Factory<any GoalsServicing> {
        self {
            DefaultGoalsService(
                environmentManager: self.appEnvironment(),
                authSessionManager: self.authSessionManager()
            )
        }
    }
}
