//
//  CandlestickRepositoryProtocol.swift
//  StockWatch
//

protocol CandlestickRepositoryProtocol {
    func fetchCandlesticks(ticker: String) async throws -> CandlestickData
}
