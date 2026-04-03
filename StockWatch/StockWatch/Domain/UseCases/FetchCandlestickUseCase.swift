//
//  FetchCandlestickUseCase.swift
//  StockWatch
//

import Foundation

enum FetchCandlestickError: Error {
    case emptyTicker
}

protocol FetchCandlestickUseCaseProtocol {
    func execute(ticker: String, period: ChartPeriod, warmupCount: Int) async throws -> CandlestickData
    func fetchOlderCandles(ticker: String, period: ChartPeriod, before: Date, warmupCount: Int) async throws -> CandlestickData
}

extension FetchCandlestickUseCaseProtocol {
    func execute(ticker: String, period: ChartPeriod) async throws -> CandlestickData {
        try await execute(ticker: ticker, period: period, warmupCount: 0)
    }
}

final class FetchCandlestickUseCase: FetchCandlestickUseCaseProtocol {

    /// 초기 차트 표시 캔들 수 (좌측 스크롤로 과거 데이터 추가 로드 가능)
    private let initialCandleCount = 20
    /// 일봉 기본 range("6mo")로 확보 가능한 근사 캔들 수
    private let defaultDailyCapacity = 125

    private let repository: CandlestickRepositoryProtocol

    init(repository: CandlestickRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String, period: ChartPeriod, warmupCount: Int) async throws -> CandlestickData {
        guard !ticker.isEmpty else { throw FetchCandlestickError.emptyTicker }
        let totalNeeded = initialCandleCount + warmupCount
        let data: CandlestickData
        if period == .day && totalNeeded > defaultDailyCapacity {
            data = try await repository.fetchCandlesticks(ticker: ticker, range: "2y", interval: period.interval)
        } else if period == .year {
            // Yahoo Finance가 interval=1y를 더 이상 지원하지 않으므로
            // interval=3mo(분기봉)로 30년치를 받아 연도별로 집계하여 년봉으로 변환
            let period2 = Int(Date().timeIntervalSince1970)
            let period1 = period2 - Int(60 * 60 * 24 * 365 * 30)
            let quarterly = try await repository.fetchCandlesticks(ticker: ticker, interval: "3mo", period1: period1, period2: period2)
            data = aggregateToYearly(quarterly, ticker: ticker)
        } else {
            data = try await repository.fetchCandlesticks(ticker: ticker, period: period)
        }
        let limited = Array(data.candles.suffix(totalNeeded))
        return CandlestickData(ticker: data.ticker, candles: limited)
    }

    /// 분기봉(3mo) 데이터를 연도별로 집계하여 년봉으로 변환
    /// - open: 해당 연도 첫 분기봉의 open
    /// - high: 해당 연도 분기봉들 중 최고가
    /// - low: 해당 연도 분기봉들 중 최저가
    /// - close: 해당 연도 마지막 분기봉의 close
    /// - volume: 해당 연도 분기봉들의 volume 합계
    private func aggregateToYearly(_ data: CandlestickData, ticker: String) -> CandlestickData {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        // 연도별로 그룹핑
        var byYear: [Int: [Candle]] = [:]
        for candle in data.candles {
            let year = calendar.component(.year, from: candle.timestamp)
            byYear[year, default: []].append(candle)
        }

        let yearlyCandles: [Candle] = byYear.compactMap { year, candles in
            let sorted = candles.sorted { $0.timestamp < $1.timestamp }
            guard let first = sorted.first, let last = sorted.last else { return nil }
            // 해당 연도 1월 1일 자정(NYSE)으로 timestamp 설정
            var components = DateComponents()
            components.year = year
            components.month = 1
            components.day = 1
            let timestamp = calendar.date(from: components) ?? first.timestamp
            return Candle(
                timestamp: timestamp,
                open: first.open,
                high: sorted.map(\.high).max() ?? first.high,
                low: sorted.map(\.low).min() ?? first.low,
                close: last.close,
                volume: sorted.map(\.volume).reduce(0, +)
            )
        }.sorted { $0.timestamp < $1.timestamp }

        return CandlestickData(ticker: ticker, candles: yearlyCandles)
    }

    func fetchOlderCandles(ticker: String, period: ChartPeriod, before: Date, warmupCount: Int = 0) async throws -> CandlestickData {
        guard !ticker.isEmpty else { throw FetchCandlestickError.emptyTicker }
        let period2 = Int(before.timeIntervalSince1970)
        let pageInterval: TimeInterval
        let intervalSeconds: TimeInterval
        switch period {
        case .day:
            pageInterval = 60 * 60 * 24 * 180   // 6개월
            intervalSeconds = 60 * 60 * 24       // 1일
        case .week:
            pageInterval = 60 * 60 * 24 * 365 * 2  // 2년
            intervalSeconds = 60 * 60 * 24 * 7     // 1주
        case .month:
            pageInterval = 60 * 60 * 24 * 365 * 5  // 5년
            intervalSeconds = 60 * 60 * 24 * 30    // 30일
        case .year:
            pageInterval = 60 * 60 * 24 * 365 * 20 // 20년
            intervalSeconds = 60 * 60 * 24 * 365   // 1년
        }
        let warmupInterval = intervalSeconds * Double(warmupCount) * 1.5
        let period1 = Int(before.timeIntervalSince1970 - pageInterval - warmupInterval)

        // 년봉은 interval=1y 미지원 → 3mo로 받아 연도별 집계
        if period == .year {
            let quarterly = try await repository.fetchCandlesticks(
                ticker: ticker,
                interval: "3mo",
                period1: period1,
                period2: period2
            )
            return aggregateToYearly(quarterly, ticker: ticker)
        }

        let result = try await repository.fetchCandlesticks(
            ticker: ticker,
            interval: period.interval,
            period1: period1,
            period2: period2
        )
        return result
    }
}
