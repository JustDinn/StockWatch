//
//  CandlestickRepositoryProtocol.swift
//  StockWatch
//

protocol CandlestickRepositoryProtocol {
    func fetchCandlesticks(ticker: String, period: ChartPeriod) async throws -> CandlestickData
    func fetchCandlesticks(ticker: String, interval: String, period1: Int, period2: Int) async throws -> CandlestickData
}
