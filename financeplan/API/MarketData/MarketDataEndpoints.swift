import AnyAPI
import Foundation
import StockPlanShared

struct GetCompanyProfileEndpoint: Endpoint {
  typealias Response = CompanyProfileResponse

  let symbol: String

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/profile/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters { [:] }
}

struct GetQuoteEndpoint: Endpoint {
  typealias Response = QuoteResponse

  let symbol: String

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/quote/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters { [:] }
}

struct GetGradesConsensusEndpoint: Endpoint {
  typealias Response = [StockAnalystConsensus]

  let symbol: String

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/grades-consensus/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters { [:] }
}

struct GetBasicFinancialsEndpoint: Endpoint {
  typealias Response = MarketBasicFinancialsResponse

  let symbol: String

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/basic-financials/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters { [:] }
}

struct GetAnalysisMetricsEndpoint: Endpoint {
  typealias Response = StockAnalysisMetrics

  let symbol: String

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/analysis/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters { [:] }
}
