//
//  AddStockToGroupState.swift
//  StockWatch
//

/// AddStockToGroup 화면 UI 상태
struct AddStockToGroupState {
    var searchResults: [SearchResult] = []
    var selectedStocks: Set<SearchResult> = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var logoURLs: [String: String] = [:]  // ticker → 로고 URL
}
