//
//  YahooFinanceStockQuoteMapper.swift
//  StockWatch
//

enum YahooFinanceStockQuoteMapper {
    static func map(ticker: String, quote: YahooFinanceQuoteDTO) -> StockQuote {
        let meta = quote.chart.result?.first?.meta
        let currentPrice = meta?.regularMarketPrice ?? 0.0
        let previousClose = meta?.previousClose ?? meta?.chartPreviousClose ?? 0.0
        let priceChangePercent: Double
        if let apiPercent = meta?.regularMarketChangePercent {
            priceChangePercent = apiPercent
        } else if previousClose > 0 {
            priceChangePercent = ((currentPrice - previousClose) / previousClose) * 100
        } else {
            priceChangePercent = 0.0
        }
        let currency = meta?.currency ?? ticker.currencyFromTickerSuffix
        return StockQuote(
            ticker: ticker,
            currentPrice: currentPrice,
            priceChangePercent: priceChangePercent,
            currency: currency
        )
    }
}
