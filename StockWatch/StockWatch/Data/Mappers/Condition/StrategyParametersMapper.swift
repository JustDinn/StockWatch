//
//  StrategyParametersMapper.swift
//  StockWatch
//

import Foundation

/// StrategyParameters ↔ JSON 변환 Mapper
enum StrategyParametersMapper {

    // MARK: - Encode

    /// StrategyParameters → JSON 문자열
    static func encode(_ parameters: StrategyParameters) -> String {
        let dict: [String: Any]

        switch parameters {
        case let .sma(shortPeriod, longPeriod):
            dict = ["type": "sma", "shortPeriod": shortPeriod, "longPeriod": longPeriod]
        case let .ema(shortPeriod, longPeriod):
            dict = ["type": "ema", "shortPeriod": shortPeriod, "longPeriod": longPeriod]
        case let .rsi(period, oversoldThreshold, overboughtThreshold):
            dict = [
                "type": "rsi",
                "period": period,
                "oversoldThreshold": oversoldThreshold,
                "overboughtThreshold": overboughtThreshold
            ]
        }

        guard
            let data = try? JSONSerialization.data(withJSONObject: dict),
            let json = String(data: data, encoding: .utf8)
        else { return "{}" }

        return json
    }

    // MARK: - Decode

    /// JSON 문자열 → StrategyParameters
    static func decode(_ json: String) -> StrategyParameters? {
        guard
            let data = json.data(using: .utf8),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type_ = dict["type"] as? String
        else { return nil }

        switch type_ {
        case "sma":
            guard
                let shortPeriod = dict["shortPeriod"] as? Int,
                let longPeriod = dict["longPeriod"] as? Int
            else { return nil }
            return .sma(shortPeriod: shortPeriod, longPeriod: longPeriod)

        case "ema":
            guard
                let shortPeriod = dict["shortPeriod"] as? Int,
                let longPeriod = dict["longPeriod"] as? Int
            else { return nil }
            return .ema(shortPeriod: shortPeriod, longPeriod: longPeriod)

        case "rsi":
            guard
                let period = dict["period"] as? Int,
                let oversoldThreshold = dict["oversoldThreshold"] as? Double,
                let overboughtThreshold = dict["overboughtThreshold"] as? Double
            else { return nil }
            return .rsi(
                period: period,
                oversoldThreshold: oversoldThreshold,
                overboughtThreshold: overboughtThreshold
            )

        default:
            return nil
        }
    }
}
