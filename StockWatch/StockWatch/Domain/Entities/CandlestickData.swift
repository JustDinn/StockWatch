//
//  CandlestickData.swift
//  StockWatch
//

import Foundation

struct Candle: Equatable {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct CandlestickData: Equatable {
    let ticker: String
    let candles: [Candle]
}
