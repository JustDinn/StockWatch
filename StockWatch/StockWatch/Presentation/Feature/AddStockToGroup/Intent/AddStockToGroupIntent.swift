//
//  AddStockToGroupIntent.swift
//  StockWatch
//

/// AddStockToGroup 화면 사용자 액션 정의
enum AddStockToGroupIntent {
    /// 종목 검색
    case search(String)
    /// 검색 결과에서 종목 선택/해제 토글
    case toggleSelection(SearchResult)
    /// 선택 완료 - 선택된 종목을 콜백으로 전달하고 뷰를 닫는다
    case confirmSelection
}
