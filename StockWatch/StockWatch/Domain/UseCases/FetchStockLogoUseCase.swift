//
//  FetchStockLogoUseCase.swift
//  StockWatch
//

/// 기업 로고 URL을 fetch하는 UseCase 구현체
final class FetchStockLogoUseCase: FetchStockLogoUseCaseProtocol {

    private let repository: StockLogoRepositoryProtocol

    init(repository: StockLogoRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async throws -> String {
        guard !ticker.isEmpty else { return "" }
        return try await repository.fetchLogoURL(ticker: ticker)
    }
}
