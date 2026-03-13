//
//  FinnhubStockDetailRouter.swift
//  StockWatch
//

import Alamofire

/// Finnhub /quote Router (현재가 + 변동률)
struct FinnhubQuoteRouter: NetworkRouter {
    let symbol: String
    let apiKey: String

    var apiService: APIService { .finnhub }
    var path: String { "/quote" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? { nil }
    var parameters: [String: Any]? {
        ["symbol": symbol, "token": apiKey]
    }
}

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
