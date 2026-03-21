//
//  ManageWatchListGroupUseCase.swift
//  StockWatch
//

import Foundation

final class ManageWatchListGroupUseCase: ManageWatchListGroupUseCaseProtocol {
    private let repository: WatchListGroupRepositoryProtocol

    init(repository: WatchListGroupRepositoryProtocol) {
        self.repository = repository
    }

    func fetchGroups() async -> [WatchListGroup] {
        return await repository.fetchAllGroups()
    }

    func createGroup(name: String) async throws -> WatchListGroup {
        return try await repository.createGroup(name: name)
    }

    func deleteGroup(id: UUID) async throws {
        try await repository.deleteGroup(id: id)
    }
}
