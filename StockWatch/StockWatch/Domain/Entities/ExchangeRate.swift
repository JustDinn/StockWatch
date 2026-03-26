//
//  ExchangeRate.swift
//  StockWatch
//

/// 환율 정보를 나타내는 경량 도메인 엔티티
/// rateToUSD: 1 USD = rateToUSD 해당 통화 (예: KRW이면 1380.0)
struct ExchangeRate: Equatable {
    let currency: String
    let rateToUSD: Double
}
