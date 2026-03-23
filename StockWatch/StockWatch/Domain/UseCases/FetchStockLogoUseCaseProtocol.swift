//
//  FetchStockLogoUseCaseProtocol.swift
//  StockWatch
//

protocol FetchStockLogoUseCaseProtocol {
    func execute(ticker: String) async throws -> String
}
