//
//  YahooFinanceStockDetailMapper.swift
//  StockWatch
//

enum YahooFinanceStockDetailMapper {
    static func map(
        ticker: String,
        quote: YahooFinanceQuoteDTO,
        logoURL: String
    ) -> StockDetail {
        let meta = quote.chart.result?.first?.meta
        let currentPrice = meta?.regularMarketPrice ?? 0.0
        let previousClose = meta?.previousClose ?? 0.0
        let priceChangePercent = previousClose > 0
            ? ((currentPrice - previousClose) / previousClose) * 100
            : 0.0
        return StockDetail(
            ticker: ticker,
            companyName: meta?.longName ?? meta?.shortName ?? ticker,
            currentPrice: currentPrice,
            priceChangePercent: priceChangePercent,
            logoURL: logoURL
        )
    }
}
