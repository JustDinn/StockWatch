//
//  SearchTickerUseCase.swift
//  StockWatch
//

/// Ticker 도메인 UseCase 구현체
final class TickerUseCase: TickerUseCaseProtocol {

    private let repository: TickerRepositoryProtocol

    init(repository: TickerRepositoryProtocol) {
        self.repository = repository
    }

    func search(query: String) async throws -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        return try await repository.search(query: query)
    }
}
