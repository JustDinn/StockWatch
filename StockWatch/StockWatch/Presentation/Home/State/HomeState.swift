//
//  HomeState.swift
//  StockWatch
//

/// Home 화면 UI 상태
struct HomeState: Equatable {
    var searchResults: [SearchResult] = []  /// 검색 결과 목록
    var isLoading: Bool = false             /// 로딩 상태
    var errorMessage: String? = nil         /// 에러 메시지 (nil이면 에러 없음)
    var selectedStock: SearchResult? = nil  /// 선택된 종목 (nil이면 상세 화면 미표시)
}
