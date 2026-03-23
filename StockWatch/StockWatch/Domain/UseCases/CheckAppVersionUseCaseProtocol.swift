//
//  CheckAppVersionUseCaseProtocol.swift
//  StockWatch
//

protocol CheckAppVersionUseCaseProtocol {
    func execute(currentVersion: String) async throws -> AppVersionStatus
}
