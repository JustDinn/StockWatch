//
//  YahooFinanceCandlestickDTO.swift
//  StockWatch
//

struct YahooFinanceCandlestickDTO: Decodable {
    let chart: ChartContainer

    struct ChartContainer: Decodable {
        let result: [ChartResult]?
        let error: ChartError?
    }

    struct ChartResult: Decodable {
        let timestamp: [Double]?
        let indicators: Indicators?
    }

    struct Indicators: Decodable {
        let quote: [Quote]?
    }

    struct Quote: Decodable {
        let open: [Double?]?
        let high: [Double?]?
        let low: [Double?]?
        let close: [Double?]?
        let volume: [Double?]?
    }

    struct ChartError: Decodable {
        let code: String
        let description: String
    }
}
