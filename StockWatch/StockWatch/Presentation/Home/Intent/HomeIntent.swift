//
//  HomeIntent.swift
//  StockWatch
//

/// Home 화면 사용자 액션 정의
enum HomeIntent {
    /// 종목 검색 (검색어 입력 후 엔터)
    case search(String)
    /// 검색 결과 셀 탭 → 상세 화면 이동
    case selectStock(SearchResult)
}
