//
//  AddStockToGroupStore.swift
//  StockWatch
//

import Foundation

/// AddStockToGroup 화면 Store
@MainActor
final class AddStockToGroupStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: AddStockToGroupState
    private let tickerUseCase: TickerUseCaseProtocol
    private let onConfirm: ([SearchResult]) -> Void
    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    init(
        tickerUseCase: TickerUseCaseProtocol,
        onConfirm: @escaping ([SearchResult]) -> Void,
        state: AddStockToGroupState = AddStockToGroupState()
    ) {
        self.tickerUseCase = tickerUseCase
        self.onConfirm = onConfirm
        self.state = state
    }

    // MARK: - Action

    func action(_ intent: AddStockToGroupIntent) {
        switch intent {
        case .search(let query):
            search(query: query)
        case .toggleSelection(let result):
            if state.selectedStocks.contains(result) {
                state.selectedStocks.remove(result)
            } else {
                state.selectedStocks.insert(result)
            }
        case .confirmSelection:
            onConfirm(Array(state.selectedStocks))
        }
    }
}

// MARK: - Private

private extension AddStockToGroupStore {

    func search(query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else {
            state.searchResults = []
            state.isLoading = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            state.isLoading = true
            state.errorMessage = nil
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
