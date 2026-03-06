//
//  CheckFavoriteUseCase.swift
//  StockWatch
//

/// 관심 종목 여부 확인 UseCase 구현체
final class CheckFavoriteUseCase: CheckFavoriteUseCaseProtocol {

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async -> Bool {
        await repository.isFavorite(ticker: ticker)
    }
}
