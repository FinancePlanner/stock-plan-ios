import Factory
import Foundation

extension Container {
    var dashboardService: Factory<any DashboardServicing> {
        self {
            DefaultDashboardService(
                environmentManager: self.appEnvironment(),
                authSessionManager: self.authSessionManager()
            )
        }
    }
}
