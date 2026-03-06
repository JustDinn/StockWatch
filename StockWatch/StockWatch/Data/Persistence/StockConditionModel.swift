//
//  StockConditionModel.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 종목 전략 조건 영구 저장 모델
@Model
final class StockConditionModel {
    @Attribute(.unique) var conditionId: String
    var ticker: String
    var strategyId: String
    /// StrategyParameters를 JSON으로 직렬화하여 저장
    var parametersJSON: String
    var isNotificationEnabled: Bool
    var isActive: Bool
    var createdAt: Date

    init(
        conditionId: String,
        ticker: String,
        strategyId: String,
        parametersJSON: String,
        isNotificationEnabled: Bool,
        isActive: Bool,
        createdAt: Date
    ) {
        self.conditionId = conditionId
        self.ticker = ticker
        self.strategyId = strategyId
        self.parametersJSON = parametersJSON
        self.isNotificationEnabled = isNotificationEnabled
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
