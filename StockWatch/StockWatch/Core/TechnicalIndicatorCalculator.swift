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

    /// Simple Moving Average Time Series — 각 캔들마다 SMA 값 계산
    /// - Parameters:
    ///   - candles: 캔들 데이터 배열
    ///   - period: 이동평균 기간
    ///   - priceSource: 계산 기준 가격 (종가/시가)
    /// - Returns: (timestamp, sma value) 배열. period개 미만은 건너뜀.
    static func smaTimeSeries(candles: [Candle], period: Int, priceSource: MAPriceSource = .close) -> [(timestamp: Date, value: Double)] {
        guard period > 0, !candles.isEmpty else { return [] }

        let keyPath: KeyPath<Candle, Double> = priceSource == .close ? \.close : \.open
        var result: [(Date, Double)] = []

        for index in 0..<candles.count {
            // period개 이상의 데이터가 있을 때부터 계산
            guard index + 1 >= period else { continue }

            let startIndex = index + 1 - period
            let endIndex = index + 1
            let slice = candles[startIndex..<endIndex]
            let average = slice.map { $0[keyPath: keyPath] }.reduce(0, +) / Double(period)

            result.append((candles[index].timestamp, average))
        }

        return result
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

    /// Exponential Moving Average Time Series — 각 캔들마다 EMA 값 계산
    /// - Parameters:
    ///   - candles: 캔들 데이터 배열
    ///   - period: 이동평균 기간
    ///   - priceSource: 계산 기준 가격 (종가/시가)
    /// - Returns: (timestamp, ema value) 배열. period개 미만은 건너뜀.
    static func emaTimeSeries(candles: [Candle], period: Int, priceSource: EMAPriceSource = .close) -> [(timestamp: Date, value: Double)] {
        guard period > 0, !candles.isEmpty, candles.count >= period else { return [] }

        let keyPath: KeyPath<Candle, Double> = priceSource == .close ? \.close : \.open
        var result: [(Date, Double)] = []

        // multiplier k = 2 / (period + 1)
        let k = 2.0 / Double(period + 1)

        // 첫 EMA 값은 SMA로 초기화 (index = period - 1)
        let initialSlice = candles.prefix(period)
        var ema = initialSlice.map { $0[keyPath: keyPath] }.reduce(0, +) / Double(period)
        result.append((candles[period - 1].timestamp, ema))

        // 이후 EMA 값 계산
        for index in period..<candles.count {
            let price = candles[index][keyPath: keyPath]
            ema = price * k + ema * (1 - k)
            result.append((candles[index].timestamp, ema))
        }

        return result
    }

    /// Volume Simple Moving Average Time Series — 각 캔들마다 거래량 SMA 값 계산
    /// - Parameters:
    ///   - candles: 캔들 데이터 배열
    ///   - period: 이동평균 기간
    /// - Returns: (timestamp, sma value) 배열. period개 미만은 건너뜀.
    static func volumeSmaTimeSeries(candles: [Candle], period: Int) -> [(timestamp: Date, value: Double)] {
        guard period > 0, !candles.isEmpty else { return [] }

        var result: [(Date, Double)] = []

        for index in 0..<candles.count {
            guard index + 1 >= period else { continue }

            let startIndex = index + 1 - period
            let endIndex = index + 1
            let slice = candles[startIndex..<endIndex]
            let average = slice.map { $0.volume }.reduce(0, +) / Double(period)

            result.append((candles[index].timestamp, average))
        }

        return result
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

    /// RSI Time Series — 각 캔들 시점마다 Wilder's Smoothed RSI 값 계산
    /// - Parameters:
    ///   - candles: 캔들 데이터 배열 (시간순 정렬)
    ///   - period: RSI 기간 (통상 14)
    /// - Returns: (timestamp, rsi value) 배열. `period + 1`개 미만은 건너뜀.
    static func rsiTimeSeries(candles: [Candle], period: Int) -> [(timestamp: Date, value: Double)] {
        guard period > 0, candles.count > period else { return [] }

        let closes = candles.map(\.close)
        var result: [(Date, Double)] = []

        // period개 변화량으로 초기 avgGain/avgLoss 계산 (초기 SMA 시드)
        var avgGain: Double = 0
        var avgLoss: Double = 0
        for i in 1...period {
            let change = closes[i] - closes[i - 1]
            avgGain += max(change, 0)
            avgLoss += abs(min(change, 0))
        }
        avgGain /= Double(period)
        avgLoss /= Double(period)

        // period번째 캔들(index = period)이 첫 번째 RSI 값
        let firstRSI: Double
        if avgLoss == 0 {
            firstRSI = 100
        } else {
            firstRSI = 100 - (100 / (1 + avgGain / avgLoss))
        }
        result.append((candles[period].timestamp, firstRSI))

        // 이후 Wilder's Smoothed 방식으로 계속 계산
        for i in (period + 1)..<candles.count {
            let change = closes[i] - closes[i - 1]
            avgGain = (avgGain * Double(period - 1) + max(change, 0)) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + abs(min(change, 0))) / Double(period)

            let rsiValue: Double
            if avgLoss == 0 {
                rsiValue = 100
            } else {
                rsiValue = 100 - (100 / (1 + avgGain / avgLoss))
            }
            result.append((candles[i].timestamp, rsiValue))
        }

        return result
    }
}
