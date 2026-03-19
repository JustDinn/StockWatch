//
//  WatchListIntent.swift
//  StockWatch
//

/// WatchList 화면 사용자 액션 정의
enum WatchListIntent {
    /// 관심 종목 목록 로드
    case loadFavorites
    /// 특정 종목을 관심 목록에서 제거
    case removeFavorite(ticker: String)
}
