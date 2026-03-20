//
//  FetchCandlestickUseCase.swift
//  StockWatch
//

import Foundation

enum FetchCandlestickError: Error {
    case emptyTicker
}

protocol FetchCandlestickUseCaseProtocol {
    func execute(ticker: String, period: ChartPeriod) async throws -> CandlestickData
    func fetchOlderCandles(ticker: String, period: ChartPeriod, before: Date) async throws -> CandlestickData
}

final class FetchCandlestickUseCase: FetchCandlestickUseCaseProtocol {

    /// 초기 차트 표시 캔들 수 (좌측 스크롤로 과거 데이터 추가 로드 가능)
    private let initialCandleCount = 20

    private let repository: CandlestickRepositoryProtocol

    init(repository: CandlestickRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String, period: ChartPeriod) async throws -> CandlestickData {
        guard !ticker.isEmpty else { throw FetchCandlestickError.emptyTicker }
        let data = try await repository.fetchCandlesticks(ticker: ticker, period: period)
        let limited = Array(data.candles.suffix(initialCandleCount))
        return CandlestickData(ticker: data.ticker, candles: limited)
    }

    func fetchOlderCandles(ticker: String, period: ChartPeriod, before: Date) async throws -> CandlestickData {
        guard !ticker.isEmpty else { throw FetchCandlestickError.emptyTicker }
        let period2 = Int(before.timeIntervalSince1970)
        let pageInterval: TimeInterval
        switch period {
        case .day:   pageInterval = 60 * 60 * 24 * 180   // 6개월
        case .week:  pageInterval = 60 * 60 * 24 * 365 * 2  // 2년
        case .month: pageInterval = 60 * 60 * 24 * 365 * 5  // 5년
        case .year:  pageInterval = 60 * 60 * 24 * 365 * 20 // 20년
        }
        let period1 = Int(before.timeIntervalSince1970 - pageInterval)
        return try await repository.fetchCandlesticks(
            ticker: ticker,
            interval: period.interval,
            period1: period1,
            period2: period2
        )
    }
}
