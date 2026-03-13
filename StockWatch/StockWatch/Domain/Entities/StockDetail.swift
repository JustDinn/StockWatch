//
//  StockDetail.swift
//  StockWatch
//

/// 종목 상세 정보를 나타내는 도메인 엔티티
/// Finnhub /quote + /stock/profile2 응답을 합산한 결과
struct StockDetail: Equatable {
    let ticker: String
    let companyName: String
    let currentPrice: Double
    let priceChangePercent: Double
    let logoURL: String     // 빈 문자열이면 이니셜 폴백
}
