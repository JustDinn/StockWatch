//
//  FetchFavoritesUseCase.swift
//  StockWatch
//

/// 관심 종목 목록 조회 UseCase 구현체
final class FetchFavoritesUseCase: FetchFavoritesUseCaseProtocol {

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async -> [String] {
        await repository.fetchAllFavorites()
    }
}
