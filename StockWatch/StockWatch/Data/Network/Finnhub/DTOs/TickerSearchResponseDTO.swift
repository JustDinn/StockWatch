//
//  SymbolSearchResponseDTO.swift
//  StockWatch
//

import Foundation

/// Finnhub 티커 검색 API 응답 DTO
struct TickerSearchResponseDTO: Decodable {
    let count: Int
    let result: [TickerSearchItemDTO]
}

/// Finnhub 티커 개별 항목 DTO
struct TickerSearchItemDTO: Decodable {
    let description: String
    let displayTicker: String
    let ticker: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case description
        case displayTicker = "displaySymbol"
        case ticker = "symbol"
        case type
    }
}
