//
//  AddFavoriteToGroupUseCaseProtocol.swift
//  StockWatch
//

import Foundation

/// 특정 그룹에 관심 종목을 추가하는 UseCase 인터페이스
protocol AddFavoriteToGroupUseCaseProtocol {
    /// 종목을 지정된 그룹에 추가한다.
    /// - 이미 즐겨찾기된 종목이면 그룹 소속만 추가한다.
    /// - 새 종목이면 즐겨찾기로 추가하고 그룹과 연결한다.
    func execute(ticker: String, companyName: String, groupId: UUID) async throws
}
