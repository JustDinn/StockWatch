//
//  FetchGroupIdsForTickerUseCaseProtocol.swift
//  StockWatch
//

import Foundation

protocol FetchGroupIdsForTickerUseCaseProtocol {
    func execute(ticker: String) async -> [UUID]
}
