//
//  FinnhubSearchRouter.swift
//  StockWatch
//

import Alamofire

/// Finnhub 종목 검색 API Router
struct FinnhubSearchRouter: NetworkRouter {
    let query: String
    let apiKey: String
    
    var apiService: APIService { .finnhub }
    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? { nil }
    var parameters: [String: Any]? {
        ["q": query, "token": apiKey]
    }
}
