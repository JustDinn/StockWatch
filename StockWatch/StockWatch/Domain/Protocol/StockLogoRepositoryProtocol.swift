//
//  StockLogoRepositoryProtocol.swift
//  StockWatch
//

protocol StockLogoRepositoryProtocol {
    func fetchLogoURL(ticker: String) async throws -> String
}
