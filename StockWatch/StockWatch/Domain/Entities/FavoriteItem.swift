//
//  FavoriteItem.swift
//  StockWatch
//

import Foundation

/// 관심 종목을 나타내는 Domain Entity
/// ticker, companyName(영문), 추가 시각, 로고 URL, 그룹 소속을 보유한다.
struct FavoriteItem: Equatable {
    let ticker: String
    let companyName: String
    let addedAt: Date
    let logoURL: String
    let groupIds: [UUID]
}
