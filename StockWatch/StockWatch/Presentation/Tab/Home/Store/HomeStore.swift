//
//  HomeStore.swift
//  StockWatch
//

import SwiftUI

/// Home 화면 Store
/// Intent를 처리하고 UseCase를 호출하여 State를 업데이트한다.
@MainActor
final class HomeStore: ObservableObject {

    // MARK: - Properties
    
    @Published private(set) var state: HomeState
    private let tickerUseCase: TickerUseCaseProtocol
    private let checkUnreadUseCase: CheckUnreadNotificationUseCaseProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private var networkMonitorTask: Task<Void, Never>?

    // MARK: - Init

    init(
        tickerUseCase: TickerUseCaseProtocol = TickerUseCase(
            repository: TickerRepository()
        ),
        checkUnreadUseCase: CheckUnreadNotificationUseCaseProtocol,
        networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared,
        state: HomeState = HomeState()
    ) {
        self.tickerUseCase = tickerUseCase
        self.checkUnreadUseCase = checkUnreadUseCase
        self.networkMonitor = networkMonitor
        self.state = state
        listenNetworkRecovery()
    }

    deinit {
        networkMonitorTask?.cancel()
    }

    // MARK: - Action
    
    func action(_ intent: HomeIntent) {
        switch intent {
        case .onAppear:
            loadUnreadStatus()
        case .search(let keyword):
            searchTicker(query: keyword)
        case .selectStock(let result):
            navigateToDetail(result: result)
        case .showNotificationHistory:
            state.isShowingNotificationHistory = true
        case .navigateToStock(let ticker):
            state.deepLinkTicker = ticker
        }
    }

    // MARK: - Navigation Binding

    var selectedStockBinding: Binding<SearchResult?> {
        Binding(
            get: { self.state.selectedStock },
            set: { self.state.selectedStock = $0 }
        )
    }

    var isShowingNotificationHistoryBinding: Binding<Bool> {
        Binding(
            get: { self.state.isShowingNotificationHistory },
            set: {
                self.state.isShowingNotificationHistory = $0
                if !$0 { self.loadUnreadStatus() }
            }
        )
    }

    var isShowingDeepLinkBinding: Binding<Bool> {
        Binding(
            get: { self.state.deepLinkTicker != nil },
            set: { if !$0 { self.state.deepLinkTicker = nil } }
        )
    }

}

extension HomeStore {

    private func listenNetworkRecovery() {
        networkMonitorTask = Task {
            for await _ in networkMonitor.makeConnectionRestoredStream() {
                // 검색 에러 상태이고 검색어가 있는 경우에만 재시도
                if state.errorMessage != nil, !state.searchQuery.isEmpty {
                    searchTicker(query: state.searchQuery)
                }
            }
        }
    }

    /// 미읽음 알림 상태 갱신
    private func loadUnreadStatus() {
        do {
            state.hasUnreadNotification = try checkUnreadUseCase.execute()
        } catch {
            state.hasUnreadNotification = false
        }
    }

    /// 종목 선택 → 상세 화면 이동
    private func navigateToDetail(result: SearchResult) {
        state.selectedStock = result
    }

    /// 티커 검색
    private func searchTicker(query: String) {
        state.searchQuery = query
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
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
    }
}
