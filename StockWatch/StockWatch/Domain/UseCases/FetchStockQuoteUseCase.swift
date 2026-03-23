//
//  FetchStockQuoteUseCase.swift
//  StockWatch
//

/// StockQuote 도메인 UseCase 구현체
final class FetchStockQuoteUseCase: FetchStockQuoteUseCaseProtocol {

    private let repository: StockQuoteRepositoryProtocol

    init(repository: StockQuoteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async throws -> StockQuote {
        guard !ticker.isEmpty else {
            throw FetchStockQuoteError.emptyTicker
        }
        return try await repository.fetchStockQuote(ticker: ticker)
    }
}

enum FetchStockQuoteError: Error {
    case emptyTicker
}
