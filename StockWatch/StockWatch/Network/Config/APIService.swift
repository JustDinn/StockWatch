//
//  APIService.swift
//  StockWatch
//
//  Created by HyoTaek on 2/23/26.
//

/// 사용하는 API 정의
enum APIService {

    /// Finnhub API
    case finnhub

    /// Yahoo Finance API
    case yahooFinance

    /// Info.plist에서 조회할 키값
    var baseURLKey: String {
        switch self {
        case .finnhub:
            "FINNHUB_BASE_URL"
        case .yahooFinance:
            "YAHOO_FINANCE_BASE_URL"
        }
    }
}
