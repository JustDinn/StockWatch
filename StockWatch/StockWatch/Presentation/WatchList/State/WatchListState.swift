//
//  WatchListState.swift
//  StockWatch
//

/// WatchList 화면 UI 상태
struct WatchListState {
    var tickers: [String] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
}
