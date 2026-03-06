//
//  ToggleFavoriteUseCaseProtocol.swift
//  StockWatch
//

/// 관심 종목 토글 UseCase 인터페이스
protocol ToggleFavoriteUseCaseProtocol {
    /// 현재 저장 상태에 따라 관심 종목을 추가하거나 삭제한다.
    /// - Returns: 토글 후 새로운 isFavorite 상태 (true = 추가됨, false = 삭제됨)
    func execute(ticker: String) async throws -> Bool
}
