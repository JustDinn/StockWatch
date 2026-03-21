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
}
