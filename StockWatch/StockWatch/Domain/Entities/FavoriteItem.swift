//
//  FavoriteItem.swift
//  StockWatch
//

import Foundation

/// 관심 종목을 나타내는 Domain Entity
/// ticker, companyName(영문), 추가 시각을 보유한다.
struct FavoriteItem: Equatable {
    let ticker: String
    let companyName: String
    let addedAt: Date
}
