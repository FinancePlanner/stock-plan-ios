import Foundation
import StockPlanShared

protocol StockServicing {
  @discardableResult
  func create(stock: StockRequest) async throws -> StockResponse
  @discardableResult
  func bulkCreate(stocks: [StockRequest]) async throws -> BulkCreateStocksResponse
  func fetchPortfolio() async throws -> [StockResponse]
  func updateStock(_ stock: StockResponse) async throws -> StockResponse
  func delete(id: String) async throws
}

final class StockService: StockServicing {
  private let environmentManager: AppEnvironmentManager
  private let session: StockURLSessionProtocol
  private let sessionStore: AuthSessionStoring

  init(
    environmentManager: AppEnvironmentManager,
    session: StockURLSessionProtocol = URLSession.shared,
    sessionStore: AuthSessionStoring
  ) {
    self.environmentManager = environmentManager
    self.session = session
    self.sessionStore = sessionStore
  }

  @discardableResult
  func create(stock: StockRequest) async throws -> StockResponse {
    let client = makeClient()
    let endpoint = CreateStockEndpoint(
      symbol: stock.symbol,
      shares: stock.shares,
      buyPrice: stock.buyPrice,
      buyDate: stock.buyDate,
      notes: stock.notes
    )
    return try await client.call(endpoint)
  }

  @discardableResult
  func bulkCreate(stocks: [StockRequest]) async throws -> BulkCreateStocksResponse {
    let client = makeClient()
    let endpoint = BulkCreateStocksEndpoint(stocks: stocks)
    return try await client.call(endpoint)
  }
  
  func fetchPortfolio() async throws -> [StockResponse] {
    let client = makeClient()
    let endpoint = GetStocksEndpoint()
    return try await client.call(endpoint)
  }

  func updateStock(_ stock: StockResponse) async throws -> StockResponse {
    let client = makeClient()
    // Build a StockRequest payload from StockResponse (assuming same fields)
    let request = StockRequest(
      symbol: stock.symbol,
      shares: stock.shares,
      buyPrice: stock.buyPrice,
      buyDate: stock.buyDate,
      notes: stock.notes ?? ""
    )
    let endpoint = UpdateStockEndpoint(stockId: stock.id, payload: request)
    return try await client.call(endpoint)
  }

  func delete(id: String) async throws {
    let client = makeClient()
    let endpoint = DeleteStockEndpoint(stockId: id)
    try await client.callWithoutResponse(endpoint)
  }

  private func makeClient() -> StockHTTPClient {
    StockHTTPClient(
      baseURL: environmentManager.current.apiBaseUrl,
      session: session,
      authTokenProvider: { [weak sessionStore] in
        sessionStore?.authToken
      }
    )
  }
}
