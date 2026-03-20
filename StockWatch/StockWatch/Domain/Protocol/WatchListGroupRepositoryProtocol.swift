//
//  WatchListGroupRepositoryProtocol.swift
//  StockWatch
//

import Foundation

protocol WatchListGroupRepositoryProtocol {
    func fetchAllGroups() async -> [WatchListGroup]
    func createGroup(name: String) async throws -> WatchListGroup
    func deleteGroup(id: UUID) async throws
}
