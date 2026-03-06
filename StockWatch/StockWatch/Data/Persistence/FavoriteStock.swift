//
//  FavoriteStock.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 관심 종목 영구 저장 모델
/// ticker는 고유 키로 중복 저장을 방지한다.
@Model
final class FavoriteStock {
    @Attribute(.unique) var ticker: String
    var addedAt: Date

    init(ticker: String, addedAt: Date = .now) {
        self.ticker = ticker
        self.addedAt = addedAt
    }
}
