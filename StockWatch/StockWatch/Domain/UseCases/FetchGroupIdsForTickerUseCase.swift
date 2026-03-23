//
//  FetchGroupIdsForTickerUseCase.swift
//  StockWatch
//

import Foundation

final class FetchGroupIdsForTickerUseCase: FetchGroupIdsForTickerUseCaseProtocol {
    private let repository: FavoriteRepositoryProtocol

    init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }

    func execute(ticker: String) async -> [UUID] {
        await repository.fetchGroupIds(for: ticker)
    }
}
