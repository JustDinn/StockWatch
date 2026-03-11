//
//  NotificationHistoryMapper.swift
//  StockWatch
//

import Foundation

enum NotificationHistoryMapper {

    static func toEntity(_ model: NotificationHistoryModel) -> NotificationItem {
        NotificationItem(
            id: model.id,
            ticker: model.ticker,
            logoURL: model.logoURL,
            strategyName: model.strategyName,
            body: model.body,
            receivedAt: model.receivedAt
        )
    }

    static func toModel(_ entity: NotificationItem) -> NotificationHistoryModel {
        NotificationHistoryModel(
            id: entity.id,
            ticker: entity.ticker,
            logoURL: entity.logoURL,
            strategyName: entity.strategyName,
            body: entity.body,
            receivedAt: entity.receivedAt
        )
    }
}
