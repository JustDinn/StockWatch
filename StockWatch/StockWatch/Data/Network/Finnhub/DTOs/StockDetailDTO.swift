//
//  StockDetailDTO.swift
//  StockWatch
//

import Foundation

/// Finnhub /stock/profile2 응답 DTO
struct StockProfileDTO: Decodable {
    let name: String?       /// 기업명
    let logo: String?       /// 로고 이미지 URL
    let ticker: String?     /// 티커 심볼
    let country: String?
    let currency: String?
    let exchange: String?
}
