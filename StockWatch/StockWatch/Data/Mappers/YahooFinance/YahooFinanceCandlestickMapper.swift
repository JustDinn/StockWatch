//
//  YahooFinanceCandlestickMapper.swift
//  StockWatch
//

import Foundation

final class YahooFinanceCandlestickMapper {

    func map(dto: YahooFinanceCandlestickDTO, ticker: String, interval: String = "1d") -> CandlestickData {
        guard
            let result = dto.chart.result?.first,
            let timestamps = result.timestamp,
            let quote = result.indicators?.quote?.first
        else {
            return CandlestickData(ticker: ticker, candles: [])
        }

        let opens = quote.open ?? []
        let highs = quote.high ?? []
        let lows = quote.low ?? []
        let closes = quote.close ?? []
        let volumes = quote.volume ?? []

        let candles: [Candle] = timestamps.indices.compactMap { i in
            guard
                i < opens.count, let open = opens[i],
                i < highs.count, let high = highs[i],
                i < lows.count, let low = lows[i],
                i < closes.count, let close = closes[i]
            else { return nil }

            let volume = (i < volumes.count ? volumes[i] : nil) ?? 0.0
            let rawDate = Date(timeIntervalSince1970: timestamps[i])
            let timestamp = normalizeTimestamp(rawDate, interval: interval)

            return Candle(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }

        let deduplicated = candles.reduce(into: [Date: Candle]()) { dict, candle in
            dict[candle.timestamp] = candle
        }
        let sortedCandles = deduplicated.values.sorted { $0.timestamp < $1.timestamp }
        return CandlestickData(ticker: ticker, candles: sortedCandles)
    }

    private func normalizeTimestamp(_ date: Date, interval: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        switch interval {
        case "1wk":
            // 해당 주의 월요일 자정으로 정규화 (weekday: 1=Sun, 2=Mon, ..., 7=Sat)
            let weekday = calendar.component(.weekday, from: date)
            let daysToMonday = weekday == 1 ? -6 : -(weekday - 2)
            let monday = calendar.date(byAdding: .day, value: daysToMonday, to: date) ?? date
            let components = calendar.dateComponents([.year, .month, .day], from: monday)
            return calendar.date(from: components) ?? date
        case "1mo", "3mo":
            // 해당 달의 1일 자정으로 정규화
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? date
        default:
            // "1d": 해당 날짜의 자정으로 정규화 (기존 동작)
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return calendar.date(from: components) ?? date
        }
    }
}
