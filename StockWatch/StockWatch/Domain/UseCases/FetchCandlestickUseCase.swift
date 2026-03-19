//
//  FetchCandlestickUseCase.swift
//  StockWatch
//

enum FetchCandlestickError: Error {
    case emptyTicker
}

protocol FetchCandlestickUseCaseProtocol {
    func execute(ticker: String) async throws -> CandlestickData
}

final class FetchCandlestickUseCase: FetchCandlestickUseCaseProtocol {

    private let repository: CandlestickRepositoryProtocol

    init(repository: CandlestickRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async throws -> CandlestickData {
        guard !ticker.isEmpty else { throw FetchCandlestickError.emptyTicker }
        return try await repository.fetchCandlesticks(ticker: ticker)
    }
}
