//
//  CandlestickRepositoryProtocol.swift
//  StockWatch
//

protocol CandlestickRepositoryProtocol {
    func fetchCandlesticks(ticker: String, period: ChartPeriod) async throws -> CandlestickData
}
