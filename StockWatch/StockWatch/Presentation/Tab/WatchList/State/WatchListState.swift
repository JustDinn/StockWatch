//
//  WatchListState.swift
//  StockWatch
//

/// WatchList 화면 UI 상태
struct WatchListState {
    var tickers: [String] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var selectedTicker: String? = nil  /// 선택된 종목 (nil이면 상세 화면 미표시)
}
