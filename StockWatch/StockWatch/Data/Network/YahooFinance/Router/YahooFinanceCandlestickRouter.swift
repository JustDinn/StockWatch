//
//  YahooFinanceCandlestickRouter.swift
//  StockWatch
//

import Alamofire

struct YahooFinanceCandlestickRouter: NetworkRouter {
    let symbol: String
    let range: String
    let interval: String

    var apiService: APIService { .yahooFinance }
    var path: String { "/v8/finance/chart/\(symbol)" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
    }
    var parameters: [String: Any]? {
        ["range": range, "interval": interval]
    }
}

struct YahooFinanceCandlestickPaginatedRouter: NetworkRouter {
    let symbol: String
    let interval: String
    let period1: Int
    let period2: Int

    var apiService: APIService { .yahooFinance }
    var path: String { "/v8/finance/chart/\(symbol)" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
    }
    var parameters: [String: Any]? {
        ["period1": period1, "period2": period2, "interval": interval]
    }
}
