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
    private let fetchLogoUseCase: FetchStockLogoUseCaseProtocol
    private let onConfirm: ([SearchResult], [String: String]) -> Void
    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    init(
        tickerUseCase: TickerUseCaseProtocol,
        fetchLogoUseCase: FetchStockLogoUseCaseProtocol,
        onConfirm: @escaping ([SearchResult], [String: String]) -> Void,
        state: AddStockToGroupState = AddStockToGroupState()
    ) {
        self.tickerUseCase = tickerUseCase
        self.fetchLogoUseCase = fetchLogoUseCase
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
            onConfirm(Array(state.selectedStocks), state.logoURLs)
        case .logoURLFetched(let ticker, let url):
            state.logoURLs[ticker] = url
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
                fetchLogos(for: results)
            } catch NetworkError.requestCancelled {
                // 사용자가 입력을 변경해 Task가 취소된 정상 흐름 — 무시
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
    }

    func fetchLogos(for results: [SearchResult]) {
        for result in results {
            Task {
                guard let url = try? await fetchLogoUseCase.execute(ticker: result.ticker),
                      !url.isEmpty else { return }
                action(.logoURLFetched(ticker: result.ticker, url: url))
            }
        }
    }
}
