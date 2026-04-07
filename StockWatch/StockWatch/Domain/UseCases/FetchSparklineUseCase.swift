//
//  FetchSparklineUseCase.swift
//  StockWatch
//

/// 스파크라인 데이터 조회 UseCase 구현체
final class FetchSparklineUseCase: FetchSparklineUseCaseProtocol {

    private let repository: CandlestickRepositoryProtocol

    init(repository: CandlestickRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async throws -> SparklineData {
        guard !ticker.isEmpty else {
            throw FetchSparklineError.emptyTicker
        }
        let candlestickData = try await repository.fetchCandlesticks(
            ticker: ticker,
            range: "5d",
            interval: "30m"
        )
        let closePrices = candlestickData.candles.map(\.close)
        return SparklineData(ticker: ticker, closePrices: closePrices)
    }
}

enum FetchSparklineError: Error {
    case emptyTicker
}
