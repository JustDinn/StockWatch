//
//  FinnhubStockDetailRouter.swift
//  StockWatch
//

import Alamofire

/// Finnhub /stock/profile2 Router (기업명 + 로고)
struct FinnhubStockProfileRouter: NetworkRouter {
    let symbol: String
    let apiKey: String

    var apiService: APIService { .finnhub }
    var path: String { "/stock/profile2" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? { nil }
    var parameters: [String: Any]? {
        ["symbol": symbol, "token": apiKey]
    }
}
