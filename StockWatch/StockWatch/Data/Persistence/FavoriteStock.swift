//
//  FavoriteStock.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 관심 종목 영구 저장 모델
/// ticker는 고유 키로 중복 저장을 방지한다.
/// companyName은 즐겨찾기 추가 시점에 함께 저장된다 (오프라인 표시 지원).
@Model
final class FavoriteStock {
    @Attribute(.unique) var ticker: String
    var companyName: String
    var addedAt: Date

    init(ticker: String, companyName: String = "", addedAt: Date = .now) {
        self.ticker = ticker
        self.companyName = companyName
        self.addedAt = addedAt
    }
}
