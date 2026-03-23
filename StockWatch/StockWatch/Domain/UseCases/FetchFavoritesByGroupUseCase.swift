//
//  FetchFavoritesByGroupUseCase.swift
//  StockWatch
//

import Foundation

final class FetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCaseProtocol {
    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(groupId: UUID) async -> [FavoriteItem] {
        await repository.fetchFavorites(in: groupId)
    }
}
