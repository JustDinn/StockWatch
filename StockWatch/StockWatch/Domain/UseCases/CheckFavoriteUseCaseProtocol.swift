//
//  CheckFavoriteUseCaseProtocol.swift
//  StockWatch
//

/// 관심 종목 여부 확인 UseCase 인터페이스
protocol CheckFavoriteUseCaseProtocol {
    /// 특정 ticker가 관심 종목으로 저장되어 있는지 반환한다.
    func execute(ticker: String) async -> Bool
}
