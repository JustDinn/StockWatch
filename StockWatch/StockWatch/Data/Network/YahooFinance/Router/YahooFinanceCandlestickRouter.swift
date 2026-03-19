//
//  YahooFinanceCandlestickRouter.swift
//  StockWatch
//

import Alamofire

struct YahooFinanceCandlestickRouter: NetworkRouter {
    let symbol: String

    var apiService: APIService { .yahooFinance }
    var path: String { "/v8/finance/chart/\(symbol)" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
    }
    var parameters: [String: Any]? {
        ["range": "3mo", "interval": "1d"]
    }
}
