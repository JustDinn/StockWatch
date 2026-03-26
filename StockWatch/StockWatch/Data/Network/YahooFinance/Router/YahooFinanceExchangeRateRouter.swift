//
//  YahooFinanceExchangeRateRouter.swift
//  StockWatch
//

import Alamofire

/// Yahoo Finance 환율 조회 Router
/// symbol 예: "KRW=X" → 1 USD = X KRW
struct YahooFinanceExchangeRateRouter: NetworkRouter {
    let currency: String

    var apiService: APIService { .yahooFinance }
    var path: String { "/v8/finance/chart/\(currency)=X" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
    }
    var parameters: [String: Any]? {
        ["range": "1d", "interval": "1d"]
    }
}
