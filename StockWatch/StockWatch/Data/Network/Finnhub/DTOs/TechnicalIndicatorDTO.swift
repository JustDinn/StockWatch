//
//  TechnicalIndicatorDTO.swift
//  StockWatch
//

/// Finnhub /indicator 응답 DTO
struct TechnicalIndicatorDTO: Decodable {
    /// 기술 지표 값 배열 (가장 최근 값이 마지막 인덱스)
    let sma: [Double]?
    let ema: [Double]?
    let rsi: [Double]?
    /// 응답 상태 ("ok" = 성공)
    let s: String
}
