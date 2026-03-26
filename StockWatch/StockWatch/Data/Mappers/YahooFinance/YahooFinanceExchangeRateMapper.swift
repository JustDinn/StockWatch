//
//  YahooFinanceExchangeRateMapper.swift
//  StockWatch
//

/// Yahoo Finance Quote DTO에서 환율 값을 추출하는 Mapper
/// 기존 YahooFinanceQuoteDTO를 재사용한다 (같은 /v8/finance/chart 엔드포인트).
enum YahooFinanceExchangeRateMapper {
    static func map(currency: String, dto: YahooFinanceQuoteDTO) -> Double {
        dto.chart.result?.first?.meta.regularMarketPrice ?? 0.0
    }
}
