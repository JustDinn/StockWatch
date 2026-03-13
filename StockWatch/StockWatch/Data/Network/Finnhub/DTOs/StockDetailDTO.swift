//
//  StockDetailDTO.swift
//  StockWatch
//

import Foundation

/// Finnhub /quote 응답 DTO
struct QuoteResponseDTO: Decodable {
    let c: Double   /// 현재가 (Current price)
    let d: Double?  /// 전일 대비 변동액 (Change) - 거래 없을 시 null
    let dp: Double? /// 전일 대비 변동률 (Percent change) - 거래 없을 시 null
    let h: Double   /// 고가
    let l: Double   /// 저가
    let o: Double   /// 시가
    let pc: Double  /// 전일 종가
}

/// Finnhub /stock/profile2 응답 DTO
struct StockProfileDTO: Decodable {
    let name: String?       /// 기업명
    let logo: String?       /// 로고 이미지 URL
    let ticker: String?     /// 티커 심볼
    let country: String?
    let currency: String?
    let exchange: String?
}
