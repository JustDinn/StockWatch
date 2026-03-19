//
//  YahooFinanceCandlestickMapper.swift
//  StockWatch
//

import Foundation

final class YahooFinanceCandlestickMapper {

    func map(dto: YahooFinanceCandlestickDTO, ticker: String) -> CandlestickData {
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
            let timestamp = Date(timeIntervalSince1970: timestamps[i])

            return Candle(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }

        return CandlestickData(ticker: ticker, candles: candles)
    }
}
