//
//  YahooFinanceChartDTO.swift
//  StockWatch
//

import Foundation

/// Yahoo Finance v8 /chart 응답 DTO
struct YahooFinanceChartDTO: Decodable {
    let chart: ChartContainer

    struct ChartContainer: Decodable {
        let result: [ChartResult]?
        let error: ChartError?
    }

    struct ChartResult: Decodable {
        let indicators: Indicators
    }

    struct Indicators: Decodable {
        let quote: [Quote]?
    }

    struct Quote: Decodable {
        let close: [Double?]?
    }

    struct ChartError: Decodable {
        let code: String
        let description: String
    }
}
