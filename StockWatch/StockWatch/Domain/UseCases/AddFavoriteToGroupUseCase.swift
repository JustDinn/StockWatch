//
//  AddFavoriteToGroupUseCase.swift
//  StockWatch
//

import Foundation

/// 특정 그룹에 관심 종목을 추가하는 UseCase 구현체
final class AddFavoriteToGroupUseCase: AddFavoriteToGroupUseCaseProtocol {

    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String, companyName: String, groupId: UUID) async throws {
        let isFav = await repository.isFavorite(ticker: ticker)
        if isFav {
            let existingGroupIds = await repository.fetchGroupIds(for: ticker)
            guard !existingGroupIds.contains(groupId) else { return }
            try await repository.updateFavoriteGroups(
                ticker: ticker,
                logoURL: "",
                groupIds: existingGroupIds + [groupId]
            )
        } else {
            try await repository.addFavorite(
                ticker: ticker,
                companyName: companyName,
                logoURL: "",
                groupIds: [groupId]
            )
        }
    }
}
