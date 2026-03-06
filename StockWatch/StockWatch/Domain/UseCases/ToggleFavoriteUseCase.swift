//
//  ToggleFavoriteUseCase.swift
//  StockWatch
//

/// 관심 종목 토글 UseCase 구현체
/// 현재 저장 상태를 확인하여 추가 또는 삭제를 수행한다.
final class ToggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol {

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async throws -> Bool {
        let currentlyFavorite = await repository.isFavorite(ticker: ticker)

        if currentlyFavorite {
            try await repository.removeFavorite(ticker: ticker)
            return false
        } else {
            try await repository.addFavorite(ticker: ticker)
            return true
        }
    }
}
