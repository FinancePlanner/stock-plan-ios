import Foundation
import StockPlanShared
import XCTest
@testable import financeplan

@MainActor
final class MarketDataServiceTests: XCTestCase {
  private final class SessionMock: MarketDataURLSessionProtocol {
    var handler: ((URLRequest) throws -> (Data, URLResponse))?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
      guard let handler else {
        fatalError("SessionMock.handler must be configured before use")
      }
      return try handler(request)
    }
  }

  private final class AuthSessionManagerMock: AuthSessionManaging {
    var validAccessTokenCalls = 0
    var refreshAccessTokenCalls = 0
    var logoutCalls = 0
    var invalidateSessionCalls = 0
    var validAccessTokenResult: Result<String?, Error> = .failure(MockError.notConfigured)
    var refreshAccessTokenResult: Result<String?, Error> = .failure(MockError.notConfigured)

    func restoreSessionIfNeeded() async -> Bool { false }

    func validAccessToken() async throws -> String? {
      validAccessTokenCalls += 1
      return try validAccessTokenResult.get()
    }

    func refreshAccessToken() async throws -> String? {
      refreshAccessTokenCalls += 1
      return try refreshAccessTokenResult.get()
    }

    func logout() async {
      logoutCalls += 1
    }

    func invalidateSession() async {
      invalidateSessionCalls += 1
    }
  }

  private enum MockError: Error {
    case notConfigured
  }

  func testFetchCompanyProfile_UsesBearerTokenAndReturnsProfile() async throws {
    let session = SessionMock()
    let authSessionManager = AuthSessionManagerMock()
    authSessionManager.validAccessTokenResult = .success("token-123")
    let service = MarketDataHTTPService(
      environmentManager: AppEnvironmentManager(),
      session: session,
      authSessionManager: authSessionManager
    )
    let expected = CompanyProfileResponse(
      country: "US",
      currency: "USD",
      estimateCurrency: "USD",
      exchange: "NEW YORK STOCK EXCHANGE, INC.",
      finnhubIndustry: "Technology",
      ipo: "2021-06-10",
      logo: "https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/950801514946.png",
      marketCapitalization: 4355.17,
      name: "Zeta Global Holdings Corp",
      phone: "18003464646",
      shareOutstanding: 244.12,
      ticker: "ZETA",
      weburl: "https://investors.zetaglobal.com/"
    )

    session.handler = { request in
      XCTAssertTrue(request.url?.path.hasSuffix("/market/profile/ZETA") == true)
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")

      let response = try XCTUnwrap(
        HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
      )
      return (try JSONEncoder().encode(expected), response)
    }

    let response = try await service.fetchCompanyProfile(symbol: "zeta")

    XCTAssertEqual(response, expected)
    XCTAssertEqual(authSessionManager.validAccessTokenCalls, 1)
    XCTAssertEqual(authSessionManager.refreshAccessTokenCalls, 0)
  }

  func testFetchQuote_WhenUnauthorized_RefreshesAndRetriesWithNewToken() async throws {
    let session = SessionMock()
    let authSessionManager = AuthSessionManagerMock()
    authSessionManager.validAccessTokenResult = .success("expired-token")
    authSessionManager.refreshAccessTokenResult = .success("fresh-token")
    let service = MarketDataHTTPService(
      environmentManager: AppEnvironmentManager(),
      session: session,
      authSessionManager: authSessionManager
    )

    var requests = 0
    session.handler = { request in
      requests += 1

      if requests == 1 {
        XCTAssertTrue(request.url?.path.hasSuffix("/market/quote/ZETA") == true)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer expired-token")

        let response = try XCTUnwrap(
          HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 401, httpVersion: nil, headerFields: nil)
        )
        return (#"{"error":"Access token expired"}"#.data(using: .utf8) ?? Data(), response)
      }

      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fresh-token")
      let payload = """
      {
        "l": 15.53,
        "currency": "USD",
        "dp": -1.1935,
        "t": 1775073600,
        "symbol": "ZETA",
        "d": -0.19,
        "o": 16.2,
        "c": 15.73,
        "h": 16.3,
        "pc": 15.92
      }
      """.data(using: .utf8) ?? Data()
      let response = try XCTUnwrap(
        HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
      )
      return (payload, response)
    }

    let response = try await service.fetchQuote(symbol: "ZETA")

    XCTAssertEqual(response.currentPrice, 15.73, accuracy: 0.001)
    XCTAssertEqual(requests, 2)
    XCTAssertEqual(authSessionManager.validAccessTokenCalls, 1)
    XCTAssertEqual(authSessionManager.refreshAccessTokenCalls, 1)
    XCTAssertEqual(authSessionManager.invalidateSessionCalls, 0)
  }

  func testFetchAnalystConsensus_UsesBearerTokenAndReturnsFirstConsensusEntry() async throws {
    let session = SessionMock()
    let authSessionManager = AuthSessionManagerMock()
    authSessionManager.validAccessTokenResult = .success("token-123")
    let service = MarketDataHTTPService(
      environmentManager: AppEnvironmentManager(),
      session: session,
      authSessionManager: authSessionManager
    )

    let expected = StockAnalystConsensus(
      symbol: "UBER",
      strongBuy: 1,
      buy: 49,
      hold: 11,
      sell: 0,
      strongSell: 0,
      consensus: "Buy"
    )

    session.handler = { request in
      XCTAssertTrue(request.url?.path.hasSuffix("/grades-consensus/UBER") == true)
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")

      let response = try XCTUnwrap(
        HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
      )
      return (try JSONEncoder().encode([expected]), response)
    }

    let response = try await service.fetchAnalystConsensus(symbol: "uber")

    XCTAssertEqual(response, expected)
    XCTAssertEqual(authSessionManager.validAccessTokenCalls, 1)
    XCTAssertEqual(authSessionManager.refreshAccessTokenCalls, 0)
  }

  func testFetchBasicFinancials_UsesBearerTokenAndMapsWrappedMetrics() async throws {
    let session = SessionMock()
    let authSessionManager = AuthSessionManagerMock()
    authSessionManager.validAccessTokenResult = .success("token-123")
    let service = MarketDataHTTPService(
      environmentManager: AppEnvironmentManager(),
      session: session,
      authSessionManager: authSessionManager
    )

    session.handler = { request in
      XCTAssertTrue(request.url?.path.hasSuffix("/market/basic-financials/ZETA") == true)
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")

      let payload = """
      {
        "series": {
          "annual": {
            "salesPerShare": [
              { "period": "2025-12-31", "v": 5.9109 },
              { "period": "2024-12-31", "v": 5.4077 }
            ],
            "currentRatio": [
              { "period": "2025-12-31", "v": 1.5968 },
              { "period": "2024-12-31", "v": 3.0930 }
            ],
            "netMargin": [
              { "period": "2025-12-31", "v": -0.0242 },
              { "period": "2024-12-31", "v": -0.0694 }
            ]
          },
          "quarterly": {
            "currentRatio": [
              { "period": "2025-12-31", "v": 1.5968 }
            ],
            "netMargin": [
              { "period": "2025-12-31", "v": 0.0166 }
            ]
          }
        },
        "metricType": "all",
        "metric": {
          "peTTM": null,
          "forwardPE": 35.88769263246781,
          "netProfitMarginTTM": -2.42,
          "currentRatioQuarterly": 1.5968,
          "beta": 1.3087735,
          "52WeekHigh": 24.9,
          "52WeekLow": 10.69,
          "52WeekLowDate": "2025-04-21",
          "52WeekPriceReturnDaily": 12.1169,
          "10DayAverageTradingVolume": 7.52443
        },
        "symbol": "ZETA"
      }
      """.data(using: .utf8) ?? Data()
      let response = try XCTUnwrap(
        HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
      )
      return (payload, response)
    }

    let response = try await service.fetchBasicFinancials(symbol: "zeta")

    XCTAssertEqual(response.symbol, "ZETA")
    XCTAssertEqual(response.metricType, "all")
    XCTAssertNil(response.currencyCode)
    XCTAssertEqual(try XCTUnwrap(response.peRatio), 35.88769263246781, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.netMargin), -0.0242, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.currentRatio), 1.5968, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.beta), 1.3087735, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.fiftyTwoWeekHigh), 24.9, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.fiftyTwoWeekLow), 10.69, accuracy: 0.0001)
    XCTAssertEqual(response.fiftyTwoWeekLowDate, "2025-04-21")
    XCTAssertEqual(try XCTUnwrap(response.fiftyTwoWeekPriceReturnDaily), 12.1169, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.tenDayAverageTradingVolume), 7.52443, accuracy: 0.0001)
    XCTAssertEqual(response.salesPerShareAnnual.map(\.period), ["2025-12-31", "2024-12-31"])
    XCTAssertEqual(try XCTUnwrap(response.salesPerShareAnnual.first).value, 5.9109, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.currentRatioAnnual.first).value, 1.5968, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.netMarginAnnual.first).value, -0.0242, accuracy: 0.0001)
    XCTAssertEqual(authSessionManager.validAccessTokenCalls, 1)
    XCTAssertEqual(authSessionManager.refreshAccessTokenCalls, 0)
  }

  func testFetchAnalysisMetrics_UsesBearerTokenAndReturnsWrappedMetrics() async throws {
    let session = SessionMock()
    let authSessionManager = AuthSessionManagerMock()
    authSessionManager.validAccessTokenResult = .success("token-123")
    let service = MarketDataHTTPService(
      environmentManager: AppEnvironmentManager(),
      session: session,
      authSessionManager: authSessionManager
    )

    session.handler = { request in
      XCTAssertTrue(request.url?.path.hasSuffix("/market/analysis/ZETA") == true)
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")

      let payload = """
      {
        "symbol": "ZETA",
        "ttmPE": 21.4,
        "forwardPE": 18.9,
        "twoYearForwardPE": 16.4,
        "ttmEPSGrowth": 0.12,
        "currentYearExpectedEPSGrowth": 0.14,
        "nextYearEPSGrowth": 0.15,
        "ttmRevenueGrowth": 0.1,
        "currentYearExpectedRevenueGrowth": 0.11,
        "nextYearRevenueGrowth": 0.12,
        "grossMargin": 0.61,
        "netMargin": 0.2,
        "ttmPEGRatio": 1.6,
        "lastYearEPSGrowth": 0.09,
        "ttmVsNTMEPSGrowth": 0.02,
        "currentQuarterEPSGrowthVsPreviousYear": 0.08,
        "twoYearStackExpectedEPSGrowth": 0.31,
        "lastYearRevenueGrowth": 0.07,
        "ttmVsNTMRevenueGrowth": 0.01,
        "currentQuarterRevenueGrowthVsPreviousYear": 0.06,
        "twoYearStackExpectedRevenueGrowth": 0.24
      }
      """.data(using: .utf8) ?? Data()
      let response = try XCTUnwrap(
        HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
      )
      return (payload, response)
    }

    let response = try await service.fetchAnalysisMetrics(symbol: "zeta")

    XCTAssertEqual(response.symbol, "ZETA")
    XCTAssertEqual(try XCTUnwrap(response.ttmPE), 21.4, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.currentYearExpectedRevenueGrowth), 0.11, accuracy: 0.0001)
    XCTAssertEqual(try XCTUnwrap(response.comparisonMetrics[.ttmPEGRatio]), 1.6, accuracy: 0.0001)
    XCTAssertEqual(authSessionManager.validAccessTokenCalls, 1)
    XCTAssertEqual(authSessionManager.refreshAccessTokenCalls, 0)
  }

  func testFetchFinancialStatements_ReturnsMockStatementsForRequestedSymbol() async throws {
    let session = SessionMock()
    let authSessionManager = AuthSessionManagerMock()
    let service = MarketDataHTTPService(
      environmentManager: AppEnvironmentManager(),
      session: session,
      authSessionManager: authSessionManager
    )

    let statements = try await service.fetchFinancialStatements(symbol: "msft")

    XCTAssertEqual(statements.symbol, "MSFT")
    XCTAssertEqual(statements.balanceSheets.count, 6)
    XCTAssertEqual(statements.cashFlows.count, 6)
    XCTAssertEqual(statements.ratios.count, 6)
    XCTAssertEqual(statements.growth.count, 6)
    XCTAssertEqual(statements.estimates.count, 3)
    XCTAssertEqual(statements.balanceSheets(for: .fy).first?.symbol, "MSFT")
    XCTAssertEqual(authSessionManager.validAccessTokenCalls, 0)
    XCTAssertEqual(authSessionManager.refreshAccessTokenCalls, 0)
  }
}
