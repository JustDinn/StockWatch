//
//  TechnicalIndicatorMapper.swift
//  StockWatch
//

import Foundation

/// TechnicalIndicatorDTO → StrategySignal 변환 Mapper
enum TechnicalIndicatorMapper {

    // MARK: - SMA

    static func mapSMA(
        ticker: String,
        shortDTO: TechnicalIndicatorDTO,
        longDTO: TechnicalIndicatorDTO,
        shortPeriod: Int,
        longPeriod: Int
    ) -> StrategySignal {
        guard
            let shortValue = shortDTO.sma?.last,
            let longValue = longDTO.sma?.last
        else {
            return StrategySignal(
                strategyId: "sma_cross",
                ticker: ticker,
                signalType: .neutral,
                description: "SMA 데이터를 불러올 수 없습니다",
                evaluatedAt: Date()
            )
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

        return StrategySignal(
            strategyId: "sma_cross",
            ticker: ticker,
            signalType: signal,
            description: description,
            evaluatedAt: Date()
        )
    }

    // MARK: - EMA

    static func mapEMA(
        ticker: String,
        shortDTO: TechnicalIndicatorDTO,
        longDTO: TechnicalIndicatorDTO,
        shortPeriod: Int,
        longPeriod: Int
    ) -> StrategySignal {
        guard
            let shortValue = shortDTO.ema?.last,
            let longValue = longDTO.ema?.last
        else {
            return StrategySignal(
                strategyId: "ema_cross",
                ticker: ticker,
                signalType: .neutral,
                description: "EMA 데이터를 불러올 수 없습니다",
                evaluatedAt: Date()
            )
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

        return StrategySignal(
            strategyId: "ema_cross",
            ticker: ticker,
            signalType: signal,
            description: description,
            evaluatedAt: Date()
        )
    }

    // MARK: - RSI

    static func mapRSI(
        ticker: String,
        dto: TechnicalIndicatorDTO,
        period: Int,
        oversoldThreshold: Double,
        overboughtThreshold: Double
    ) -> StrategySignal {
        guard let rsiValue = dto.rsi?.last else {
            return StrategySignal(
                strategyId: "rsi",
                ticker: ticker,
                signalType: .neutral,
                description: "RSI 데이터를 불러올 수 없습니다",
                evaluatedAt: Date()
            )
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

        return StrategySignal(
            strategyId: "rsi",
            ticker: ticker,
            signalType: signal,
            description: description,
            evaluatedAt: Date()
        )
    }
}
