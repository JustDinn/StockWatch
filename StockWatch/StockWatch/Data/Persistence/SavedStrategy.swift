//
//  SavedStrategy.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 저장된 전략 영구 저장 모델
/// strategyId는 고유 키로 중복 저장을 방지한다.
@Model
final class SavedStrategy {
    @Attribute(.unique) var strategyId: String
    var savedAt: Date

    init(strategyId: String, savedAt: Date = .now) {
        self.strategyId = strategyId
        self.savedAt = savedAt
    }
}
