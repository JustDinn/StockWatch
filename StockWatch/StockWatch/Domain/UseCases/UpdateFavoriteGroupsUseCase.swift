//
//  UpdateFavoriteGroupsUseCase.swift
//  StockWatch
//

import Foundation

final class UpdateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCaseProtocol {
    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String, companyName: String, logoURL: String, groupIds: [UUID]) async throws {
        if groupIds.isEmpty {
            try await repository.removeFavorite(ticker: ticker)
        } else {
            let isAlreadyFavorite = await repository.isFavorite(ticker: ticker)
            if isAlreadyFavorite {
                try await repository.updateFavoriteGroups(ticker: ticker, logoURL: logoURL, groupIds: groupIds)
            } else {
                try await repository.addFavorite(ticker: ticker, companyName: companyName, logoURL: logoURL, groupIds: groupIds)
            }
        }
    }
}
