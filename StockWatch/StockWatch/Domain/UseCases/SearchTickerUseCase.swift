//
//  SearchTickerUseCase.swift
//  StockWatch
//

/// 종목 검색 UseCase 구현체
/// 검색어를 받아 Repository를 통해 검색 결과를 반환한다.
final class SearchTickerUseCase: SearchTickerUseCaseProtocol {

    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(query: String) async throws -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        return try await repository.search(query: query)
    }
}
