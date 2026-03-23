//
//  AppVersionRepositoryProtocol.swift
//  StockWatch
//

protocol AppVersionRepositoryProtocol {
    func fetchMinimumVersion() async throws -> (minimumVersion: String, storeURL: String)
}
