//
//  ManageWatchListGroupUseCaseProtocol.swift
//  StockWatch
//

import Foundation

protocol ManageWatchListGroupUseCaseProtocol {
    func fetchGroups() async -> [WatchListGroup]
    func createGroup(name: String) async throws -> WatchListGroup
    func deleteGroup(id: UUID) async throws
    func renameGroup(id: UUID, name: String) async throws
    func reorderGroups(orderedIds: [UUID]) async throws
}
