//
//  ManageWatchListGroupUseCaseProtocol.swift
//  StockWatch
//

import Foundation

protocol ManageWatchListGroupUseCaseProtocol {
    func fetchGroups() async -> [WatchListGroup]
    func createGroup(name: String) async throws -> WatchListGroup
    func deleteGroup(id: UUID) async throws
    func ensureDefaultGroup() async throws -> WatchListGroup
}
