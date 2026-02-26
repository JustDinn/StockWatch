//
//  HomeState.swift
//  StockWatch
//

/// Home 화면 UI 상태
struct HomeState: Equatable {
    /// 검색 결과 목록
    var searchResults: [SearchResult] = []
    /// 로딩 상태
    var isLoading: Bool = false
    /// 에러 메시지 (nil이면 에러 없음)
    var errorMessage: String? = nil
}
