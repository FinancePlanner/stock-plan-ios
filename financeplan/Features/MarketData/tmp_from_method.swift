func from(
    symbol: String,
    balanceSheets: [BalanceSheetStatementResponse],
    cashFlows: [CashFlowStatementResponse],
    ratios: [RatiosResponse],
    ratiosTTM: [RatiosTTMResponse],
    growth: [FinancialGrowthResponse],
    estimates: [AnalystEstimatesResponse]
  ) -> StockFinancialStatements {
    let ttmSnapshots: [StockFinancialMetricSnapshot] = ratiosTTM.map { res in
      StockFinancialMetricSnapshot(
        date: "TTM",
        symbol: res.symbol,
        fiscalYear: nil,
        period: "TTM",
        reportedCurrency: nil,
        entries: [
          .init(id: "grossProfitMarginTTM", title: "Gross margin", value: res.grossProfitMarginTTM, format: .percentFraction),
          .init(id: "netProfitMarginTTM", title: "Net margin", value: res.netProfitMarginTTM, format: .percentFraction),
          .init(id: "operatingProfitMarginTTM", title: "Operating margin", value: res.operatingProfitMarginTTM, format: .percentFraction),
          .init(id: "returnOnEquityTTM", title: "Return on equity", value: res.debtToEquityRatioTTM, format: .percentFraction),
          .init(id: "currentRatioTTM", title: "Current ratio", value: res.currentRatioTTM, format: .multiple(decimals: 2)),
          .init(id: "quickRatioTTM", title: "Quick ratio", value: res.quickRatioTTM, format: .multiple(decimals: 2)),
          .init(id: "priceToEarningsRatioTTM", title: "P/E ratio", value: res.priceToEarningsRatioTTM, format: .multiple(decimals: 2)),
          .init(id: "priceToBookRatioTTM", title: "P/B ratio", value: res.priceToBookRatioTTM, format: .multiple(decimals: 2)),
          .init(id: "priceToSalesRatioTTM", title: "P/S ratio", value: res.priceToSalesRatioTTM, format: .multiple(decimals: 2)),
          .init(id: "dividendYieldTTM", title: "Dividend yield", value: res.dividendYieldTTM, format: .percentFraction)
        ]
      )
    }

    let historicalRatios: [StockFinancialMetricSnapshot] = ratios.map { res in
      StockFinancialMetricSnapshot(
        date: res.date,
        symbol: res.symbol,
        fiscalYear: res.fiscalYear,
        period: res.period,
        reportedCurrency: res.reportedCurrency,
        entries: [
          .init(id: "grossProfitMargin", title: "Gross margin", value: res.grossProfitMargin, format: .percentFraction),
          .init(id: "netProfitMargin", title: "Net margin", value: res.netProfitMargin, format: .percentFraction),
          .init(id: "operatingProfitMargin", title: "Operating margin", value: res.operatingProfitMargin, format: .percentFraction),
          .init(id: "returnOnEquity", title: "Return on equity", value: res.debtToEquityRatio, format: .percentFraction),
          .init(id: "currentRatio", title: "Current ratio", value: res.currentRatio, format: .multiple(decimals: 2)),
          .init(id: "quickRatio", title: "Quick ratio", value: res.quickRatio, format: .multiple(decimals: 2)),
          .init(id: "priceToEarningsRatio", title: "P/E ratio", value: res.priceToEarningsRatio, format: .multiple(decimals: 2)),
          .init(id: "priceToBookRatio", title: "P/B ratio", value: res.priceToBookRatio, format: .multiple(decimals: 2)),
          .init(id: "priceToSalesRatio", title: "P/S ratio", value: res.priceToSalesRatio, format: .multiple(decimals: 2)),
          .init(id: "dividendYield", title: "Dividend yield", value: res.dividendYield, format: .percentFraction)
        ]
      )
    }

    return StockFinancialStatements(
      symbol: symbol,
      balanceSheets: balanceSheets.map { res in
        StockFinancialStatement(
          date: res.date,
          symbol: res.symbol,
          reportedCurrency: res.reportedCurrency ?? "USD",
          cik: res.cik ?? "",
          filingDate: res.filingDate ?? res.date,
          acceptedDate: res.acceptedDate ?? res.date,
          fiscalYear: res.fiscalYear ?? "",
          period: res.period ?? "FY",
          entries: [
            .init(id: "cashAndCashEquivalents", title: "Cash & equivalents", value: res.cashAndCashEquivalents ?? 0),
            .init(id: "shortTermInvestments", title: "Short-term investments", value: res.shortTermInvestments ?? 0),
            .init(id: "cashAndShortTermInvestments", title: "Cash + short-term investments", value: res.cashAndShortTermInvestments ?? 0),
            .init(id: "netReceivables", title: "Net receivables", value: res.netReceivables ?? 0),
            .init(id: "inventory", title: "Inventory", value: res.inventory ?? 0),
            .init(id: "totalCurrentAssets", title: "Total current assets", value: res.totalCurrentAssets ?? 0),
            .init(id: "propertyPlantEquipmentNet", title: "PP&E, net", value: res.propertyPlantEquipmentNet ?? 0),
            .init(id: "goodwillAndIntangibleAssets", title: "Goodwill & intangibles", value: res.goodwillAndIntangibleAssets ?? 0),
            .init(id: "totalAssets", title: "Total assets", value: res.totalAssets ?? 0),
            .init(id: "accountPayables", title: "Accounts payables", value: res.accountPayables ?? 0),
            .init(id: "totalCurrentLiabilities", title: "Total current liabilities", value: res.totalCurrentLiabilities ?? 0),
            .init(id: "longTermDebt", title: "Long-term debt", value: res.longTermDebt ?? 0),
            .init(id: "totalLiabilities", title: "Total liabilities", value: res.totalLiabilities ?? 0),
            .init(id: "totalStockholdersEquity", title: "Total stockholders equity", value: res.totalStockholdersEquity ?? 0),
            .init(id: "totalEquity", title: "Total equity", value: res.totalEquity ?? 0)
          ]
        )
      },
      cashFlows: cashFlows.map { res in
        StockFinancialStatement(
          date: res.date,
          symbol: res.symbol,
          reportedCurrency: res.reportedCurrency ?? "USD",
          cik: res.cik ?? "",
          filingDate: res.filingDate ?? res.date,
          acceptedDate: res.acceptedDate ?? res.date,
          fiscalYear: res.fiscalYear ?? "",
          period: res.period ?? "FY",
          entries: [
            .init(id: "netIncome", title: "Net income", value: res.netIncome ?? 0),
            .init(id: "depreciationAndAmortization", title: "D&A", value: res.depreciationAndAmortization ?? 0),
            .init(id: "stockBasedCompensation", title: "Stock-based comp", value: res.stockBasedCompensation ?? 0),
            .init(id: "operatingCashFlow", title: "Operating cash flow", value: res.operatingCashFlow ?? 0),
            .init(id: "capitalExpenditure", title: "Capital expenditure", value: res.capitalExpenditure ?? 0),
            .init(id: "freeCashFlow", title: "Free cash flow", value: res.freeCashFlow ?? 0),
            .init(id: "commonStockRepurchased", title: "Common stock repurchased", value: res.commonStockRepurchased ?? 0),
            .init(id: "commonDividendsPaid", title: "Common dividends paid", value: res.commonDividendsPaid ?? 0)
          ]
        )
      },
      ratios: ttmSnapshots + historicalRatios,
      growth: growth.map { res in
        StockFinancialMetricSnapshot(
          date: res.date,
          symbol: res.symbol,
          fiscalYear: res.fiscalYear,
          period: res.period,
          reportedCurrency: res.reportedCurrency,
          entries: [
            .init(id: "revenueGrowth", title: "Revenue growth", value: res.revenueGrowth, format: .percentFraction),
            .init(id: "netIncomeGrowth", title: "Net income growth", value: res.netIncomeGrowth, format: .percentFraction),
            .init(id: "epsgrowth", title: "EPS growth", value: res.epsgrowth, format: .percentFraction),
            .init(id: "operatingCashFlowGrowth", title: "Operating CF growth", value: res.operatingCashFlowGrowth, format: .percentFraction),
            .init(id: "freeCashFlowGrowth", title: "Free CF growth", value: res.freeCashFlowGrowth, format: .percentFraction),
            .init(id: "fiveYRevenueGrowthPerShare", title: "5Y Rev/Share growth", value: res.fiveYRevenueGrowthPerShare, format: .percentFraction),
            .init(id: "fiveYNetIncomeGrowthPerShare", title: "5Y NetInc/Share growth", value: res.fiveYNetIncomeGrowthPerShare, format: .percentFraction)
          ]
        )
      },
      estimates: estimates.map { res in
        StockFinancialMetricSnapshot(
          date: res.date,
          symbol: res.symbol,
          fiscalYear: nil,
          period: nil,
          reportedCurrency: nil,
          entries: [
            .init(id: "revenueAvg", title: "Revenue avg", value: res.revenueAvg, format: .currencyCompact),
            .init(id: "ebitdaAvg", title: "EBITDA avg", value: res.ebitdaAvg, format: .currencyCompact),
            .init(id: "netIncomeAvg", title: "Net income avg", value: res.netIncomeAvg, format: .currencyCompact),
            .init(id: "epsAvg", title: "EPS avg", value: res.epsAvg, format: .currency(decimals: 2)),
            .init(id: "numAnalystsRevenue", title: "Revenue analysts", value: Double(res.numAnalystsRevenue ?? 0), format: .count),
            .init(id: "numAnalystsEps", title: "EPS analysts", value: Double(res.numAnalystsEps ?? 0), format: .count)
          ]
        )
      }
    )
  }
