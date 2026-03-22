//
//  WatchListGroupRepositoryProtocol.swift
//  StockWatch
//

import Foundation

@MainActor
protocol WatchListGroupRepositoryProtocol {
    func fetchAllGroups() async -> [WatchListGroup]
    func createGroup(name: String) async throws -> WatchListGroup
    func deleteGroup(id: UUID) async throws
    func renameGroup(id: UUID, name: String) async throws
    func reorderGroups(orderedIds: [UUID]) async throws
}
