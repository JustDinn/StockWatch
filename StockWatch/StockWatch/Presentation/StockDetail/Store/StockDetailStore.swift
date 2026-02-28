//
//  StockDetailStore.swift
//  StockWatch
//

import Foundation

/// StockDetail 화면 Store
@MainActor
final class StockDetailStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: StockDetailState

    // MARK: - Init

    init(ticker: String, companyName: String) {
        self.state = StockDetailState(
            ticker: ticker,
            companyName: companyName,
            currentPrice: 306.54,
            priceChangePercent: 1.06
        )
    }

    // MARK: - Action

    func action(_ intent: StockDetailIntent) {
        switch intent {
        case .dismiss:
            break
        }
    }
}
