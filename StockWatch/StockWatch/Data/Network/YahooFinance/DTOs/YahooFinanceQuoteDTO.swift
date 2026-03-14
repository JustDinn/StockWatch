//
//  YahooFinanceQuoteDTO.swift
//  StockWatch
//

struct YahooFinanceQuoteDTO: Decodable {
    let chart: ChartContainer

    struct ChartContainer: Decodable {
        let result: [ChartResult]?
        let error: ChartError?
    }

    struct ChartResult: Decodable {
        let meta: Meta
    }

    struct Meta: Decodable {
        let symbol: String
        let regularMarketPrice: Double?
        let previousClose: Double?
        let shortName: String?
        let longName: String?
    }

    struct ChartError: Decodable {
        let code: String
        let description: String
    }
}
