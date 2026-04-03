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

struct GetMarketCompareEndpoint: Endpoint {
  typealias Response = [StockAnalysisMetrics]

  let symbols: [String]

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/compare" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters {
    ["symbols": symbols.joined(separator: ",")]
  }
}

struct GetBalanceSheetStatementEndpoint: Endpoint {
  typealias Response = [BalanceSheetStatementResponse]

  let symbol: String
  let limit: Int?
  let period: String?

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/balance-sheet-statement/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters {
    var params: Parameters = [:]
    if let limit { params["limit"] = limit }
    if let period { params["period"] = period }
    return params
  }
}

struct GetCashFlowStatementEndpoint: Endpoint {
  typealias Response = [CashFlowStatementResponse]

  let symbol: String
  let limit: Int?
  let period: String?

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/cash-flow-statement/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters {
    var params: Parameters = [:]
    if let limit { params["limit"] = limit }
    if let period { params["period"] = period }
    return params
  }
}

struct GetRatiosEndpoint: Endpoint {
  typealias Response = [RatiosResponse]

  let symbol: String
  let limit: Int?
  let period: String?

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/ratios/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters {
    var params: Parameters = [:]
    if let limit { params["limit"] = limit }
    if let period { params["period"] = period }
    return params
  }
}

struct GetRatiosTTMEndpoint: Endpoint {
  typealias Response = [RatiosTTMResponse]

  let symbol: String

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/ratios-ttm/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters { [:] }
}

struct GetFinancialGrowthEndpoint: Endpoint {
  typealias Response = [FinancialGrowthResponse]

  let symbol: String
  let limit: Int?
  let period: String?

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/financial-growth/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters {
    var params: Parameters = [:]
    if let limit { params["limit"] = limit }
    if let period { params["period"] = period }
    return params
  }
}

struct GetAnalystEstimatesEndpoint: Endpoint {
  typealias Response = [AnalystEstimatesResponse]

  let symbol: String
  let limit: Int?
  let period: String?

  var method: HTTPMethod { .get }
  var path: String { "/v1/market/analyst-estimates/\(symbol.uppercased())" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters {
    var params: Parameters = [:]
    if let limit { params["limit"] = limit }
    if let period { params["period"] = period }
    return params
  }
}
