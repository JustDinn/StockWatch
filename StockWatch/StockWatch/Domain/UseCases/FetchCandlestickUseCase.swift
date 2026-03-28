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
        print("<< [Execute] ticker=\(ticker) period=\(period) warmupCount=\(warmupCount) totalNeeded=\(totalNeeded)")
        let data: CandlestickData
        if period == .day && totalNeeded > defaultDailyCapacity {
            data = try await repository.fetchCandlesticks(ticker: ticker, range: "2y", interval: period.interval)
        } else {
            data = try await repository.fetchCandlesticks(ticker: ticker, period: period)
        }
        let limited = Array(data.candles.suffix(totalNeeded))
        print("<< [Execute] 전체 가져온 캔들=\(data.candles.count) suffix 후=\(limited.count)")
        return CandlestickData(ticker: data.ticker, candles: limited)
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
        let warmupInterval = intervalSeconds * Double(warmupCount)
        let period1 = Int(before.timeIntervalSince1970 - pageInterval - warmupInterval)
        print("<< [FetchOlderCandles] ticker=\(ticker) period=\(period) before=\(before) warmupCount=\(warmupCount) pageInterval=\(pageInterval/86400)일 warmupInterval=\(warmupInterval/86400)일")
        let result = try await repository.fetchCandlesticks(
            ticker: ticker,
            interval: period.interval,
            period1: period1,
            period2: period2
        )
        print("<< [FetchOlderCandles] 반환된 캔들 수=\(result.candles.count)")
        return result
    }
}
