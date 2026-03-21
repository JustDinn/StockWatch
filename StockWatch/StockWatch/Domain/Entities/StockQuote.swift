//
//  StockQuote.swift
//  StockWatch
//

/// 종목 현재가/등락률을 나타내는 경량 도메인 엔티티
/// Yahoo Finance Quote API만 사용하며, 로고/회사명은 포함하지 않는다.
struct StockQuote: Equatable {
    let ticker: String
    let currentPrice: Double
    let priceChangePercent: Double
    let currency: String    // 통화 코드 (예: "KRW", "USD", "JPY")
}
