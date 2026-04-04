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
    /// 주봉 기본 range("2y")로 확보 가능한 근사 캔들 수
    private let defaultWeeklyCapacity = 104
    /// 월봉 기본 range("5y")로 확보 가능한 근사 캔들 수
    private let defaultMonthlyCapacity = 60

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
        } else if period == .week && totalNeeded > defaultWeeklyCapacity {
            // 주봉 2y=~104개로 부족할 때 5y=~260개로 확장
            data = try await repository.fetchCandlesticks(ticker: ticker, range: "5y", interval: period.interval)
        } else if period == .month && totalNeeded > defaultMonthlyCapacity {
            // 월봉 5y=~60개로 부족할 때 10y=~120개로 확장
            data = try await repository.fetchCandlesticks(ticker: ticker, range: "10y", interval: period.interval)
        } else if period == .year {
            // Yahoo Finance가 interval=1y를 더 이상 지원하지 않으므로
            // interval=3mo(분기봉)로 받아 연도별로 집계하여 년봉으로 변환
            // period1/period2 방식은 약 52개(13년치) 분기봉 반환 제한이 있으므로
            // range=max 방식으로 상장일 이후 전체 분기봉을 받아 집계
            let quarterly = try await repository.fetchCandlesticks(ticker: ticker, range: "max", interval: "3mo")
            data = aggregateToYearly(quarterly, ticker: ticker)
        } else {
            data = try await repository.fetchCandlesticks(ticker: ticker, period: period)
        }
        // 년봉은 전체 데이터가 적으므로(예: NVDA 28개) suffix 없이 전체 반환
        // suffix로 자르면 RSI 계산에 필요한 히스토리(period개)가 부족해짐
        let limited = period == .year ? data.candles : Array(data.candles.suffix(totalNeeded))
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

        // 년봉은 interval=1y 미지원 → range=max+3mo로 받아 연도별 집계
        // period1/period2 방식은 약 52개(13년치) 제한이 있으므로 range=max 사용
        if period == .year {
            let quarterly = try await repository.fetchCandlesticks(ticker: ticker, range: "max", interval: "3mo")
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
