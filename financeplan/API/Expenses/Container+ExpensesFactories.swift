import Factory
import Foundation

extension Container {
  var expensesHTTPClient: Factory<ExpensesHTTPClient> {
    self { [unowned self] in
      let env = self.appEnvironment()
      let store = self.authSessionStore()
      return ExpensesHTTPClient(
        baseURL: env.current.apiBaseUrl,
        session: URLSession.shared,
        authTokenProvider: { store.authToken }
      )
    }
  }

  var expensesService: Factory<ExpensesServicing> {
    self { [unowned self] in
      ExpensesHTTPService(
        environmentManager: self.appEnvironment(),
        authSessionManager: self.authSessionManager()
      )
    }
  }
}
