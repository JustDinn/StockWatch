//
//  FetchFavoritesUseCaseProtocol.swift
//  StockWatch
//

/// 관심 종목 목록 조회 UseCase 인터페이스
protocol FetchFavoritesUseCaseProtocol {
    /// 저장된 모든 관심 종목 ticker를 addedAt 내림차순으로 반환한다.
    func execute() async -> [String]
}
