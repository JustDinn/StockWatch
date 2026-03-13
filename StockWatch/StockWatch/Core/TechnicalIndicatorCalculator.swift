//
//  TechnicalIndicatorCalculator.swift
//  StockWatch
//

import Foundation

/// SMA, EMA, RSI를 종가 배열로부터 로컬에서 계산하는 유틸리티
enum TechnicalIndicatorCalculator {

    /// Simple Moving Average — 마지막 `period`개 종가의 평균
    static func sma(closes: [Double], period: Int) -> Double? {
        guard closes.count >= period, period > 0 else { return nil }
        let slice = closes.suffix(period)
        return slice.reduce(0, +) / Double(period)
    }

    /// Exponential Moving Average — multiplier = 2/(period+1), SMA 시드
    static func ema(closes: [Double], period: Int) -> Double? {
        guard closes.count >= period, period > 0 else { return nil }
        let k = 2.0 / Double(period + 1)
        var ema = closes.prefix(period).reduce(0, +) / Double(period)
        for close in closes.dropFirst(period) {
            ema = close * k + ema * (1 - k)
        }
        return ema
    }

    /// RSI — Wilder's smoothed 방식 (`period + 1`개 이상 종가 필요)
    static func rsi(closes: [Double], period: Int) -> Double? {
        guard closes.count > period, period > 0 else { return nil }
        let changes = zip(closes, closes.dropFirst()).map { $1 - $0 }
        let initialGains = changes.prefix(period).filter { $0 > 0 }
        let initialLosses = changes.prefix(period).filter { $0 < 0 }.map { abs($0) }
        var avgGain = initialGains.reduce(0, +) / Double(period)
        var avgLoss = initialLosses.reduce(0, +) / Double(period)
        for change in changes.dropFirst(period) {
            avgGain = (avgGain * Double(period - 1) + max(change, 0)) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + abs(min(change, 0))) / Double(period)
        }
        guard avgLoss > 0 else { return 100 }
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
}
