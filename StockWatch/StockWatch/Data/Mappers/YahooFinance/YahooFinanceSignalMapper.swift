//
//  YahooFinanceSignalMapper.swift
//  StockWatch
//

import Foundation

/// 종가 배열([Double]) + StrategyParameters → StrategySignal 변환 Mapper
enum YahooFinanceSignalMapper {

    static func map(
        ticker: String,
        closes: [Double],
        parameters: StrategyParameters
    ) -> StrategySignal {
        switch parameters {
        case let .sma(shortPeriod, longPeriod):
            return mapSMA(ticker: ticker, closes: closes, shortPeriod: shortPeriod, longPeriod: longPeriod)
        case let .ema(shortPeriod, longPeriod):
            return mapEMA(ticker: ticker, closes: closes, shortPeriod: shortPeriod, longPeriod: longPeriod)
        case let .rsi(period, oversoldThreshold, overboughtThreshold):
            return mapRSI(
                ticker: ticker,
                closes: closes,
                period: period,
                oversoldThreshold: oversoldThreshold,
                overboughtThreshold: overboughtThreshold
            )
        }
    }

    // MARK: - Private

    private static func mapSMA(
        ticker: String,
        closes: [Double],
        shortPeriod: Int,
        longPeriod: Int
    ) -> StrategySignal {
        guard
            let shortValue = TechnicalIndicatorCalculator.sma(closes: closes, period: shortPeriod),
            let longValue = TechnicalIndicatorCalculator.sma(closes: closes, period: longPeriod)
        else {
            return neutralSignal(strategyId: "sma_cross", ticker: ticker, reason: "SMA 데이터가 부족합니다")
        }

        let signal: SignalType
        let description: String

        if shortValue > longValue {
            signal = .buy
            description = "SMA(\(shortPeriod)) = \(String(format: "%.2f", shortValue)), SMA(\(longPeriod)) = \(String(format: "%.2f", longValue)) → 골든크로스 (매수 신호)"
        } else if shortValue < longValue {
            signal = .sell
            description = "SMA(\(shortPeriod)) = \(String(format: "%.2f", shortValue)), SMA(\(longPeriod)) = \(String(format: "%.2f", longValue)) → 데드크로스 (매도 신호)"
        } else {
            signal = .neutral
            description = "SMA(\(shortPeriod)) = SMA(\(longPeriod)) = \(String(format: "%.2f", shortValue)) → 중립"
        }

        return StrategySignal(strategyId: "sma_cross", ticker: ticker, signalType: signal, description: description, evaluatedAt: Date())
    }

    private static func mapEMA(
        ticker: String,
        closes: [Double],
        shortPeriod: Int,
        longPeriod: Int
    ) -> StrategySignal {
        guard
            let shortValue = TechnicalIndicatorCalculator.ema(closes: closes, period: shortPeriod),
            let longValue = TechnicalIndicatorCalculator.ema(closes: closes, period: longPeriod)
        else {
            return neutralSignal(strategyId: "ema_cross", ticker: ticker, reason: "EMA 데이터가 부족합니다")
        }

        let signal: SignalType
        let description: String

        if shortValue > longValue {
            signal = .buy
            description = "EMA(\(shortPeriod)) = \(String(format: "%.2f", shortValue)), EMA(\(longPeriod)) = \(String(format: "%.2f", longValue)) → 골든크로스 (매수 신호)"
        } else if shortValue < longValue {
            signal = .sell
            description = "EMA(\(shortPeriod)) = \(String(format: "%.2f", shortValue)), EMA(\(longPeriod)) = \(String(format: "%.2f", longValue)) → 데드크로스 (매도 신호)"
        } else {
            signal = .neutral
            description = "EMA(\(shortPeriod)) = EMA(\(longPeriod)) = \(String(format: "%.2f", shortValue)) → 중립"
        }

        return StrategySignal(strategyId: "ema_cross", ticker: ticker, signalType: signal, description: description, evaluatedAt: Date())
    }

    private static func mapRSI(
        ticker: String,
        closes: [Double],
        period: Int,
        oversoldThreshold: Double,
        overboughtThreshold: Double
    ) -> StrategySignal {
        guard let rsiValue = TechnicalIndicatorCalculator.rsi(closes: closes, period: period) else {
            return neutralSignal(strategyId: "rsi", ticker: ticker, reason: "RSI 데이터가 부족합니다")
        }

        let signal: SignalType
        let description: String

        if rsiValue <= oversoldThreshold {
            signal = .buy
            description = "RSI(\(period)) = \(String(format: "%.1f", rsiValue)) → 과매도 (매수 신호)"
        } else if rsiValue >= overboughtThreshold {
            signal = .sell
            description = "RSI(\(period)) = \(String(format: "%.1f", rsiValue)) → 과매수 (매도 신호)"
        } else {
            signal = .neutral
            description = "RSI(\(period)) = \(String(format: "%.1f", rsiValue)) → 중립"
        }

        return StrategySignal(strategyId: "rsi", ticker: ticker, signalType: signal, description: description, evaluatedAt: Date())
    }

    private static func neutralSignal(strategyId: String, ticker: String, reason: String) -> StrategySignal {
        StrategySignal(strategyId: strategyId, ticker: ticker, signalType: .neutral, description: reason, evaluatedAt: Date())
    }
}
