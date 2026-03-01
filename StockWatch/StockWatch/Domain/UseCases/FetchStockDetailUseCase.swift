//
//  FetchStockDetailUseCase.swift
//  StockWatch
//

/// StockDetail 도메인 UseCase 구현체
final class FetchStockDetailUseCase: FetchStockDetailUseCaseProtocol {

    private let repository: StockDetailRepositoryProtocol

    init(repository: StockDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async throws -> StockDetail {
        guard !ticker.isEmpty else {
            throw FetchStockDetailError.emptyTicker
        }
        return try await repository.fetchStockDetail(ticker: ticker)
    }
}

enum FetchStockDetailError: Error {
    case emptyTicker
}
