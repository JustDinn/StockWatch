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
    private let fetchStockDetailUseCase: FetchStockDetailUseCaseProtocol

    // MARK: - Init

    init(
        ticker: String,
        fetchStockDetailUseCase: FetchStockDetailUseCaseProtocol = FetchStockDetailUseCase(
            repository: StockDetailRepository()
        )
    ) {
        self.state = StockDetailState(ticker: ticker)
        self.fetchStockDetailUseCase = fetchStockDetailUseCase
    }

    // MARK: - Action

    func action(_ intent: StockDetailIntent) {
        switch intent {
        case .loadDetail:
            loadDetail()
        case .dismiss:
            break
        }
    }
}

// MARK: - Private

extension StockDetailStore {

    private func loadDetail() {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let detail = try await fetchStockDetailUseCase.execute(ticker: state.ticker)
                print("<< [StockDetailStore] companyName: \(detail.companyName)")
                print("<< [StockDetailStore] currentPrice: \(detail.currentPrice)")
                print("<< [StockDetailStore] priceChangePercent: \(detail.priceChangePercent)")
                print("<< [StockDetailStore] logoURL: '\(detail.logoURL)'")
                state.companyName = detail.companyName
                state.currentPrice = detail.currentPrice
                state.priceChangePercent = detail.priceChangePercent
                state.logoURL = detail.logoURL
            } catch {
                print("<< [StockDetailStore] error: \(error)")
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
    }
}
