//
//  YahooFinanceSearchRouter.swift
//  StockWatch
//

import Alamofire

struct YahooFinanceSearchRouter: NetworkRouter {
    let query: String

    var apiService: APIService { .yahooFinance }
    var path: String { "/v1/finance/search" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
    }
    var parameters: [String: Any]? {
        ["q": query, "quotesCount": 10, "newsCount": 0]
    }
}
