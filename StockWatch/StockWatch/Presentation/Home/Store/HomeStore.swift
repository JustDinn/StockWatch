//
//  HomeStore.swift
//  StockWatch
//

import Foundation

/// Home 화면 Store
/// Intent를 처리하고 UseCase를 호출하여 State를 업데이트한다.
@MainActor
final class HomeStore: ObservableObject {

    // MARK: - Properties
    
    @Published private(set) var state: HomeState
    private let tickerUseCase: TickerUseCaseProtocol

    // MARK: - Init
    
    init(
        tickerUseCase: TickerUseCaseProtocol = TickerUseCase(
            repository: TickerRepository()
        ),
        state: HomeState = HomeState()
    ) {
        self.tickerUseCase = tickerUseCase
        self.state = state
    }

    // MARK: - Action
    
    func action(_ intent: HomeIntent) {
        switch intent {
        case .search(let keyword):
            searchTicker(query: keyword)
        }
    }
}

extension HomeStore {
    
    /// 티커 검색
    private func searchTicker(query: String) {
        guard !query.isEmpty else {
            state.searchResults = []
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let results = try await tickerUseCase.search(query: query)
                state.searchResults = results
                print("<< 검색 결과: \(results)")
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
    }
}
