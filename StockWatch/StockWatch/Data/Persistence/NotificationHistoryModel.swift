//
//  NotificationHistoryModel.swift
//  StockWatch
//

import Foundation
import SwiftData

/// 수신한 FCM 푸시 알림 내역을 로컬에 저장하는 SwiftData 모델
@Model
final class NotificationHistoryModel {

    @Attribute(.unique) var id: String
    var ticker: String
    var logoURL: String
    var strategyName: String
    var body: String
    var receivedAt: Date

    init(
        id: String,
        ticker: String,
        logoURL: String,
        strategyName: String,
        body: String,
        receivedAt: Date
    ) {
        self.id = id
        self.ticker = ticker
        self.logoURL = logoURL
        self.strategyName = strategyName
        self.body = body
        self.receivedAt = receivedAt
    }
}
