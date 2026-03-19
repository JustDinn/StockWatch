//
//  WatchListStore.swift
//  StockWatch
//

import Foundation
import SwiftUI

/// WatchList 화면 Store
@MainActor
final class WatchListStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: WatchListState
    private let fetchFavoritesUseCase: FetchFavoritesUseCaseProtocol
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol

    // MARK: - Init

    init(
        fetchFavoritesUseCase: FetchFavoritesUseCaseProtocol,
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        state: WatchListState = WatchListState()
    ) {
        self.state = state
        self.fetchFavoritesUseCase = fetchFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
    }

    // MARK: - Action

    func action(_ intent: WatchListIntent) {
        switch intent {
        case .loadFavorites:
            loadFavorites()
        case .removeFavorite(let ticker):
            removeFavorite(ticker: ticker)
        case .selectTicker(let ticker):
            state.selectedTicker = ticker
        }
    }

    // MARK: - Navigation Binding

    var selectedTickerBinding: Binding<String?> {
        Binding(
            get: {
                return self.state.selectedTicker
            },
            set: {
                self.state.selectedTicker = $0
            }
        )
    }
}

// MARK: - Private

private extension WatchListStore {

    func loadFavorites() {
        state.isLoading = true
        Task {
            state.tickers = await fetchFavoritesUseCase.execute()
            state.isLoading = false
        }
    }

    /// 낙관적 UI 업데이트 후 SwiftData에서 제거한다.
    /// 실패 시 이전 목록으로 rollback한다.
    func removeFavorite(ticker: String) {
        let previous = state.tickers
        state.tickers.removeAll { $0 == ticker }

        Task {
            do {
                _ = try await toggleFavoriteUseCase.execute(ticker: ticker)
            } catch {
                state.tickers = previous
            }
        }
    }
}
