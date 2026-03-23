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
        print("<< [AddStockToGroupStore] init")
        self.tickerUseCase = tickerUseCase
        self.fetchLogoUseCase = fetchLogoUseCase
        self.onConfirm = onConfirm
        self.state = state
    }

    // MARK: - Action

    func action(_ intent: AddStockToGroupIntent) {
        print("<< [AddStockToGroupStore] action called - intent: \(intent)")
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
        print("<< [AddStockToGroupStore] search called - query: '\(query)'")
        if searchTask != nil {
            print("<< [AddStockToGroupStore] cancelling existing searchTask")
        }
        searchTask?.cancel()
        guard !query.isEmpty else {
            print("<< [AddStockToGroupStore] query is empty, clearing results")
            state.searchResults = []
            state.isLoading = false
            return
        }
        print("<< [AddStockToGroupStore] starting new searchTask for query: '\(query)'")
        searchTask = Task {
            print("<< [AddStockToGroupStore] Task started - sleeping 300ms")
            try? await Task.sleep(for: .milliseconds(300))
            print("<< [AddStockToGroupStore] Task awoke - isCancelled: \(Task.isCancelled)")
            guard !Task.isCancelled else {
                print("<< [AddStockToGroupStore] Task was cancelled, returning early")
                return
            }
            state.isLoading = true
            state.errorMessage = nil
            print("<< [AddStockToGroupStore] calling tickerUseCase.search for query: '\(query)'")
            do {
                let results = try await tickerUseCase.search(query: query)
                print("<< [AddStockToGroupStore] search succeeded - results count: \(results.count)")
                state.searchResults = results
                fetchLogos(for: results)
            } catch NetworkError.requestCancelled {
                // 사용자가 입력을 변경해 Task가 취소된 정상 흐름 — 무시
                print("<< [AddStockToGroupStore] search cancelled (normal flow) - ignoring")
            } catch {
                print("<< [AddStockToGroupStore] search failed - error type: \(type(of: error)), description: \(error.localizedDescription), error: \(error)")
                state.errorMessage = error.localizedDescription
                print("<< [AddStockToGroupStore] state.errorMessage set to: '\(error.localizedDescription)'")
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
