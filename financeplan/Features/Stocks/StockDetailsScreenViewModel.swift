//
//  StockDetailsScreenViewModel.swift
//  financeplan
//
//  Created by Fernando Correia on 11.03.26.
//

import Combine
import Factory
import Foundation
import StockPlanShared

@MainActor
final class StockDetailsViewModel: ObservableObject {
    private struct AnalystConsensusLoadResult {
        let consensus: StockAnalystConsensus?
        let message: String?
    }

    private struct AnalysisMetricsLoadResult {
        let metrics: StockAnalysisMetrics?
        let message: String?
    }

    private struct FinancialStatementsLoadResult {
        let statements: StockFinancialStatements?
        let message: String?
    }

    private struct FinancialStatementsSectionLoadResult<Value> {
        let value: Value
        let message: String?
        let isUnsupportedPlan: Bool
    }

    @Published var details: StockDetails?
    @Published var history: [StockHistory] = []
    @Published var news: [StockNews] = []
    @Published var valuation: StockValuationRequest?
    @Published private(set) var companyProfile: CompanyProfileResponse?
    @Published private(set) var marketSnapshot: StockMarketSnapshot?
    @Published private(set) var analystConsensus: StockAnalystConsensus?
    @Published private(set) var analystConsensusMessage: String?
    @Published private(set) var basicFinancials: StockBasicFinancials?
    @Published private(set) var analysisMetrics: StockAnalysisMetrics?
    @Published private(set) var analysisMetricsMessage: String?
    @Published private(set) var financialStatements: StockFinancialStatements?
    @Published private(set) var financialStatementsMessage: String?
    @Published private(set) var primaryComparisonProfile: StockComparisonProfile?
    @Published private(set) var comparisonUniverse: [StockComparisonProfile] = []
    @Published private(set) var selectedPeerSymbols: [String] = []
    @Published var isLoading = false
    @Published var isSavingPosition = false
    @Published var isDeletingPosition = false
    @Published var errorMessage: String?

    private let service: StockServicing
    private let marketDataService: MarketDataServicing

    var shareSnapshot: StockShareSnapshot? {
        guard let details else { return nil }
        return StockShareFormatter.makeSnapshot(
            details: details,
            valuation: valuation,
            history: history,
            news: news
        )
    }

    var selectedPeerProfiles: [StockComparisonProfile] {
        selectedPeerSymbols.compactMap(comparisonProfile(for:))
    }

    var comparisonProfiles: [StockComparisonProfile] {
        guard let primaryComparisonProfile else { return [] }
        return [primaryComparisonProfile] + selectedPeerProfiles
    }

    var availablePeerProfiles: [StockComparisonProfile] {
        guard let primaryComparisonProfile else { return comparisonUniverse }
        return comparisonUniverse.filter { $0.symbol != primaryComparisonProfile.symbol }
    }

    init() {
        self.service = Container.shared.stockService()
        self.marketDataService = Container.shared.marketDataService()
    }

    init(service: StockServicing, marketDataService: MarketDataServicing) {
        self.service = service
        self.marketDataService = marketDataService
    }

    init(service: StockServicing) {
        self.service = service
        self.marketDataService = MarketDataServiceStub()
    }

    func savePosition(_ updated: StockResponse) async -> Bool {
        guard !isSavingPosition else { return false }
        isSavingPosition = true
        errorMessage = nil
        defer { isSavingPosition = false }

        do {
            let saved = try await service.updateStock(updated)
            details = saved
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            errorMessage = message
            return false
        }
    }

    func deletePosition() async -> Bool {
        guard let current = details else { return false }
        guard !isDeletingPosition else { return false }
        isDeletingPosition = true
        errorMessage = nil
        defer { isDeletingPosition = false }

        do {
            try await service.delete(id: current.id)
            details = nil
            history = []
            news = []
            valuation = nil
            companyProfile = nil
            marketSnapshot = nil
            analystConsensus = nil
            analystConsensusMessage = nil
            basicFinancials = nil
            analysisMetrics = nil
            analysisMetricsMessage = nil
            financialStatements = nil
            financialStatementsMessage = nil
            primaryComparisonProfile = nil
            comparisonUniverse = []
            selectedPeerSymbols = []
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            errorMessage = message
            return false
        }
    }

    func saveValuation(_ draft: StockValuationDraft) async -> String? {
        guard !isLoading else { return "A save is already in progress." }
        guard let symbol = details?.symbol ?? valuation?.symbol else {
            return "Unable to resolve the stock symbol for this valuation."
        }

        print(
            """
            StockDetailsViewModel.saveValuation \
            symbol=\(symbol) \
            bearLow=\(draft.bearLow) bearHigh=\(draft.bearHigh) \
            baseLow=\(draft.baseLow) baseHigh=\(draft.baseHigh) \
            bullLow=\(draft.bullLow) bullHigh=\(draft.bullHigh) \
            rationale=\(draft.rationale ?? "<nil>") \
            targetDate=\(draft.targetDate ?? "<nil>")
            """
        )

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if valuation != nil {
                valuation = try await service.updateValuation(symbol: symbol, draft: draft)
            } else {
                valuation = try await service.createValuation(symbol: symbol, draft: draft)
            }
            return nil
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            errorMessage = message
            return message
        }
    }

    func load(stockId: String) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let details = try await service.fetchStockDetails(stockId: stockId)
            let symbol = details.symbol

            async let historyTask = loadHistory(symbol: symbol)
            async let newsTask = loadNews(symbol: symbol)
            async let valuationTask = loadValuation(symbol: symbol)
            async let companyProfileTask = loadCompanyProfile(symbol: symbol)
            async let quoteTask = loadQuote(symbol: symbol)
            async let analystConsensusTask = loadAnalystConsensus(symbol: symbol)
            async let basicFinancialsTask = loadBasicFinancials(symbol: symbol)
            async let analysisMetricsTask = loadAnalysisMetrics(symbol: symbol)
            async let financialStatementsTask = loadFinancialStatements(symbol: symbol)

            self.details = details
            seedMockInsights(for: symbol)
            self.history = await historyTask
            self.news = await newsTask
            self.valuation = await valuationTask
            self.companyProfile = await companyProfileTask
            self.marketSnapshot = await quoteTask
            let analystConsensusResult = await analystConsensusTask
            self.analystConsensus = analystConsensusResult.consensus
            self.analystConsensusMessage = analystConsensusResult.message
            self.basicFinancials = await basicFinancialsTask
            let analysisMetricsResult = await analysisMetricsTask
            self.analysisMetrics = analysisMetricsResult.metrics
            self.analysisMetricsMessage = analysisMetricsResult.message
            applyAnalysisMetrics(analysisMetricsResult.metrics, to: symbol)
            let financialStatementsResult = await financialStatementsTask
            self.financialStatements = financialStatementsResult.statements
            self.financialStatementsMessage = financialStatementsResult.message
        } catch {
            details = nil
            history = []
            news = []
            valuation = nil
            companyProfile = nil
            marketSnapshot = nil
            analystConsensus = nil
            analystConsensusMessage = nil
            basicFinancials = nil
            analysisMetrics = nil
            analysisMetricsMessage = nil
            financialStatements = nil
            financialStatementsMessage = nil
            primaryComparisonProfile = nil
            comparisonUniverse = []
            selectedPeerSymbols = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func projectionScenario(_ kind: StockProjectionScenarioKind) -> StockProjectionScenario? {
        primaryComparisonProfile?.projectionScenarios[kind]
    }

    func comparisonProfile(for symbol: String) -> StockComparisonProfile? {
        comparisonUniverse.first { $0.symbol == symbol.uppercased() }
    }

    func selectedPeerSymbol(at slot: Int) -> String {
        guard selectedPeerSymbols.indices.contains(slot) else { return "" }
        return selectedPeerSymbols[slot]
    }

    func updatePeerSymbol(_ symbol: String, slot: Int) {
        guard slot >= 0 else { return }

        let normalized = symbol.uppercased()
        guard
            !normalized.isEmpty,
            let primaryComparisonProfile,
            normalized != primaryComparisonProfile.symbol
        else { return }

        var peers = selectedPeerSymbols
        if peers.count <= slot {
            peers.append(contentsOf: Array(repeating: "", count: slot - peers.count + 1))
        }

        if let existingIndex = peers.firstIndex(of: normalized), existingIndex != slot {
            peers.swapAt(existingIndex, slot)
        } else {
            peers[slot] = normalized
        }

        var seen = Set<String>()
        selectedPeerSymbols = peers.filter { symbol in
            !symbol.isEmpty && seen.insert(symbol).inserted
        }

        fillMissingPeers()
    }

    func saveValuation(
        bearLow: Double,
        bearHigh: Double,
        baseLow: Double,
        baseHigh: Double,
        bullLow: Double,
        bullHigh: Double,
        rationale: String?,
        targetDate: String?
    ) async -> String? {
        await saveValuation(
            StockValuationDraft(
                bearLow: bearLow,
                bearHigh: bearHigh,
                baseLow: baseLow,
                baseHigh: baseHigh,
                bullLow: bullLow,
                bullHigh: bullHigh,
                rationale: rationale,
                targetDate: targetDate
            )
        )
    }

    func saveAnalysis(_ analysis: String?) async -> String? {
        guard let details else {
            return "Unable to load the stock details for this analysis."
        }

        errorMessage = nil

        do {
            let saved = try await service.updateStock(
                StockResponse(
                    id: details.id,
                    symbol: details.symbol,
                    shares: details.shares,
                    buyPrice: details.buyPrice,
                    buyDate: details.buyDate,
                    notes: analysis
                )
            )
            self.details = saved
            return nil
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            errorMessage = message
            return message
        }
    }

    private func loadHistory(symbol: String) async -> [StockHistory] {
        do {
            return try await service.fetchStockHistory(symbol: symbol)
        } catch {
            return []
        }
    }

    private func loadNews(symbol: String) async -> [StockNews] {
        do {
            return try await service.fetchStockNews(symbol: symbol)
        } catch {
            return []
        }
    }

    private func loadValuation(symbol: String) async -> StockValuationRequest? {
        do {
            return try await service.getValuation(symbol: symbol)
        } catch let error as StockHTTPClient.Error {
            switch error {
            case .invalidStatus(404):
                return nil
            case let .api(message) where message.localizedCaseInsensitiveContains("valuation not found"):
                return nil
            default:
                errorMessage = error.errorDescription ?? error.localizedDescription
                return nil
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }

    private func loadCompanyProfile(symbol: String) async -> CompanyProfileResponse? {
        do {
            return try await marketDataService.fetchCompanyProfile(symbol: symbol)
        } catch {
            return nil
        }
    }

    private func loadQuote(symbol: String) async -> StockMarketSnapshot? {
        do {
            return try await marketDataService.fetchQuote(symbol: symbol)
        } catch {
            return nil
        }
    }

    private func loadAnalystConsensus(symbol: String) async -> AnalystConsensusLoadResult {
        guard StockAnalystConsensus.isSupportedTicker(symbol) else {
            return AnalystConsensusLoadResult(
                consensus: nil,
                message: StockAnalystConsensus.unsupportedPlanMessage(for: symbol)
            )
        }

        do {
            let consensus = try await marketDataService.fetchAnalystConsensus(symbol: symbol)
            return AnalystConsensusLoadResult(consensus: consensus, message: nil)
        } catch let error as MarketDataHTTPClient.Error {
            if let message = error.errorDescription,
               message.localizedCaseInsensitiveContains("premium")
                || message.localizedCaseInsensitiveContains("subscription") {
                return AnalystConsensusLoadResult(
                    consensus: nil,
                    message: StockAnalystConsensus.unsupportedPlanMessage(for: symbol)
                )
            }
            return AnalystConsensusLoadResult(consensus: nil, message: nil)
        } catch {
            return AnalystConsensusLoadResult(consensus: nil, message: nil)
        }
    }

    private func loadBasicFinancials(symbol: String) async -> StockBasicFinancials? {
        do {
            return try await marketDataService.fetchBasicFinancials(symbol: symbol)
        } catch {
            return nil
        }
    }

    private func loadAnalysisMetrics(symbol: String) async -> AnalysisMetricsLoadResult {
        guard FMPFreeTierCoverage.isSupportedTicker(symbol) else {
            return AnalysisMetricsLoadResult(
                metrics: nil,
                message: FMPFreeTierCoverage.unsupportedAnalysisMessage(for: symbol)
            )
        }

        do {
            let metrics = try await marketDataService.fetchAnalysisMetrics(symbol: symbol)
            return AnalysisMetricsLoadResult(metrics: metrics, message: nil)
        } catch let error as MarketDataHTTPClient.Error {
            if let message = error.errorDescription,
               message.localizedCaseInsensitiveContains("free-tier coverage")
                || message.localizedCaseInsensitiveContains("premium")
                || message.localizedCaseInsensitiveContains("subscription") {
                return AnalysisMetricsLoadResult(
                    metrics: nil,
                    message: FMPFreeTierCoverage.unsupportedAnalysisMessage(for: symbol)
                )
            }
            return AnalysisMetricsLoadResult(metrics: nil, message: nil)
        } catch {
            return AnalysisMetricsLoadResult(metrics: nil, message: nil)
        }
    }

    private func loadFinancialStatements(symbol: String) async -> FinancialStatementsLoadResult {
        guard FMPFreeTierCoverage.isSupportedTicker(symbol) else {
            return FinancialStatementsLoadResult(
                statements: nil,
                message: FMPFreeTierCoverage.unsupportedStatementsMessage(for: symbol)
            )
        }

        async let balanceSheetsResult = loadFinancialStatementsSection(emptyValue: [BalanceSheetStatementResponse]()) {
            try await marketDataService.fetchBalanceSheetStatement(symbol: symbol, limit: 10, period: nil)
        }
        async let cashFlowsResult = loadFinancialStatementsSection(emptyValue: [CashFlowStatementResponse]()) {
            try await marketDataService.fetchCashFlowStatement(symbol: symbol, limit: 10, period: nil)
        }
        async let ratiosResult = loadFinancialStatementsSection(emptyValue: [RatiosResponse]()) {
            try await marketDataService.fetchRatios(symbol: symbol, limit: 10, period: nil)
        }
        async let ratiosTTMResult = loadFinancialStatementsSection(emptyValue: [RatiosTTMResponse]()) {
            try await marketDataService.fetchRatiosTTM(symbol: symbol)
        }
        async let growthResult = loadFinancialStatementsSection(emptyValue: [FinancialGrowthResponse]()) {
            try await marketDataService.fetchFinancialGrowth(symbol: symbol, limit: 10, period: nil)
        }
        async let estimatesResult = loadFinancialStatementsSection(emptyValue: [AnalystEstimatesResponse]()) {
            try await marketDataService.fetchAnalystEstimates(symbol: symbol, limit: 10, period: nil)
        }

        let balanceSheets = await balanceSheetsResult
        let cashFlows = await cashFlowsResult
        let ratios = await ratiosResult
        let ratiosTTM = await ratiosTTMResult
        let growth = await growthResult
        let estimates = await estimatesResult

        if [balanceSheets.isUnsupportedPlan, cashFlows.isUnsupportedPlan, ratios.isUnsupportedPlan, ratiosTTM.isUnsupportedPlan, growth.isUnsupportedPlan, estimates.isUnsupportedPlan]
            .contains(true) {
            return FinancialStatementsLoadResult(
                statements: nil,
                message: FMPFreeTierCoverage.unsupportedStatementsMessage(for: symbol)
            )
        }

        let statements = StockFinancialStatements.from(
            symbol: symbol,
            balanceSheets: balanceSheets.value,
            cashFlows: cashFlows.value,
            ratios: ratios.value,
            ratiosTTM: ratiosTTM.value,
            growth: growth.value,
            estimates: estimates.value
        )

        let hasAnyStatementsData =
            !balanceSheets.value.isEmpty
            || !cashFlows.value.isEmpty
            || !ratios.value.isEmpty
            || !ratiosTTM.value.isEmpty
            || !growth.value.isEmpty
            || !estimates.value.isEmpty

        if hasAnyStatementsData {
            return FinancialStatementsLoadResult(statements: statements, message: nil)
        }

        let firstErrorMessage = [
            balanceSheets.message,
            cashFlows.message,
            ratios.message,
            ratiosTTM.message,
            growth.message,
            estimates.message,
        ].compactMap { $0 }.first

        if let firstErrorMessage {
            return FinancialStatementsLoadResult(statements: nil, message: firstErrorMessage)
        }

        return FinancialStatementsLoadResult(statements: statements, message: nil)
    }

    private func loadFinancialStatementsSection<Value>(
        emptyValue: Value,
        operation: () async throws -> Value
    ) async -> FinancialStatementsSectionLoadResult<Value> {
        do {
            return FinancialStatementsSectionLoadResult(
                value: try await operation(),
                message: nil,
                isUnsupportedPlan: false
            )
        } catch let error as MarketDataHTTPClient.Error {
            let message = error.errorDescription ?? error.localizedDescription
            if isUnsupportedStatementsError(message: message) {
                return FinancialStatementsSectionLoadResult(
                    value: emptyValue,
                    message: nil,
                    isUnsupportedPlan: true
                )
            }
            if isMissingStatementsDataError(error) {
                return FinancialStatementsSectionLoadResult(
                    value: emptyValue,
                    message: nil,
                    isUnsupportedPlan: false
                )
            }
            return FinancialStatementsSectionLoadResult(
                value: emptyValue,
                message: message,
                isUnsupportedPlan: false
            )
        } catch {
            return FinancialStatementsSectionLoadResult(
                value: emptyValue,
                message: error.localizedDescription,
                isUnsupportedPlan: false
            )
        }
    }

    private func isUnsupportedStatementsError(message: String) -> Bool {
        message.localizedCaseInsensitiveContains("free-tier coverage")
            || message.localizedCaseInsensitiveContains("premium")
            || message.localizedCaseInsensitiveContains("subscription")
            || message.localizedCaseInsensitiveContains("unsupported symbol")
    }

    private func isMissingStatementsDataError(_ error: MarketDataHTTPClient.Error) -> Bool {
        switch error {
        case .invalidStatus(404):
            return true
        case .invalidStatus:
            return false
        case let .api(message):
            return message.localizedCaseInsensitiveContains("not found")
                || message.localizedCaseInsensitiveContains("no data")
                || message.localizedCaseInsensitiveContains("no financial")
                || message.localizedCaseInsensitiveContains("no analyst estimates")
        case .invalidResponse, .unauthorized(_):
            return false
        }
    }

    private func seedMockInsights(for symbol: String) {
        let normalizedSymbol = symbol.uppercased()
        let universe = StockInsightsMockStore.universe(for: normalizedSymbol)
        comparisonUniverse = universe
        primaryComparisonProfile = universe.first { $0.symbol == normalizedSymbol }
            ?? StockInsightsMockStore.profile(for: normalizedSymbol)
        selectedPeerSymbols = []
        fillMissingPeers()
    }

    private func applyAnalysisMetrics(_ metrics: StockAnalysisMetrics?, to symbol: String) {
        guard let metrics else { return }

        let normalizedSymbol = symbol.uppercased()
        if let primaryComparisonProfile, primaryComparisonProfile.symbol == normalizedSymbol {
            self.primaryComparisonProfile = StockComparisonProfile(
                symbol: primaryComparisonProfile.symbol,
                companyName: primaryComparisonProfile.companyName,
                currentPrice: primaryComparisonProfile.currentPrice,
                marketCap: primaryComparisonProfile.marketCap,
                sharesOutstanding: primaryComparisonProfile.sharesOutstanding,
                metrics: metrics.comparisonMetrics,
                projectionScenarios: primaryComparisonProfile.projectionScenarios
            )
        }
    }


    private func fillMissingPeers() {
        guard let primaryComparisonProfile else { return }

        var resolved = selectedPeerSymbols.filter { $0 != primaryComparisonProfile.symbol }
        let defaults = comparisonUniverse
            .map(\.symbol)
            .filter { $0 != primaryComparisonProfile.symbol && !resolved.contains($0) }

        resolved.append(contentsOf: defaults.prefix(max(0, 2 - resolved.count)))
        selectedPeerSymbols = Array(resolved.prefix(2))
    }
}
