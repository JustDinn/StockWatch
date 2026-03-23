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
        try validateName(name)
        return try await repository.createGroup(name: name)
    }

    func deleteGroup(id: UUID) async throws {
        try await repository.deleteGroup(id: id)
    }

    func renameGroup(id: UUID, name: String) async throws {
        try validateName(name)
        try await repository.renameGroup(id: id, name: name)
    }

    private func validateName(_ name: String) throws {
        guard name.count <= 20 else { throw WatchListGroupError.tooLong(max: 20) }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WatchListGroupError.onlyWhitespace
        }
    }

    func reorderGroups(orderedIds: [UUID]) async throws {
        try await repository.reorderGroups(orderedIds: orderedIds)
    }
}
