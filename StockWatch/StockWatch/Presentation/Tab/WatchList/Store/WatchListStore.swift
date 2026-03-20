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
    private let manageGroupUseCase: ManageWatchListGroupUseCaseProtocol
    private let fetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCaseProtocol

    // MARK: - Init

    init(
        fetchFavoritesUseCase: FetchFavoritesUseCaseProtocol,
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        manageGroupUseCase: ManageWatchListGroupUseCaseProtocol,
        fetchFavoritesByGroupUseCase: FetchFavoritesByGroupUseCaseProtocol,
        state: WatchListState = WatchListState()
    ) {
        self.state = state
        self.fetchFavoritesUseCase = fetchFavoritesUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.manageGroupUseCase = manageGroupUseCase
        self.fetchFavoritesByGroupUseCase = fetchFavoritesByGroupUseCase
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
        case .selectGroup(let index):
            guard index >= 0 && index < state.groups.count else { return }
            state.selectedGroupIndex = index
            loadFavorites()
        case .loadGroups:
            loadGroups()
        case .createGroup(let name):
            createGroup(name: name)
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
            if state.selectedGroupIndex == 0 {
                state.favorites = await fetchFavoritesUseCase.execute()
            } else {
                let groupIndex = state.selectedGroupIndex - 1
                guard groupIndex < state.dbGroups.count else {
                    state.favorites = []
                    state.isLoading = false
                    return
                }
                let groupId = state.dbGroups[groupIndex].id
                state.favorites = await fetchFavoritesByGroupUseCase.execute(groupId: groupId)
            }
            state.mockPriceData = Dictionary(uniqueKeysWithValues:
                state.favorites.map { ($0.ticker, WatchListState.mockData(for: $0.ticker)) }
            )
            state.isLoading = false
        }
    }

    func loadGroups() {
        Task {
            state.dbGroups = await manageGroupUseCase.fetchGroups()
        }
    }

    func createGroup(name: String) {
        Task {
            _ = try? await manageGroupUseCase.createGroup(name: name)
            state.dbGroups = await manageGroupUseCase.fetchGroups()
        }
    }

    /// 낙관적 UI 업데이트 후 SwiftData에서 제거한다.
    /// 실패 시 이전 목록으로 rollback한다.
    func removeFavorite(ticker: String) {
        let previous = state.favorites
        state.favorites.removeAll { $0.ticker == ticker }

        Task {
            do {
                _ = try await toggleFavoriteUseCase.execute(ticker: ticker, companyName: "")
            } catch {
                state.favorites = previous
            }
        }
    }
}
