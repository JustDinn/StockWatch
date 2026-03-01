//
//  StockDetailDTO.swift
//  StockWatch
//

import Foundation

/// Finnhub /quote 응답 DTO
struct QuoteResponseDTO: Decodable {
    /// 현재가 (Current price)
    let c: Double
    /// 전일 대비 변동액 (Change) - 거래 없을 시 null
    let d: Double?
    /// 전일 대비 변동률 (Percent change) - 거래 없을 시 null
    let dp: Double?
    /// 고가
    let h: Double
    /// 저가
    let l: Double
    /// 시가
    let o: Double
    /// 전일 종가
    let pc: Double
}

/// Finnhub /stock/profile2 응답 DTO
struct StockProfileDTO: Decodable {
    /// 기업명
    let name: String
    /// 로고 이미지 URL
    let logo: String
    /// 티커 심볼
    let ticker: String
    let country: String?
    let currency: String?
    let exchange: String?
}
