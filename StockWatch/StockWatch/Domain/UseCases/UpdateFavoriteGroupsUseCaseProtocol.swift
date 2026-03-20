//
//  UpdateFavoriteGroupsUseCaseProtocol.swift
//  StockWatch
//

import Foundation

protocol UpdateFavoriteGroupsUseCaseProtocol {
    /// ticker 종목의 그룹 소속을 업데이트한다.
    /// - groupIds가 비어있으면 워치리스트에서 제거한다.
    /// - 이미 저장된 경우 groups 업데이트, 아닌 경우 새로 추가한다.
    func execute(ticker: String, companyName: String, logoURL: String, groupIds: [UUID]) async throws
}
