//
//  YahooFinanceChartRouter.swift
//  StockWatch
//

import Alamofire
import Foundation

/// Yahoo Finance v8 /chart Router (일별 OHLCV 데이터)
struct YahooFinanceChartRouter: NetworkRouter {
    let symbol: String
    let period1: Int    // Unix timestamp (시작)
    let period2: Int    // Unix timestamp (종료)
    let interval: String    // "1d" = 일봉

    var apiService: APIService { .yahooFinance }
    var path: String { "/v8/finance/chart/\(symbol)" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
    }
    var parameters: [String: Any]? {
        [
            "period1": period1,
            "period2": period2,
            "interval": interval
        ]
    }
}

extension YahooFinanceChartRouter {

    /// 일봉 데이터 Router 생성
    /// - Parameters:
    ///   - symbol: 종목 티커 (예: "AAPL")
    ///   - daysBack: 조회할 과거 일수. EMA(200) 수렴을 위해 기본 400일 사용
    static func dailyChart(symbol: String, daysBack: Int = 400) -> YahooFinanceChartRouter {
        let to = Int(Date().timeIntervalSince1970)
        let from = to - 60 * 60 * 24 * daysBack
        return YahooFinanceChartRouter(symbol: symbol, period1: from, period2: to, interval: "1d")
    }
}
