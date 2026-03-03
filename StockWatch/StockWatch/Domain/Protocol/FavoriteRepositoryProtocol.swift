//
//  FavoriteRepositoryProtocol.swift
//  StockWatch
//

/// 관심 종목 저장소 인터페이스
/// 구현체는 Data 레이어에 위치하며, Domain은 이 Protocol에만 의존한다.
protocol FavoriteRepositoryProtocol {
    /// 특정 ticker가 관심 종목으로 저장되어 있는지 확인한다.
    func isFavorite(ticker: String) async -> Bool
    /// 관심 종목을 추가한다.
    func addFavorite(ticker: String) async throws
    /// 관심 종목을 삭제한다.
    func removeFavorite(ticker: String) async throws
}
