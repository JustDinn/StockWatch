//
//  FinnhubIndicatorRouter.swift
//  StockWatch
//

import Alamofire
import Foundation

/// Finnhub /indicator Router (기술 지표: SMA, EMA, RSI)
struct FinnhubIndicatorRouter: NetworkRouter {
    let symbol: String
    let resolution: String     // "D" = daily
    let from: Int              // Unix timestamp (시작)
    let to: Int                // Unix timestamp (종료)
    let indicator: String      // "sma", "ema", "rsi"
    let indicatorFields: String // JSON 문자열 (예: {"timeperiod":14})
    let apiKey: String

    var apiService: APIService { .finnhub }
    var path: String { "/indicator" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? { nil }
    var parameters: [String: Any]? {
        [
            "symbol": symbol,
            "resolution": resolution,
            "from": from,
            "to": to,
            "indicator": indicator,
            "indicatorFields": indicatorFields,
            "token": apiKey
        ]
    }
}

extension FinnhubIndicatorRouter {

    /// SMA 지표 Router 생성 (단기 + 장기)
    static func sma(
        symbol: String,
        period: Int,
        apiKey: String
    ) -> FinnhubIndicatorRouter {
        let to = Int(Date().timeIntervalSince1970)
        let from = to - 60 * 60 * 24 * 365  // 1년 전
        return FinnhubIndicatorRouter(
            symbol: symbol,
            resolution: "D",
            from: from,
            to: to,
            indicator: "sma",
            indicatorFields: "{\"timeperiod\":\(period)}",
            apiKey: apiKey
        )
    }

    /// EMA 지표 Router 생성
    static func ema(
        symbol: String,
        period: Int,
        apiKey: String
    ) -> FinnhubIndicatorRouter {
        let to = Int(Date().timeIntervalSince1970)
        let from = to - 60 * 60 * 24 * 365
        return FinnhubIndicatorRouter(
            symbol: symbol,
            resolution: "D",
            from: from,
            to: to,
            indicator: "ema",
            indicatorFields: "{\"timeperiod\":\(period)}",
            apiKey: apiKey
        )
    }

    /// RSI 지표 Router 생성
    static func rsi(
        symbol: String,
        period: Int,
        apiKey: String
    ) -> FinnhubIndicatorRouter {
        let to = Int(Date().timeIntervalSince1970)
        let from = to - 60 * 60 * 24 * 365
        return FinnhubIndicatorRouter(
            symbol: symbol,
            resolution: "D",
            from: from,
            to: to,
            indicator: "rsi",
            indicatorFields: "{\"timeperiod\":\(period)}",
            apiKey: apiKey
        )
    }
}
